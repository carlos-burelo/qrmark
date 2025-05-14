import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum InputType { text, textarea, number, email, phone, password, date, time, datetime }

class InputField extends StatefulWidget {
  final InputType type;

  final dynamic value;

  final String label;

  final String? hint;

  final Widget? prefix;

  final Widget? suffix;

  final IconData? prefixIcon;

  final IconData? suffixIcon;

  final Function(dynamic value)? onChanged;

  final Function(dynamic value)? onSubmitted;

  final int? maxLines;

  final int? minLines;

  final double? maxHeight;

  final int? maxLength;

  final bool required;

  final bool disabled;

  final bool readOnly;

  final String? errorText;

  final bool autoValidate;

  final String? Function(String?)? validator;

  final InputDecoration? decoration;

  final Color? focusColor;

  final Color? textColor;

  final double? fontSize;

  final String? dateFormat;

  final String? timeFormat;

  final DateTime? minDate;

  final DateTime? maxDate;

  final TextEditingController? controller;

  final FocusNode? focusNode;

  final TextInputAction? textInputAction;

  final bool? autocorrect;

  final VoidCallback? onSuffixIconPressed;

  const InputField({
    super.key,
    required this.type,
    this.value,
    required this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.maxLines,
    this.minLines,
    this.maxHeight,
    this.maxLength,
    this.required = false,
    this.disabled = false,
    this.readOnly = false,
    this.errorText,
    this.autoValidate = false,
    this.validator,
    this.decoration,
    this.focusColor,
    this.textColor,
    this.fontSize,
    this.dateFormat,
    this.timeFormat,
    this.minDate,
    this.maxDate,
    this.controller,
    this.focusNode,
    this.textInputAction,
    this.autocorrect,
    this.onSuffixIconPressed,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  dynamic _value;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _value = widget.value;

    if (widget.value != null) {
      _setControllerValue(widget.value);
    }

    if (widget.autoValidate && widget.validator != null) {
      _errorText = widget.validator!(_controller.text);
    }
  }

  @override
  void didUpdateWidget(InputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
      _setControllerValue(widget.value);
    }

    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  void _setControllerValue(dynamic value) {
    if (value == null) {
      _controller.text = '';
      return;
    }

    switch (widget.type) {
      case InputType.date:
        final format = DateFormat(widget.dateFormat ?? 'yyyy-MM-dd');
        _controller.text = format.format(value as DateTime);
        break;
      case InputType.time:
        if (value is TimeOfDay) {
          final format = widget.timeFormat ?? 'HH:mm';
          if (format == 'HH:mm') {
            _controller.text =
                '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
          } else {
            _controller.text = value.format(context);
          }
        } else if (value is DateTime) {
          final format = DateFormat(widget.timeFormat ?? 'HH:mm');
          _controller.text = format.format(value);
        }
        break;
      case InputType.datetime:
        final format = DateFormat(widget.dateFormat ?? 'yyyy-MM-dd HH:mm');
        _controller.text = format.format(value as DateTime);
        break;
      default:
        _controller.text = value.toString();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _value is DateTime ? _value : DateTime.now(),
      firstDate: widget.minDate ?? DateTime(1900),
      lastDate: widget.maxDate ?? DateTime(2100),

      builder: (context, child) => child!,
    );

    if (pickedDate != null) {
      setState(() {
        _value = pickedDate;
        _setControllerValue(_value);
        if (widget.onChanged != null) {
          widget.onChanged!(_value);
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay initialTime =
        _value is TimeOfDay
            ? _value
            : (_value is DateTime ? TimeOfDay.fromDateTime(_value) : TimeOfDay.now());

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,

      builder: (context, child) => child!,
    );

    if (pickedTime != null) {
      setState(() {
        if (_value is DateTime) {
          final DateTime newDateTime = DateTime(
            _value.year,
            _value.month,
            _value.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _value = newDateTime;
        } else {
          _value = pickedTime;
        }

        _setControllerValue(_value);
        if (widget.onChanged != null) {
          widget.onChanged!(_value);
        }
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _value is DateTime ? _value : DateTime.now(),
      firstDate: widget.minDate ?? DateTime(1900),
      lastDate: widget.maxDate ?? DateTime(2100),
      builder: (context, child) {
        return child!;
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;

    final TimeOfDay initialTime =
        _value is DateTime ? TimeOfDay.fromDateTime(_value) : TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: widget.focusColor ?? Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        _setControllerValue(_value);
        if (widget.onChanged != null) {
          widget.onChanged!(_value);
        }
      });
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case InputType.number:
        return TextInputType.number;
      case InputType.email:
        return TextInputType.emailAddress;
      case InputType.phone:
        return TextInputType.phone;
      case InputType.textarea:
        return TextInputType.multiline;
      case InputType.password:
        return TextInputType.visiblePassword;
      case InputType.date:
      case InputType.time:
      case InputType.datetime:
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters() {
    switch (widget.type) {
      case InputType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case InputType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  int? _getMaxLines() {
    switch (widget.type) {
      case InputType.textarea:
        return widget.maxLines;
      default:
        return widget.type == InputType.textarea ? null : 1;
    }
  }

  int? _getMinLines() {
    switch (widget.type) {
      case InputType.textarea:
        return widget.minLines ?? 3;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration;

    if (widget.decoration != null) {
      inputDecoration = widget.decoration!.copyWith(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: _errorText ?? widget.errorText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : widget.prefix,
        suffixIcon: _buildSuffixIcon(),
        enabled: !widget.disabled,
      );
    } else {
      final theme = Theme.of(context);
      inputDecoration = InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: _errorText ?? widget.errorText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : widget.prefix,
        suffixIcon: _buildSuffixIcon(),
        enabled: !widget.disabled,
        alignLabelWithHint: true,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        errorBorder: theme.inputDecorationTheme.errorBorder,
        focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
        disabledBorder: theme.inputDecorationTheme.disabledBorder,
        fillColor: theme.inputDecorationTheme.fillColor,
        filled: theme.inputDecorationTheme.filled,
        isDense: theme.inputDecorationTheme.isDense,
        contentPadding: theme.inputDecorationTheme.contentPadding,
      );
    }

    final textStyle =
        widget.disabled
            ? Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).disabledColor)
            : Theme.of(context).textTheme.bodyLarge;

    final bool isDateTimeField =
        widget.type == InputType.date ||
        widget.type == InputType.time ||
        widget.type == InputType.datetime;

    final bool fieldReadOnly = widget.readOnly || isDateTimeField;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: inputDecoration,
      keyboardType: _getKeyboardType(),
      inputFormatters: _getInputFormatters(),
      maxLines: _getMaxLines(),
      minLines: _getMinLines(),
      maxLength: widget.maxLength,
      enabled: !widget.disabled,
      readOnly: fieldReadOnly,
      style: textStyle,
      textInputAction: widget.textInputAction,
      autocorrect: widget.autocorrect ?? true,
      obscureText: widget.type == InputType.password ? _obscureText : false,
      onChanged: (value) {
        if (widget.validator != null && widget.autoValidate) {
          setState(() {
            _errorText = widget.validator!(value);
          });
        }

        dynamic newValue;

        switch (widget.type) {
          case InputType.number:
            newValue = int.tryParse(value) ?? double.tryParse(value);
            break;
          default:
            newValue = value;
        }

        _value = newValue;

        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
      onSubmitted: (value) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(_value);
        }
      },
      onTap:
          isDateTimeField
              ? () {
                switch (widget.type) {
                  case InputType.date:
                    _selectDate(context);
                    break;
                  case InputType.time:
                    _selectTime(context);
                    break;
                  case InputType.datetime:
                    _selectDateTime(context);
                    break;
                  default:
                    break;
                }
              }
              : null,
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) {
      return widget.suffix;
    }

    if (widget.suffixIcon != null) {
      return IconButton(icon: Icon(widget.suffixIcon), onPressed: widget.onSuffixIconPressed);
    }

    if (widget.type == InputType.password) {
      return IconButton(
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    switch (widget.type) {
      case InputType.date:
        return IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        );
      case InputType.time:
        return IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _selectTime(context),
        );
      case InputType.datetime:
        return IconButton(icon: const Icon(Icons.event), onPressed: () => _selectDateTime(context));
      default:
        return null;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }
}
