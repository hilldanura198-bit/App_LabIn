class AppValidation {
  const AppValidation._();

  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$",
  );

  static final RegExp whatsappRegex = RegExp(
    r'^(?:\+62|62|0)8[1-9][0-9]{6,11}$',
  );

  static final RegExp nimRegex = RegExp(r'^\d{8,15}$');

  static bool isValidEmail(String value) {
    return emailRegex.hasMatch(value.trim());
  }

  static bool isValidWhatsappNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s\-]'), '');
    return whatsappRegex.hasMatch(normalized);
  }

  static String normalizeWhatsappNumber(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (normalized.startsWith('08')) {
      normalized = '+62${normalized.substring(1)}';
    } else if (normalized.startsWith('62')) {
      normalized = '+$normalized';
    }
    return normalized;
  }

  static bool isValidNim(String value) {
    return nimRegex.hasMatch(value.trim());
  }
}
