class DashboardStats {
  final int totalFilms;
  final int totalCopies;
  final int activeRentals;
  final int returnedRentals;

  DashboardStats({
    required this.totalFilms,
    required this.totalCopies,
    required this.activeRentals,
    required this.returnedRentals,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalFilms: json['totalFilms'] ?? 0,
      totalCopies: json['totalCopies'] ?? 0,
      activeRentals: json['activeRentals'] ?? 0,
      returnedRentals: json['returnedRentals'] ?? 0,
    );
  }
}
