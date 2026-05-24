/// Pure routing decision. Returns the path to redirect to, or null to stay.
String? authRedirect({
  required String? uid,
  required bool hasProfile,
  required String location,
}) {
  const auth = {'/login', '/onboarding'};
  if (uid == null) return location == '/login' ? null : '/login';
  if (!hasProfile) return location == '/onboarding' ? null : '/onboarding';
  return auth.contains(location) ? '/home' : null;
}
