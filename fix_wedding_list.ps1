$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\src\wedding\wedding_list_page.dart'
$lines = Get-Content $p
$newLines = @()
$skip = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($skip -gt 0) { $skip--; continue }
    if ($line -match "'ACTIVE' \|\| 'PUBLISHED' => 'En cours',") { continue }
    if ($line -match "'DRAFT' => 'Brouillon',") { continue }
    if ($line -match "_ => 'À venir',") { continue }
    if ($line -match "^\s*}$") {
        if ($newLines.Count -gt 0 -and $newLines[$newLines.Count-1] -match "^\s*}$") {
            continue
        }
    }
    $newLines += $line
}
$newLines -join "`n" | Set-Content $p
Write-Host 'done'
