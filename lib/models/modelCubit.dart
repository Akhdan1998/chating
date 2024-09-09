class VC {
  String? channelName;
  String? uid;
  String? token;

  VC({this.channelName, this.uid, this.token});

  VC.fromJson(Map<String, dynamic> json) {
    channelName = json['channelName'];
    uid = json['uid'];
    token = json['token'];
  }
}