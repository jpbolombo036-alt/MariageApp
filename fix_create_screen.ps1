$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\organisateur\presentation\screens\evenement_create_screen.dart'
$lines = Get-Content $p
$newLines = @()
$skip = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($skip -gt 0) {
        $skip--
        continue
    }
    if ($line -match "_buildTypeSelector\(\);") { continue }
    if ($line -match "_nameALabel\(\);") { $newLines += "                        label: 'Prénom principal',"; continue }
    if ($line -match "_nameALastLabel\(\);") { $newLines += "                        label: 'Nom de famille',"; continue }
    if ($line -match "_nameBLabel\(\);") { $newLines += "                        label: 'Prénom secondaire',"; continue }
    if ($line -match "EventType\? _type;") { continue }
    if ($line -match "if \(_type == null\)") { $skip = 3; continue }
    if ($line -match "eventType: _type!,") { continue }
    if ($line -match "_type == EventType\.wedding") { continue }
    if ($line -match "_typeChip\(") { $skip = 7; continue }
    if ($line -match "Widget _typeChip\(") { $skip = 18; continue }
    if ($line -match "String _nameALabel\(\) =>") { $skip = 2; continue }
    if ($line -match "String _nameBLabel\(\) =>") { $skip = 2; continue }
    $newLines += $line
}
$newLines -join "`n" | Set-Content $p
Write-Host 'done'
