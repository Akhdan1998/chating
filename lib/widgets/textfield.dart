import 'package:flutter/material.dart';

class TextFieldCustom extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final bool icon;
  final bool readOnly;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double height;
  final RegExp validationRegEx;
  final void Function(String?) onSaved;

  const TextFieldCustom({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.icon = false,
    this.readOnly = false,
    this.controller,
    this.focusNode,
    required this.height,
    required this.validationRegEx,
    required this.onSaved,
  });

  @override
  State<TextFieldCustom> createState() => _TextFieldCustomState();
}

class _TextFieldCustomState extends State<TextFieldCustom> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      keyboardType: TextInputType.emailAddress,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      controller: widget.controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  size: 20,
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}