import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;

typedef ComputeFunction<RESULT, PARAM> =
    FutureOr<RESULT> Function(PARAM parameter);

Future<RESULT> compute<PARAM extends Object, RESULT extends Object>(
  ComputeFunction<RESULT, PARAM> function,
  PARAM parameter,
) async {
  final RESULT result = await foundation.compute(function, parameter);
  return result;
}
