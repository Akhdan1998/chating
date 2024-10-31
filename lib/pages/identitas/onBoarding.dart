import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';

class Boarding extends StatefulWidget {
  const Boarding({super.key});

  @override
  State<Boarding> createState() => _BoardingState();
}

class _BoardingState extends State<Boarding> {
  bool dropdownIcon = false;
  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        selectedLanguage = _getLanguageFromLocale(context.locale);
      });
    });
  }

  String _getLanguageFromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'ko':
        return 'Korea';
      default:
        return 'English'; // Default language
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle:
          GoogleFonts.poppins().copyWith(fontSize: 14, color: Colors.white),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
    double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Image.asset('assets/boarding.png', scale: 3,),
            Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Center(
                child: Column(
                  children: [
                    Text('welcome'.tr(), style: GoogleFonts.poppins(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold,),),
                    SizedBox(height: 15),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 18,),
                        children: [
                          TextSpan(text: 'read_our'.tr(), style: GoogleFonts.poppins(),),
                          TextSpan(
                            text: 'privacy_policy'.tr(),
                            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold,),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Aksi ketika "Kebijakan Privasi" ditekan
                                print('Kebijakan Privasi ditekan'.tr());
                              },
                          ),
                          TextSpan(text: 'tap_to_accept'.tr(), style: GoogleFonts.poppins(),),
                          TextSpan(
                            text: 'terms_of_service'.tr(),
                            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold,),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Aksi ketika "Ketentuan Layanan" ditekan
                                print('Ketentuan Layanan ditekan'.tr());
                              },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    ExpansionTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.transparent,
                      leading: Icon(
                        Icons.translate,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        selectedLanguage,
                        style: GoogleFonts.poppins().copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(
                        dropdownIcon ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          dropdownIcon = expanded;
                        });
                      },
                      children: [
                        ListTile(
                          title: Text('Bahasa Indonesia', style: GoogleFonts.poppins(),),
                          onTap: () => _changeLanguage('Bahasa Indonesia'),
                        ),
                        ListTile(
                          title: Text('English', style: GoogleFonts.poppins(),),
                          onTap: () => _changeLanguage('English'),
                        ),
                        ListTile(
                          title: Text('Korea', style: GoogleFonts.poppins(),),
                          onTap: () => _changeLanguage('Korea'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: Duration(microseconds: 500),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          color: Colors.grey.shade100,
          alignment: Alignment.bottomCenter,
          width: MediaQuery.of(context).size.width,
          height: 60,
          padding: EdgeInsets.fromLTRB(13, 8, 13, 8),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 40,
            child: ElevatedButton(
              style: style,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              child: Text(
                'agree_and_continue'.tr(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white,),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeLanguage(String language) {
    Locale newLocale;
    switch (language) {
      case 'Bahasa Indonesia':
        newLocale = Locale('id');
        break;
      case 'English':
        newLocale = Locale('en');
        break;
      case 'Korea':
        newLocale = Locale('ko');
        break;
      default:
        newLocale = Locale('en');
    }
    context.setLocale(newLocale);
    setState(() {
      selectedLanguage = language;
    });
  }
}
