class SupportContact {
  const SupportContact({
    required this.label,
    required this.display,
    required this.dial,
  });

  final String label;
  final String display;
  final String dial;
}

abstract final class SupportContacts {
  // Source: NCMH crisis hotline numbers as reported by Philstar Life,
  // 26 Dec 2025. RE-VERIFY before any demo, defense, or deployment.
  static const List<SupportContact> ncmhCrisisHotline = [
    SupportContact(
      label: 'From a landline (toll-free)',
      display: '1553',
      dial: '1553',
    ),
    SupportContact(
      label: 'Smart / TNT',
      display: '0919 057 1553',
      dial: '09190571553',
    ),
    SupportContact(
      label: 'Globe / TM',
      display: '0917 899 8727',
      dial: '09178998727',
    ),
  ];

  static const SupportContact emergency = SupportContact(
    label: 'National emergency hotline',
    display: '911',
    dial: '911',
  );
}