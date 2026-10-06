<#
    tools/flutter_build.ps1 -- lance les builds Flutter de facon ROBUSTE.

    Pourquoi ce script ?
    -------------------
    `flutter` est un .bat : un Ctrl+C dans le terminal integre de VS Code peut
    laisser des fichiers de verrou Gradle corrompus, ce qui produit ensuite :
        "Unexpected lock protocol found in lock file. Expected 3, found 0"
    et un echec de `:app:mergeReleaseNativeLibs`.

    Ici le build tourne dans un PROCESSUS SEPARE, toute la sortie part dans
    build_logs\<tache>-<horodatage>.log : aucune interruption accidentelle et
    la progression reste consultable meme apres fermeture de la fenetre.

    Utilisation
    -----------
      .\tools\flutter_build.ps1 -Task apk
      .\tools\flutter_build.ps1 -Task apk -SplitPerAbi
      .\tools\flutter_build.ps1 -Task apk -DartDefine API_BASE_URL=https://api.example.com
      .\tools\flutter_build.ps1 -Task aab
      .\tools\flutter_build.ps1 -Task run -Device B37M001K00700041 -DartDefine API_ENV=prod
      .\tools\flutter_build.ps1 -Task repair     # verrous / caches corrompus
      .\tools\flutter_build.ps1 -Task clean      # flutter clean + pub get
#>
[CmdletBinding()]
param(
    [ValidateSet('apk', 'aab', 'run', 'repair', 'clean', 'get', 'doctor', 'analyze')]
    [string]$Task = 'apk',

    [string[]]$DartDefine = @(),

    [switch]$SplitPerAbi,

    # Identifiant de l'appareil pour `flutter run` (voir `flutter devices`).
    [string]$Device
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

# --- Localisation de Flutter ------------------------------------------------
$Flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $Flutter) { $Flutter = 'C:\src\flutter\bin\flutter.bat' }
if (-not (Test-Path $Flutter)) { throw "flutter introuvable (ajustez le chemin dans ce script)" }
$Flutter = (Resolve-Path $Flutter).Path

