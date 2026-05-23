import 'package:pokerspot/core/feature_flags.dart';

enum AppEnv { dev, staging, prod }

/// App environment (spec §12.G). Selected via --dart-define APP_ENV;
/// defaults to dev. Per-env feature-flag overrides live here.
class Environment {
  final AppEnv name;
  final String firebaseProjectId;
  final FeatureFlags flags;

  const Environment({
    required this.name,
    required this.firebaseProjectId,
    required this.flags,
  });

  static final Environment current =
      Environment.forName(const String.fromEnvironment('APP_ENV', defaultValue: 'dev'));

  factory Environment.forName(String raw) {
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    switch (raw) {
      case 'prod':
        return Environment(
          name: AppEnv.prod,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-prod' : projectId,
          flags: const FeatureFlags.mvp(),
        );
      case 'staging':
        return Environment(
          name: AppEnv.staging,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-staging' : projectId,
          flags: const FeatureFlags.mvp(),
        );
      case 'dev':
      default:
        return Environment(
          name: AppEnv.dev,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-dev' : projectId,
          flags: const FeatureFlags.mvp(),
        );
    }
  }
}
