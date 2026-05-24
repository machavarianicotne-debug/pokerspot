import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/home/presentation/player_home.dart' show RoleScaffold;

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});
  @override
  Widget build(BuildContext context) => RoleScaffold(title: AppL10n.of(context).superAdminHome);
}
