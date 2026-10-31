
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<double> fetchRate() async {
  final url = Uri.parse(
    'https://open.er-api.com/v6/latest/USD',
  );

  try {
    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'API request failed. Status: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (data['result'] != 'success') {
      throw Exception('The exchange-rate API returned an error.');
    }

    final rates = data['rates'] as Map<String, dynamic>?;
    final rwfRate = rates?['RWF'];

    if (rwfRate == null || rwfRate is! num) {
      throw Exception('RWF exchange rate was not found.');
    }

    return rwfRate.toDouble();
  } catch (e) {
    debugPrint('Exchange rate error: $e');
    rethrow;
  }
}
