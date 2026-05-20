class Category {
  final int? id;
  final String name;
  final String type; // 'quota' or 'limit'
  final String color;
  final int weekdayBudgetMin;
  final int weekendBudgetMin;
  final int sortOrder;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.weekdayBudgetMin,
    required this.weekendBudgetMin,
    required this.sortOrder,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        color: map['color'] as String,
        weekdayBudgetMin: map['weekday_budget_min'] as int,
        weekendBudgetMin: map['weekend_budget_min'] as int,
        sortOrder: map['sort_order'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'color': color,
        'weekday_budget_min': weekdayBudgetMin,
        'weekend_budget_min': weekendBudgetMin,
        'sort_order': sortOrder,
      };

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? color,
    int? weekdayBudgetMin,
    int? weekendBudgetMin,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color ?? this.color,
        weekdayBudgetMin: weekdayBudgetMin ?? this.weekdayBudgetMin,
        weekendBudgetMin: weekendBudgetMin ?? this.weekendBudgetMin,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
