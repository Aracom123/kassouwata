enum BoutiqueStatus {
  active,
  suspended,
  pending,
  closed;

  static BoutiqueStatus fromJson(String value) {
    return BoutiqueStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => BoutiqueStatus.pending,
    );
  }

  String toJson() => name.toUpperCase();
}