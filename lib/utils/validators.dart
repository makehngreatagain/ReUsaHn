/// Clase de validadores para formularios
class Validators {
  // Validar nombre (solo letras, espacios y algunos caracteres especiales)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }

    // Permitir letras, espacios, acentos, ñ, apóstrofes y guiones
    final nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s'-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'El nombre solo puede contener letras';
    }

    return null;
  }

  // Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    // Expresión regular estándar para validar emails
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }

    if (value.length > 100) {
      return 'El email no puede exceder 100 caracteres';
    }

    return null;
  }

  // Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (value.length > 50) {
      return 'La contraseña no puede exceder 50 caracteres';
    }

    // Verificar que contenga al menos una letra y un número
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return 'La contraseña debe contener letras y números';
    }

    return null;
  }

  // Validar teléfono (Honduras: 8 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Teléfono es opcional
    }

    // Eliminar espacios, guiones y paréntesis
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Verificar que solo contenga números
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'El teléfono solo puede contener números';
    }

    // Para Honduras, validar 8 dígitos
    if (cleanPhone.length != 8) {
      return 'El teléfono debe tener 8 dígitos';
    }

    return null;
  }

  // Validar puntos verdes (solo números positivos)
  static String? validateGreenPoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los puntos son requeridos';
    }

    final points = int.tryParse(value.trim());

    if (points == null) {
      return 'Ingresa un número válido';
    }

    if (points < 0) {
      return 'Los puntos no pueden ser negativos';
    }

    if (points > 999999) {
      return 'El valor es demasiado grande';
    }

    return null;
  }

  // Validar biografía
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Bio es opcional
    }

    if (value.trim().length > 500) {
      return 'La biografía no puede exceder 500 caracteres';
    }

    return null;
  }

  // Validar campo de texto general (no vacío)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Validar números enteros positivos
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Ingresa un número válido';
    }

    if (number < 0) {
      return '$fieldName no puede ser negativo';
    }

    return null;
  }

  // Validar rango de números
  static String? validateNumberRange(
    String? value,
    String fieldName,
    int min,
    int max,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Ingresa un número válido';
    }

    if (number < min || number > max) {
      return '$fieldName debe estar entre $min y $max';
    }

    return null;
  }

  // Formatear teléfono (Honduras: XXXX-XXXX)
  static String formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleanPhone.length == 8) {
      return '${cleanPhone.substring(0, 4)}-${cleanPhone.substring(4)}';
    }

    return phone;
  }

  // Limpiar teléfono (remover formato)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // Validar solo letras y números (sin espacios)
  static String? validateAlphanumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '$fieldName solo puede contener letras y números';
    }

    return null;
  }

  // Validar URL (opcional)
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL es opcional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Ingresa una URL válida';
    }

    return null;
  }

  // Sanitizar texto (remover caracteres especiales peligrosos)
  static String sanitizeText(String text) {
    // Remover caracteres que podrían ser usados para inyección
    return text
        .replaceAll(RegExp(r'''[<>"'`]'''), '')
        .trim();
  }

  // Validar longitud mínima
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (value.trim().length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    return null;
  }

  // Validar longitud máxima
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }
}
