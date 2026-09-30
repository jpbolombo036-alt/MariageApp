import 'package:flutter_test/flutter_test.dart';
import 'package:mariageplus_app/src/auth/auth_models.dart';
import 'package:mariageplus_app/src/auth/permission_roles.dart';
import 'package:mariageplus_app/src/navigation/rsvp_link.dart';

void main() {
  test('les permissions API priment sur la matrice locale', () {
    final codes = permissionsFromPayload(
      {
        'permissions': ['EVENT_VIEW'],
      },
      const ['ORGANISATEUR'],
    );
    expect(codes, ['EVENT_VIEW']);
  });

  test('sans codes API, le rôle ORGANISATEUR garde la matrice locale', () {
    final codes = permissionsFromPayload(const {}, const ['ORGANISATEUR']);
    expect(codes, contains(PermissionCodes.weddingView));
    expect(codes, contains(PermissionCodes.organizationManageMembers));
  });

  test('un lien mariageplus://rsvp expose le jeton', () {
    expect(
      parseRsvpToken('mariageplus://rsvp?token=abc123'),
      'abc123',
    );
    expect(parseRsvpToken('mariageplus://rsvp/abc123'), 'abc123');
    expect(parseRsvpToken('/'), isNull);
  });
}