// import 'package:chating/wkwk_state.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../models/api_return.dart';
// import 'models/modelCubit.dart';
// import 'models/services.dart';
//
// class VCCubit extends Cubit<VCState> {
//   VCCubit() : super(VCInitial());
//
//   Future<void> getVC(String channelName) async {
//     ApiReturnM<VC>? result = await VCServices.getVC(channelName);
//     if (result?.value != null) {
//       emit(VCLoaded(getvc: result?.value));
//     } else {
//       emit(VCLoadingFailed(result?.message));
//     }
//   }
// }
