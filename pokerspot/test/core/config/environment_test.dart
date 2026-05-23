import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/config/environment.dart';

void main() {
  test('defaults to dev when no dart-define given', () {
    expect(Environment.current.name, AppEnv.dev);
    expect(Environment.current.firebaseProjectId, 'pokerspot-dev');
  });

  test('prod keeps the MVP flags', () {
    final prod = Environment.forName('prod');
    expect(prod.name, AppEnv.prod);
    expect(prod.flags.clubChat, isTrue);
  });
}
