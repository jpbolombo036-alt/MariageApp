$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\organisateur\shared\widgets\app_event_cards.dart'
$lines = Get-Content $p
$newLines = @()
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($line -match "^\s*this\.type,") { continue }
    if ($line -match "final EventType\? type;") { continue }
    if ($line -match "eventTypeEmoji\(type\)") {
        $newLines += '                child: Text(''✨'', style: const TextStyle(fontSize: 40)),'
        continue
    }
    $newLines += $line
}
$newLines -join "`n" | Set-Content $p
Write-Host 'done'
