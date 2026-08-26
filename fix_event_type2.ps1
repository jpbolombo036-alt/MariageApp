$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\organisateur\shared\widgets\app_event_cards.dart'
$content = Get-Content $p -Raw
$lines = $content -split "`n"
$newLines = @()
$skip = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($skip -gt 0) {
        $skip--
        continue
    }
    if ($line -match "EventType.birthday => 'Anniversaire',") {
        $skip = 13
        continue
    }
    $newLines += $line
}
$newLines -join "`n" | Set-Content $p
Write-Host 'done'
