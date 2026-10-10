enum UserStatus {
  phoneUnverified,
  kycPending,
  active,
  suspended,
  blocked,
  closed;

  static UserStatus fromJson(String value) {
    const map = {
      'PHONE_UNVERIFIED': UserStatus.phoneUnverified,
      'KYC_PENDING': UserStatus.kycPending,
      'ACTIVE': UserStatus.active,
      'SUSPENDED': UserStatus.suspended,
      'BLOCKED': UserStatus.blocked,
      'CLOSED': UserStatus.closed,
    };
    return map[value.toUpperCase()] ?? UserStatus.kycPending;
  }

  String toJson() {
    const map = {
      UserStatus.phoneUnverified: 'PHONE_UNVERIFIED',
      UserStatus.kycPending: 'KYC_PENDING',
      UserStatus.active: 'ACTIVE',
      UserStatus.suspended: 'SUSPENDED',
      UserStatus.blocked: 'BLOCKED',
      UserStatus.closed: 'CLOSED',
    };
    return map[this]!;
  }
}