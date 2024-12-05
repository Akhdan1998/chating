import 'package:chating/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  ChatTile({
    required this.userProfile,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(userProfile.pfpURL ?? ''),
      ),
      title: Text(
        userProfile.name ?? '',
        style: StyleText(fontSize: 15,
          fontWeight: FontWeight.w600,),
      ),
      subtitle: Text(
        userProfile.phoneNumber ?? '-',
        style: StyleText(fontSize: 12),
      ),
    );
  }
}
