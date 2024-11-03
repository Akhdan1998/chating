import 'package:chating/models/group.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../models/fitur.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/database_service.dart';
import '../service/navigation_service.dart';
import 'notifikasi_page.dart';

class DetailGroupPage extends StatefulWidget {
  final List<UserProfile> users;
  late final Group grup;
  final Future<void> Function(String) onDeleteAllMessages;
  final VoidCallback onLeaveGroup;

  DetailGroupPage({
    required this.users,
    required this.grup,
    required this.onDeleteAllMessages,
    required this.onLeaveGroup,
  });

  @override
  State<DetailGroupPage> createState() => _DetailGroupPageState();
}

class _DetailGroupPageState extends State<DetailGroupPage> {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  late DatabaseService _databaseService;
  late AlertService _alertService;
  List<UserProfile> _users = [];
  final List<int> selectedUserIndexes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _loadUsers();
  }

  List<Fitur> fitur = [
    Fitur(
      id: '1',
      icon: Icons.call,
      title: 'Audio',
    ),
    Fitur(
      id: '2',
      icon: Icons.videocam_outlined,
      title: 'Video',
    ),
    Fitur(
      id: '3',
      icon: Icons.search,
      title: 'Search',
    ),
  ];

  void _loadUsers() async {
    var userProfiles = await _databaseService.getUserProfiles().first;
    setState(() {
      _users = userProfiles.docs.map((doc) => doc.data() as UserProfile).toList();
    });
  }

  void _showModalBottomSheet(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    var userProfiles = await _databaseService.getUserProfiles().first;
    setState(() {
      _users = userProfiles.docs
          .map((doc) => doc.data() as UserProfile)
          .toList();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            setState(() {
              selectedUserIndexes.clear();
            });
            return true;
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding: MediaQuery.of(context).viewInsets,
                child: Container(
                  height: 500,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            UserProfile user = _users[index];
                            bool isSelected = selectedUserIndexes.contains(index);
                            bool isMember = widget.grup.members.contains(user.uid);
                            if (isMember) {
                              return SizedBox.shrink(); // Skip rendering
                            }
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedUserIndexes.remove(index);
                                  } else {
                                    selectedUserIndexes.add(index);
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                color: Colors.transparent,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            : Colors.white,
                                        border: Border.all(
                                          width: 1,
                                          color: Colors.grey,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      width: MediaQuery.of(context).size.width - 70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(user.name ?? '-'),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(user.pfpURL!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      _createGroupButton(setState, _isLoading, context),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _createGroupButton(void Function(void Function()) setState,
      bool isLoading, BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: MaterialButton(
        color: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          setState(() {
            _isLoading = true;
          });

          await _addMembersToGroup().whenComplete(() {
            Navigator.pop(context);
          });

          setState(() {
            selectedUserIndexes.clear();
            _isLoading = false;
          });
        },
        child: (_isLoading == true)
            ? Text(
                'Add Member',
                style: TextStyle(color: Colors.white),
              )
            : SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _addMembersToGroup() async {
    List<String> selectedUserIds = selectedUserIndexes.map((index) => _users[index].uid!).toList();
    await _databaseService.addMembersToGroup(widget.grup.id, selectedUserIds);

    final updatedGroup = await _databaseService.getGroupById(widget.grup.id);
    setState(() {
      widget.grup = updatedGroup;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = DateFormat('yyyy-MM-dd hh:mm:ss').parse(widget.grup.createdAt.toString());
    String date_n = DateFormat('yMMMMd').format(date);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _showModalBottomSheet(context);
                  },
                  leading: Text('Add Members'),
                  trailing: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
        title: Text(
          'Group Info',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black54,
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return AlertDialog(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          content: Image.network(widget.grup.imageUrl),
                        );
                      },
                      transitionBuilder:
                          (context, anim1, anim2, child) {
                        return Transform.scale(
                          scale: anim1.value,
                          child: child,
                        );
                      },
                    );
                    // showDialog(context: context, builder: (BuildContext context) {
                    //   return AlertDialog(
                    //     contentPadding: EdgeInsets.zero,
                    //     content: Image.network(widget.grup.imageUrl),
                    //   );
                    // });
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    width: constraints.maxWidth * 0.4,
                    height: constraints.maxWidth * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(widget.grup.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  widget.grup.name,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Group • ${widget.grup.members.length} Members',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 15),
                Wrap(
                  spacing: 14,
                  runSpacing: 15,
                  children: fitur.map((e) => ButtonFitur(e)).toList(),
                ),
                SizedBox(height: 15),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: constraints.maxWidth - 94,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Media dan Document',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '6',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _navigationService.push(
                      MaterialPageRoute(builder: (context) {
                        return NotifikasiPage(group: widget.grup);
                      }),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: constraints.maxWidth - 94,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notification',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${widget.grup.members.length} Members',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: constraints.maxWidth,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.grup.members.map((memberId) {
                      final userProfile = widget.users.firstWhere(
                            (user) => user.uid == memberId,
                        orElse: () => UserProfile(
                          uid: memberId,
                          name: 'You',
                          pfpURL: '',
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(userProfile.pfpURL ?? ''),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProfile.name.toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    userProfile.phoneNumber ?? '-',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  width: constraints.maxWidth,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins().copyWith(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await widget.onDeleteAllMessages(widget.grup.id);
                                    },
                                    child: Text(
                                      'Yes',
                                      style: GoogleFonts.poppins().copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                title: Column(
                                  children: [
                                    Text(
                                      'Clear All Messages from "${widget.grup.name}"?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.deepPurple.shade100,
                                      ),
                                      child: Text(
                                        'This chat will be empty, but will remain in your chat list.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: constraints.maxWidth,
                          color: Colors.transparent,
                          child: Text(
                            'Clear Chat',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Divider(),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins().copyWith(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      widget.onLeaveGroup();
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Yes',
                                      style: GoogleFonts.poppins().copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                title: Column(
                                  children: [
                                    Text(
                                      'Do you want to exit the group "${widget.grup.name}"?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.deepPurple.shade100,
                                      ),
                                      child: Text(
                                        'Only group admins will be notified that you leave the group.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: constraints.maxWidth,
                          color: Colors.transparent,
                          child: Text(
                            'Exit Group',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  margin: EdgeInsets.only(left: 20),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created on $date_n.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ButtonFitur extends StatelessWidget {
  final Fitur fitur;

  ButtonFitur(this.fitur);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = screenWidth * 0.27;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fitur.icon,
              size:  buttonSize * 0.3,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 5),
            Text(
              fitur.title ?? '-',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
