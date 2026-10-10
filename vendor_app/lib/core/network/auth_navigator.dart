/// Simple callback holder to avoid circular imports between
/// AuthInterceptor and AppRouter.
class AuthNavigator {
  static void Function()? onUnauthorized;
  static bool sessionExpired = false;
}