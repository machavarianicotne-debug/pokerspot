/// Feature flags (spec §12.B). Activating the v2 backlog = flip a flag here.
class FeatureFlags {
  final bool clubChat;
  final bool perSeatIdentity;
  final bool multiClubPitBoss;
  final bool autoReservationConvertToWaitlist;
  final bool deepAnalytics;
  final bool geoMap;
  final bool templateAutoRestore;
  final bool crossClubWaitlist;
  final bool iosSupport;

  const FeatureFlags({
    required this.clubChat,
    required this.perSeatIdentity,
    required this.multiClubPitBoss,
    required this.autoReservationConvertToWaitlist,
    required this.deepAnalytics,
    required this.geoMap,
    required this.templateAutoRestore,
    required this.crossClubWaitlist,
    required this.iosSupport,
  });

  const FeatureFlags.mvp()
      : clubChat = true,
        perSeatIdentity = true,
        multiClubPitBoss = false,
        autoReservationConvertToWaitlist = false,
        deepAnalytics = false,
        geoMap = false,
        templateAutoRestore = false,
        crossClubWaitlist = false,
        iosSupport = false;

  FeatureFlags copyWith({
    bool? clubChat,
    bool? perSeatIdentity,
    bool? multiClubPitBoss,
    bool? autoReservationConvertToWaitlist,
    bool? deepAnalytics,
    bool? geoMap,
    bool? templateAutoRestore,
    bool? crossClubWaitlist,
    bool? iosSupport,
  }) {
    return FeatureFlags(
      clubChat: clubChat ?? this.clubChat,
      perSeatIdentity: perSeatIdentity ?? this.perSeatIdentity,
      multiClubPitBoss: multiClubPitBoss ?? this.multiClubPitBoss,
      autoReservationConvertToWaitlist:
          autoReservationConvertToWaitlist ?? this.autoReservationConvertToWaitlist,
      deepAnalytics: deepAnalytics ?? this.deepAnalytics,
      geoMap: geoMap ?? this.geoMap,
      templateAutoRestore: templateAutoRestore ?? this.templateAutoRestore,
      crossClubWaitlist: crossClubWaitlist ?? this.crossClubWaitlist,
      iosSupport: iosSupport ?? this.iosSupport,
    );
  }
}
