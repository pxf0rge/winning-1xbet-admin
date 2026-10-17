/// Thrown when a manual match with same teams/date/sport already exists.
class DuplicateMatchException implements Exception {
  final String message;
  DuplicateMatchException([this.message = 'Duplicate match']);

  @override
  String toString() => message;
}
