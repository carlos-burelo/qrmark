class Validators {
  static String? email(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.toString())) {
      return 'Ingrese un correo electrónico válido';
    }

    return null;
  }

  static String? password(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }

    if (value.toString().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  static String? name(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }

    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    if (!nameRegex.hasMatch(value.toString().trim())) {
      return 'Ingrese un nombre válido';
    }

    return null;
  }
}
