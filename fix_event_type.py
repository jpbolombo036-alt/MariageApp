import re
path = r'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\organisateur\shared\widgets\app_event_cards.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = re.sub(r"import '../../../../src/wedding/wedding_api.dart';\n", '', text)
text = re.sub(r"String eventTypeLabel\(EventType\? t\) => switch \(t\) \{[^}]+\};\n", '', text)
text = re.sub(r"String eventTypeEmoji\(EventType\? t\) => switch \(t\) \{[^}]+\};\n", '', text)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('done')
