class ApiReturnC<T> {
  final T? data;
  final int statusCode;
  ApiReturnC({this.data, required this.statusCode});
}

class ApiReturnM<T> {
  final T? value;
  final String? message;
  ApiReturnM({this.value, this.message});
}