import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../../../models/api_return.dart';
import 'package:http/http.dart' as http;

import 'modelCubit.dart';

class VCServices {
  static Future<ApiReturnM<VC>?> getVC(String channelName) async {
    String baseUrl = 'http://45.130.229.79:5656/vc-token?channelName=$channelName&uid=123';
    String url = baseUrl;

    var response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data != null) {
        VC value = VC.fromJson(data["data"]);
        return ApiReturnM(value: value);
      }
      return ApiReturnM(message: 'Data Null');
    } else {
      return ApiReturnM(message: 'Please try Again');
    }
  }
}
