class AppConstants {
  AppConstants._();

  // Pagination
  static const int pageSize = 20;

  // Order statuses
  static const String orderPending = 'PENDING';
  static const String orderConfirmed = 'CONFIRMED';
  static const String orderShipping = 'SHIPPING';
  static const String orderDelivered = 'DELIVERED';
  static const String orderCancelled = 'CANCELLED';

  // Payment modes
  static const String paymentPrepaid = 'PREPAID';
  static const String paymentDirect = 'DIRECT';

  // Tontine statuses
  static const String tontineActive = 'ACTIVE';
  static const String tontineCompleted = 'COMPLETED';
  static const String tontinePending = 'PENDING';
}
