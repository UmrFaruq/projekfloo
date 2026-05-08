class SessionService {
  static String? userId;
  static String? username;
  static String? role;

  static void setUser({
    required String id,
    required String userName,
    required String userRole,
  }) {
    userId = id;
    username = userName;
    role = userRole;
  }

  static void clear() {
    userId = null;
    username = null;
    role = null;
  }
}
