/// Pure routing decision. Returns the path to redirect to, or null to stay.
///
/// [profileResolved] is false while the signed-in user's profile is still
/// loading — in that window we must NOT send them to onboarding (that caused a
/// brief name-form flash for already-registered users on login); we wait until
/// the profile is known.
String? authRedirect({
  required String? uid,
  required bool hasProfile,
  required String location,
  bool profileResolved = true,
}) {
  const auth = {'/login', '/onboarding'};
  if (uid == null) return location == '/login' ? null : '/login';
  if (!profileResolved) return null; // signed in, profile loading → stay put
  if (!hasProfile) return location == '/onboarding' ? null : '/onboarding';
  return auth.contains(location) ? '/home' : null;
}
