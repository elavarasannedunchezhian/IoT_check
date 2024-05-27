class Level implements Comparable<Level> {
  final String name;
  final int value;
  const Level(this.name, this.value);

  static const Level DEBUG = Level('DEBUG', 300);
  static const Level INFO = Level('INFO', 500);
  static const Level WARNING = Level('WARNING', 900);
  static const Level ERROR = Level('ERROR', 1200);

  static const List<Level> LEVELS = [
    DEBUG,
    ERROR,
    WARNING,
    INFO,
  ];

  @override
  bool operator ==(Object other) => other is Level && value == other.value;

  bool operator <(Level other) => value < other.value;

  bool operator <=(Level other) => value <= other.value;

  bool operator >(Level other) => value > other.value;

  bool operator >=(Level other) => value >= other.value;

  @override
  int compareTo(Level other) => value - other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => name;
}