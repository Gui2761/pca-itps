enum UserRole {
  admin,
  editor,
  viewer,
}

class User {
  final int? id;
  final String username;
  final String name;
  final UserRole role;
  final bool editLocked;

  User({
    this.id,
    required this.username,
    required this.name,
    required this.role,
    this.editLocked = false,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isEditor => (role == UserRole.editor || role == UserRole.admin) && !editLocked; // Se editLocked for verdadeiro, não tem poder de edição!
  bool get isViewer => role == UserRole.viewer || editLocked;

  String get roleName {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.editor:
        return 'Editor';
      case UserRole.viewer:
        return 'Visualizador';
    }
  }
}
