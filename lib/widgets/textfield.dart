import 'package:flutter/material.dart';

class TextFieldCustom extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final bool icon;
  final bool readOnly;
  final bool autoFocus;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double height;
  final RegExp validationRegEx;
  final void Function(String?) onSaved;
  final double borderRadius;
  final Color fillColor;
  final BorderSide borderSide;
  final bool filled;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;

  const TextFieldCustom({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.icon = false,
    this.readOnly = false,
    this.autoFocus = false,
    this.controller,
    this.focusNode,
    required this.height,
    required this.validationRegEx,
    required this.onSaved,
    this.borderRadius = 10.0,
    this.fillColor = Colors.white,
    this.borderSide = BorderSide.none,
    this.filled = true,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
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
    return Container(
      color: Colors.transparent,
      child: TextFormField(
        autofocus: widget.autoFocus,
        textCapitalization: widget.textCapitalization,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.emailAddress,
        obscureText: _obscureText,
        readOnly: widget.readOnly,
        controller: widget.controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          filled: widget.filled,
          fillColor: widget.fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: widget.borderSide,
          ),
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
      ),
    );
  }
}