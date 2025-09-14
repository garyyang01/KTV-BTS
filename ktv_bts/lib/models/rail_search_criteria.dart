/// 鐵路搜尋條件模型
/// 用於 G2Rail API 的搜尋參數
class RailSearchCriteria {
  final String from;
  final String to;
  final String date;
  final String time;
  final int adult;
  final int child;
  final int junior;
  final int senior;
  final int infant;

  const RailSearchCriteria({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    this.adult = 1,
    this.child = 0,
    this.junior = 0,
    this.senior = 0,
    this.infant = 0,
  });

  /// 轉換為查詢字串
  String toQueryString() {
    return "from=$from&to=$to&date=$date&time=$time"
        "&adult=$adult&child=$child&junior=$junior"
        "&senior=$senior&infant=$infant";
  }

  /// 轉換為 Map 格式（用於認證簽名）
  Map<String, dynamic> toMap() {
    return {
      "from": from,
      "to": to,
      "date": date,
      "time": time,
      "adult": adult,
      "child": child,
      "junior": junior,
      "senior": senior,
      "infant": infant,
    };
  }

  @override
  String toString() {
    return 'RailSearchCriteria(from: $from, to: $to, date: $date, time: $time, '
        'adult: $adult, child: $child, junior: $junior, senior: $senior, infant: $infant)';
  }
}
