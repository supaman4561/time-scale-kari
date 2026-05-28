class Category {
  final int? id;
  final String name;
  final String type; // 'quota' or 'limit'
  final String color;
  final int budgetMin;
  /// 曜日ビットマスク: bit0=月, bit1=火, ..., bit6=日 (127=全曜日)
  final int activeDays;
  final int sortOrder;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.budgetMin,
    this.activeDays = 127,
    required this.sortOrder,
  });

  /// 指定日がアクティブかどうか (DateTime.weekday: 月=1, ..., 日=7)
  bool isActiveOn(DateTime date) =>
      (activeDays & (1 << (date.weekday - 1))) != 0;

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        color: map['color'] as String,
        budgetMin: map['weekday_budget_min'] as int,
        activeDays: (map['active_days'] as int?) ?? 127,
        sortOrder: map['sort_order'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'color': color,
        'weekday_budget_min': budgetMin,
        'weekend_budget_min': budgetMin, // 旧列は同値で維持
        'active_days': activeDays,
        'sort_order': sortOrder,
      };

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? color,
    int? budgetMin,
    int? activeDays,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color ?? this.color,
        budgetMin: budgetMin ?? this.budgetMin,
        activeDays: activeDays ?? this.activeDays,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
