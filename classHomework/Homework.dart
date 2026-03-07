// Task 1: Process a list with a predicate function
List<int> processList(List<int> numbers, bool Function(int) predicate) {
  return numbers.where(predicate).toList();
}

// Task 2: Print words longer than four characters
void printWordsLongerThanFour() {
  List<String> words = ["apple", "cat", "banana", "dog", "elephant"];

  Map<String, int> lengthMap = {for (var w in words) w: w.length};

  lengthMap.entries
      .where((entry) => entry.value > 4)
      .forEach((entry) => print("${entry.key} has length ${entry.value}"));
}

// Task 3: Calculate average age for names starting with A or B
class Person {
  String name;
  int age;

  Person(this.name, this.age);
}

String formatToOneDecimal(double value) => value.toStringAsFixed(1);

void printAverageAgeForNamesStartingWithAOrB() {
  List<Person> people = [
    Person("Alice", 25),
    Person("Bob", 30),
    Person("Charlie", 35),
    Person("Anna", 22),
    Person("Ben", 28),
  ];

  var matchingAges = people
      .where((p) => p.name.startsWith('A') || p.name.startsWith('B'))
      .map((p) => p.age)
      .toList();

  double average = matchingAges.isNotEmpty
      ? matchingAges.reduce((a, b) => a + b) / matchingAges.length
      : 0.0;

  print("Average age: ${formatToOneDecimal(average)}");
}

void main() {
  print("Task 1:");
  List<int> nums = [1, 2, 3, 4, 5, 6];
  var even = processList(nums, (n) => n % 2 == 0);
  print(even);

  print("\nTask 2:");
  printWordsLongerThanFour();

  print("\nTask 3:");
  printAverageAgeForNamesStartingWithAOrB();
}
