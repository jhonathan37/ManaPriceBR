import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/core/services/sale_calculator.dart';

describe('SaleCalculator', () {
  test('calculates final value after discount', () {
    expect(SaleCalculator.finalValue(100, 15), closeTo(85, 0.000001));
    expect(SaleCalculator.discountAmount(100, 15), closeTo(15, 0.000001));
  });

  test('clamps invalid discount values', () {
    expect(SaleCalculator.finalValue(100, -20), closeTo(100, 0.000001));
    expect(SaleCalculator.finalValue(100, 120), closeTo(0, 0.000001));
  });
});