# --- Utilitaires ------------------------------------------------------------
function New-LogPath {
    param([string]$Name)
    $dir = Join-Path $ProjectRoot 'build_logs'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Join-Path $dir ("{0}-{1}.log" -f $Name, (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

# Suppression compatible chemins longs (> 260 caracteres) : Remove-Item echoue,
# `rmdir /s /q` non.
function Remove-LongPath {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    & cmd.exe /c "rmdir /s /q `"$Path`"" | Out-Null
    if (Test-Path -LiteralPath $Path) {
        try { Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop }
        catch { Write-Warning "  suppression partielle : $Path"; return }
    }
    Write-Host "  purge : $Path"
}

function Get-EffectiveApiUrl {
    param([bool]$Release)
    $base = $DartDefine | Where-Object { $_ -like 'API_BASE_URL=*' } | Select-Object -First 1
    if ($base) { return $base.Substring('API_BASE_URL='.Length) }
    $envName = $DartDefine | Where-Object { $_ -like 'API_ENV=*' } | Select-Object -First 1
    if ($envName) {
        $v = $envName.Substring('API_ENV='.Length).ToLower()
        if ($v -eq 'prod' -or $v -eq 'production') { return 'production (Railway)' }
        return 'local (10.0.2.2:8000 ou localhost:8000)'
    }
    if ($Release) { return 'production (Railway)' }
    return 'local (10.0.2.2:8000 ou localhost:8000)'
}

function Invoke-Flutter {
    param([string[]]$Arguments, [string]$Label)
    $log = New-LogPath $Label
    Write-Host ''
    Write-Host "==> flutter $($Arguments -join ' ')"
    Write-Host "    log : $log"
    Write-Host '    (build dans un processus separe : laissez cette fenetre ouverte)'
    $p = Start-Process -FilePath $Flutter -ArgumentList $Arguments -WorkingDirectory $ProjectRoot `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err.log" -PassThru
    while (-not $p.HasExited) {
        Start-Sleep -Seconds 3
        $tail = Get-Content $log -Tail 1 -ErrorAction SilentlyContinue
        if ($tail) { Write-Host ("    " + $tail.Trim()) }
    }
    $code = $p.ExitCode
    Write-Host ''
    Write-Host '--- 30 dernieres lignes -------------------------------'
    Get-Content $log -Tail 30 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
    $errLog = "$log.err.log"
    if (Test-Path $errLog) {
        $err = Get-Content $errLog -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^WARNING:' }
        if ($err) { Write-Host '--- stderr ---'; $err | Select-Object -Last 20 | ForEach-Object { Write-Host $_ } }
    }
    return $code
}

function Invoke-Repair {
    Write-Host '==> 1/5 Arret des daemons Gradle / Kotlin (les autres applis Java sont epargnees)...'
    $gradlew = Join-Path $ProjectRoot 'android\gradlew.bat'
    if (Test-Path $gradlew) { & $gradlew --stop 2>&1 | Out-Host }
    Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'GradleDaemon|org\.gradle\.launcher|KotlinCompileDaemon' } |
        ForEach-Object {
            try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; Write-Host "    daemon arrete : PID $($_.ProcessId)" } catch { }
        }
    Start-Sleep -Seconds 2

    $gradleHome = Join-Path $env:USERPROFILE '.gradle'

    Write-Host '==> 2/5 Fichiers de verrou invalides (0 octet) sous ~/.gradle...'
    if (Test-Path $gradleHome) {
        Get-ChildItem $gradleHome -Recurse -Force -Filter '*.lock' -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -eq 0 } |
            ForEach-Object {
                try { Remove-Item $_.FullName -Force -ErrorAction Stop; Write-Host "    supprime : $($_.FullName)" } catch { }
            }
    }

    Write-Host '==> 3/5 Caches Gradle corrompus (version du wrapper, journal, jars, transformations)...'
    $wrapper = Join-Path $ProjectRoot 'android\gradle\wrapper\gradle-wrapper.properties'
    $version = $null
    if (Test-Path $wrapper) {
        $m = Select-String -Path $wrapper -Pattern 'gradle-([0-9][0-9.]*)-' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($m) { $version = $m.Matches[0].Groups[1].Value }
    }
    $targets = @()
    if ($version) { $targets += (Join-Path $gradleHome "caches\$version") }
    $targets += (Join-Path $gradleHome 'caches\journal-1')
    $targets += (Join-Path $gradleHome 'caches\jars-9')
    $targets += (Join-Path $ProjectRoot 'android\.gradle')
    foreach ($t in $targets) { Remove-LongPath $t }

    # Les fichiers de configuration CMake (`.cxx`) sont eux aussi mis en cache :
    # quand ils sont tronques, le build echoue sur
    #   [CXX1420] ... configure_fingerprint.bin: unrecognized RECORD_NOT_SET
    Write-Host '==> 4/5 Caches CMake .cxx (projet + pub cache)...'
    $cxxDirs = @(Join-Path $ProjectRoot 'build\.cxx')
    $pubCache = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev'
    if (Test-Path $pubCache) {
        $cxxDirs += Get-ChildItem $pubCache -Recurse -Directory -Force -Filter '.cxx' `
            -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }
    foreach ($d in $cxxDirs) { Remove-LongPath $d }

    Write-Host '==> 5/5 Termine.'
    Write-Host '    Les dependances telechargees (~/.gradle/caches/modules-2) sont conservees :'
    Write-Host '    pas de re-telechargement, seulement les transformations a refaire.'
    Write-Host '    Relancez :  .\tools\flutter_build.ps1 -Task apk'
    Write-Host ''
    Write-Host '    Si l erreur persiste : .\tools\flutter_build.ps1 -Task clean'
}

# --- Execution --------------------------------------------------------------
switch ($Task) {
    'repair' { Invoke-Repair; exit 0 }

    'clean' {
        [void](Invoke-Flutter -Arguments @('clean') -Label 'clean')
        exit (Invoke-Flutter -Arguments @('pub', 'get') -Label 'pubget')
    }

    'get' { exit (Invoke-Flutter -Arguments @('pub', 'get') -Label 'pubget') }
    'doctor' { exit (Invoke-Flutter -Arguments @('doctor', '-v') -Label 'doctor') }
    'analyze' { exit (Invoke-Flutter -Arguments @('analyze') -Label 'analyze') }

    'run' {
        $runArgs = @('run')
        if ($Device) { $runArgs += @('-d', $Device) }
        $runArgs += ($DartDefine | ForEach-Object { "--dart-define=$_" })
        Write-Host "Appareil    : $(if ($Device) { $Device } else { 'auto' })"
        Write-Host "API ciblee  : $(Get-EffectiveApiUrl -Release:$false)"
        exit (Invoke-Flutter -Arguments $runArgs -Label 'run')
    }

    'apk' {
        $buildArgs = @('build', 'apk', '--release') + ($DartDefine | ForEach-Object { "--dart-define=$_" })
        if ($SplitPerAbi) { $buildArgs += '--split-per-abi' }
        Write-Host "API ciblee : $(Get-EffectiveApiUrl -Release:$true)"
        $code = Invoke-Flutter -Arguments $buildArgs -Label 'apk'
        if ($code -eq 0) {
            Write-Host ''
            Write-Host 'APK genere :'
            Get-ChildItem (Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\*.apk') -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Host ("  {0}  ({1:N1} Mo)" -f $_.FullName, ($_.Length / 1MB)) }
        }
        exit $code
    }

    'aab' {
        $buildArgs = @('build', 'appbundle', '--release') + ($DartDefine | ForEach-Object { "--dart-define=$_" })
        Write-Host "API ciblee : $(Get-EffectiveApiUrl -Release:$true)"
        exit (Invoke-Flutter -Arguments $buildArgs -Label 'aab')
    }
}
