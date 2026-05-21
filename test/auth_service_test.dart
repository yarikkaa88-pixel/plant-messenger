import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/plant_data_service.dart';

void main() {
  test('formatTime returns time for today', () {
    final now = DateTime.now();
    final result = PlantDataService.formatTime(now);
    expect(result.contains(':'), isTrue);
  });
}
