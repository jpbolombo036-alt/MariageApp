$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\gestionnaire_invites\screens\gi_guests_view.dart'
$content = Get-Content $p -Raw
$content = $content -replace "String _query = '';\r?\n  String _filter = 'Tous';\r?\n", "String _query = '';`n"
$content = $content -replace "List<String> get _filters => \[[\s\S]*?\];\r?\n\r?\n", ""
$content = $content -replace "String _persons\(Guest g\) =>[\s\S]*?\r?\n\r?\n", ""
Set-Content $p $content
Write-Host 'done'
