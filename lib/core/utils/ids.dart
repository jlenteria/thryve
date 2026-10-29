import 'package:uuid/uuid.dart';

/// Generates ids for new goals, practices, milestones and Wall items.
abstract final class Ids {
  static const Uuid _uuid = Uuid();

  static String next() => _uuid.v4();
}
