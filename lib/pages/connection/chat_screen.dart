// import 'package:chating/utils.dart';
// import 'package:contacts_service/contacts_service.dart';
// import 'package:dash_chat_2/dash_chat_2.dart';
// import 'package:flutter/material.dart';
//
// class ChatScreen extends StatefulWidget {
//   final Contact contact;
//
//   const ChatScreen({Key? key, required this.contact}) : super(key: key);
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: true,
//         centerTitle: false,
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: 37,
//               height: 37,
//               child: CircleAvatar(
//                 child: Text(
//                   widget.contact.initials(),
//                   style: StyleText(),
//                 ),
//               ),
//             ),
//             SizedBox(width: 15),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.contact.displayName!,
//                   overflow: TextOverflow.ellipsis,
//                   style: StyleText(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   widget.contact.phones!.isNotEmpty
//                       ? widget.contact.phones!.first.value ?? ''
//                       : '',
//                   style: StyleText(
//                     color: Colors.white,
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.videocam,
//               color: Colors.white,
//             ),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.call,
//               color: Colors.white,
//             ),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       // body: DashChat(
//       //   // user: User(id: chatUser.id), // Adjust according to your User model
//       //   messages: [], // Initialize with chat messages if any
//       //   onSend: (message) {
//       //     // Handle sending messages
//       //   }, currentUser: null,
//       // ),
//     );
//   }
// }
