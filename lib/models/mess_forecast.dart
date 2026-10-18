class MealForecastDetail {
  final String menu;
  final int forecast;
  final int served;
  final int remaining;

  MealForecastDetail({
    required this.menu,
    required this.forecast,
    required this.served,
    required this.remaining,
  });

  factory MealForecastDetail.fromJson(Map<String, dynamic> json) {
    return MealForecastDetail(
      menu: json['menu']?.toString() ?? 'Standard Menu',
      forecast: json['forecast'] as int? ?? 0,
      served: json['served'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
    );
  }
}

class MessForecast {
  final String date;
  final String dayOfWeek;
  final int totalActiveTenants;
  final int optedOutCount;
  final MealForecastDetail breakfast;
  final MealForecastDetail lunch;
  final MealForecastDetail dinner;

  MessForecast({
    required this.date,
    required this.dayOfWeek,
    required this.totalActiveTenants,
    required this.optedOutCount,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory MessForecast.fromJson(Map<String, dynamic> json) {
    final meals = json['meals'] as Map<String, dynamic>? ?? {};
    return MessForecast(
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      totalActiveTenants: json['total_active_tenants'] as int? ?? 0,
      optedOutCount: json['opted_out_count'] as int? ?? 0,
      breakfast: MealForecastDetail.fromJson(meals['breakfast'] as Map<String, dynamic>? ?? {}),
      lunch: MealForecastDetail.fromJson(meals['lunch'] as Map<String, dynamic>? ?? {}),
      dinner: MealForecastDetail.fromJson(meals['dinner'] as Map<String, dynamic>? ?? {}),
    );
  }
}
