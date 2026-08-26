$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\gestionnaire_invites\screens\gi_guests_view.dart'
$content = Get-Content $p -Raw
$content = $content -replace 'String _query = ''\);', "String _query = '';
  String _filter = 'Tous';"
$content = $content -replace '  bool _match\(String\? status\) \{[\s\S]*?^\t\}\);\r?\n', @'
  bool _match(String? status) {
    final q = _query.trim().toLowerCase();
    final guestMatch = q.isEmpty || _guests.any((g) => '${g.firstName} ${g.lastName}'.toLowerCase().contains(q));
    if (!guestMatch) return false;
    if (_filter.isEmpty) return true;
    final selected = _filter.split(' ').first.toLowerCase();
    final s = (status ?? '').toUpperCase();
    return switch (selected) {
      'confirmés' => s == 'ACCEPTED',
      'refusés' => s == 'DECLINED',
      'en' => s != 'ACCEPTED' && s != 'DECLINED',
      _ => true,
    };
  }

  List<String> get _filters => [
        'Tous (${_guests.length})',
        'Confirmés (${_rsvps.values.where((r) => (r.status ?? '').toUpperCase() == 'ACCEPTED').length})',
        'En attente (${_rsvps.values.where((r) => (r.status ?? '').toUpperCase() != 'ACCEPTED' && (r.status ?? '').toUpperCase() != 'DECLINED').length})',
        'Refusés (${_rsvps.values.where((r) => (r.status ?? '').toUpperCase() == 'DECLINED').length})',
      ];

  Widget _chip(GiPalette p, String label) {
    final active = label == _filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? p.primary : p.surfaceAlt,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? p.primary : p.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : p.textSecondary)),
      ),
    );
  }
'@
$content = $content -replace '          Expanded\(child: _body\(context, p\)\),', @'
          SizedBox(
            height: 32,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _chip(p, _filters[i]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(context, p)),
'@
Set-Content $p $content
Write-Host 'done'
