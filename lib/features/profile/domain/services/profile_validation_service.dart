class ProfileValidationService {
  static final RegExp _dobPattern = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$',
  );
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.(com|in|org)$',
  );
  static final RegExp _allSameDigitPattern = RegExp(r'^(\d)\1{9}$');

  static const Set<String> _allowedGenders = {
    'Male',
    'Female',
    'Others',
    'Prefer not to say',
  };

  static const Map<String, int> _monthIndexByName = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };

  String? validateName(String name) {
    if (name.isEmpty) return 'Please enter your full name';
    if (name.trim().isEmpty) return 'Please enter your full name';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(name)) {
      return 'Full Name should contain only alphabets and spaces.';
    }
    final trimmed = name.trim();
    if (trimmed.length < 2) return 'Full Name must be at least 2 characters.';
    if (trimmed.length > 50) return 'Full Name must be 50 characters or fewer.';
    return null;
  }

  String? validateGender(String gender) {
    final value = gender.trim();
    if (value.isEmpty) return 'Please select your gender';
    if (!_allowedGenders.contains(value)) return 'Please select a valid gender';
    return null;
  }

  String? validateDob(String dob) {
    final value = dob.trim();
    if (value.isEmpty) return 'Please select your date of birth';

    final match = _dobPattern.firstMatch(value);
    if (match == null) return 'Please select a valid date of birth';

    final day = int.tryParse(match.group(1)!);
    final month = _monthIndexByName[match.group(2)!.toLowerCase()];
    final year = int.tryParse(match.group(3)!);

    if (day == null || month == null || year == null) {
      return 'Please select a valid date of birth';
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return 'Please select a valid date of birth';
    }

    final now = DateTime.now();
    if (parsed.isAfter(now)) return 'Date of birth cannot be in the future';

    final age =
        now.year -
        parsed.year -
        ((now.month < parsed.month ||
                (now.month == parsed.month && now.day < parsed.day))
            ? 1
            : 0);

    if (age < 18) return 'You must be at least 18 years old';
    if (age > 100) return 'Please enter a valid date of birth';

    return null;
  }

  String? validateEmergencyContact(String emergencyContact) {
    final digits = emergencyContact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 10) return 'Emergency contact must be 10 digits';
    if (_allSameDigitPattern.hasMatch(digits)) {
      return 'Emergency contact number is invalid';
    }
    if (!digits.startsWith(RegExp(r'[6-9]'))) {
      return 'Enter a valid emergency contact number';
    }
    return null;
  }

  String? validateEmail(String email) {
    final value = email.trim();
    if (value.isEmpty) return 'Please enter your email address';
    if (!_emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
