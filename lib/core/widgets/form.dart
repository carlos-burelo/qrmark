import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/utils/date.dart';
import 'package:qrmark/core/widgets/column.dart';

enum InputType {
  text,
  email,
  password,
  number,
  phone,
  date,
  time,
  datetime,
  select,
  switch_,
  checkbox,
  radio,
  rrule,
}

typedef FormValues = Map<String, dynamic>;

class FormController extends ChangeNotifier {
  final FormValues _values = {};
  final Map<String, String?> _errors = {};
  final Map<String, FormFieldDefinition> _fieldDefinitions = {};
  Function(FormValues)? _onSubmitCallback;
  bool _isResetting = false;

  FormValues get values => Map.unmodifiable(_values);
  Map<String, String?> get errors => Map.unmodifiable(_errors);
  T? getValue<T>(String fieldId) => _values[fieldId] as T?;
  String? getError(String fieldId) => _errors[fieldId];

  void setOnSubmitCallback(Function(FormValues)? callback) {
    _onSubmitCallback = callback;
  }

  void registerField(FormFieldDefinition definition) {
    _fieldDefinitions[definition.id] = definition;
    if (definition.initialValue != null) {
      _values[definition.id] = definition.initialValue;
    }
  }

  void unregisterField(String fieldId) {
    if (_fieldDefinitions.containsKey(fieldId)) {
      _fieldDefinitions.remove(fieldId);

      _values.remove(fieldId);
      _errors.remove(fieldId);
    }
  }

  void setValue(String fieldId, dynamic value) {
    _values[fieldId] = value;
    final fieldDef = _fieldDefinitions[fieldId];
    if (fieldDef != null && fieldDef.autoValidate) {
      _validateField(fieldId);
    }
    notifyListeners();
  }

  void setError(String fieldId, String? error) {
    if (error != null && error.isNotEmpty) {
      _errors[fieldId] = error;
    } else {
      _errors.remove(fieldId);
    }
    notifyListeners();
  }

  bool _validateField(String fieldId) {
    final fieldDef = _fieldDefinitions[fieldId];
    if (fieldDef == null) return true;
    final value = _values[fieldId];
    if (fieldDef.required) {
      if (value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty)) {
        setError(fieldId, "${fieldDef.label} es obligatorio");
        return false;
      }
    }
    if (fieldDef.validator != null && value != null) {
      final error = fieldDef.validator!(value);
      if (error != null && error.isNotEmpty) {
        setError(fieldId, error);
        return false;
      }
    }
    setError(fieldId, null);
    return true;
  }

  bool validate() {
    bool isValid = true;
    for (final fieldId in _fieldDefinitions.keys) {
      final fieldValid = _validateField(fieldId);
      if (!fieldValid) {
        isValid = false;
      }
    }
    return isValid;
  }

  bool submit() {
    return validate();
  }

  bool submitForm() {
    final isValid = validate();
    if (isValid && _onSubmitCallback != null) {
      final parsedValues = _parseFormValues();
      _onSubmitCallback!(parsedValues);
    }
    return isValid;
  }

  Map<String, dynamic> _parseFormValues() {
    final result = <String, dynamic>{};

    for (final entry in _fieldDefinitions.entries) {
      final fieldId = entry.key;
      final fieldDef = entry.value;
      final value = _values[fieldId];

      if (value != null) {
        try {
          switch (fieldDef.type) {
            case InputType.number:
              result[fieldId] = _parseNumber(value);
              break;
            case InputType.select:
              result[fieldId] = value;
              break;
            case InputType.date:
              result[fieldId] = _parseDate(value);
              break;
            case InputType.time:
              result[fieldId] = _parseTime(value);
              break;
            case InputType.datetime:
              result[fieldId] = _parseDateTime(value);
              break;
            case InputType.checkbox:
            case InputType.switch_:
              result[fieldId] = _parseBoolean(value);
              break;
            default:
              result[fieldId] = value.toString();
          }
        } catch (e) {
          result[fieldId] = value;
        }
      }
    }

    return result;
  }

  num _parseNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final normalized = value.replaceAll(',', '.');

      final intValue = int.tryParse(normalized);
      if (intValue != null) return intValue;

      final doubleValue = double.tryParse(normalized);
      if (doubleValue != null) return doubleValue;
    }
    throw FormatException('No se puede convertir "$value" a número');
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy'];
      for (final format in formats) {
        try {
          return DateFormat(format).parse(value);
        } catch (_) {}
      }

      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
    }
    throw FormatException('No se puede convertir "$value" a fecha');
  }

  DateTime _parseTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        final today = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(today);

        final timeFormats = ['HH:mm', 'HH:mm:ss', 'h:mm a'];
        for (final format in timeFormats) {
          try {
            return DateFormat('yyyy-MM-dd $format').parse('$dateStr $value');
          } catch (_) {}
        }
      } catch (_) {}
    }
    throw FormatException('No se puede convertir "$value" a hora');
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final formats = [
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd HH:mm:ss',
        'dd/MM/yyyy HH:mm',
        'MM/dd/yyyy HH:mm',
        'dd/MM/yyyy h:mm a',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(value);
        } catch (_) {}
      }

      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
    }
    throw FormatException('No se puede convertir "$value" a fecha y hora');
  }

  bool _parseBoolean(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'si' ||
          normalized == 'sí' ||
          normalized == '1' ||
          normalized == 'on' ||
          normalized == 'active';
    }
    if (value is num) {
      return value != 0;
    }
    throw FormatException('No se puede convertir "$value" a booleano');
  }

  List<String> get invalidFieldIds => _errors.keys.toList();

  void reset() {
    _values.clear();
    _errors.clear();
    for (final entry in _fieldDefinitions.entries) {
      if (entry.value.initialValue != null) {
        _values[entry.key] = entry.value.initialValue;
      }
    }
    notifyListeners();
  }

  void resetWithControllers() {
    _isResetting = true;
    _values.clear();
    _errors.clear();

    notifyListeners();

    Future.delayed(Duration(milliseconds: 50), () {
      for (final entry in _fieldDefinitions.entries) {
        if (entry.value.initialValue != null) {
          _values[entry.key] = entry.value.initialValue;
        }
      }
      _isResetting = false;
      notifyListeners();
    });
  }

  bool get isResetting => _isResetting;

  void clearErrors() {
    _errors.clear();
    notifyListeners();
  }

  void dispose() {
    _onSubmitCallback = null;
    super.dispose();
  }
}

class FormFieldDefinition {
  final String id;
  final InputType type;
  final String label;
  final String? hint;
  final dynamic initialValue;
  final String? Function(dynamic value)? validator;
  final bool required;
  final bool autoValidate;
  FormFieldDefinition({
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.required = false,
    this.autoValidate = false,
  });
}

class FormData extends InheritedNotifier<FormController> {
  const FormData({super.key, required FormController controller, required super.child})
    : super(notifier: controller);
  static FormController of(BuildContext context) {
    final FormData? form = context.dependOnInheritedWidgetOfExactType<FormData>();
    if (form == null) {
      throw FlutterError('No FormData encontrado en el contexto');
    }
    return form.notifier!;
  }
}

class FlexibleForm extends StatefulWidget {
  final FormController controller;
  final Widget child;
  final Function(FormValues values)? onSubmit;
  final bool isSubmitting;
  const FlexibleForm({
    super.key,
    required this.controller,
    required this.child,
    this.onSubmit,
    this.isSubmitting = false,
  });
  @override
  State<FlexibleForm> createState() => _FlexibleFormState();
}

class _FlexibleFormState extends State<FlexibleForm> {
  @override
  void initState() {
    super.initState();

    widget.controller.setOnSubmitCallback(widget.onSubmit);
  }

  @override
  void didUpdateWidget(FlexibleForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.onSubmit != oldWidget.onSubmit) {
      widget.controller.setOnSubmitCallback(widget.onSubmit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormData(controller: widget.controller, child: widget.child);
  }
}

class Submit extends StatelessWidget {
  final String text;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  final Widget? loadingChild;
  const Submit({super.key, this.text = 'Enviar', this.style, this.onPressed, this.loadingChild});
  @override
  Widget build(BuildContext context) {
    final form = FormData.of(context);
    final isSubmitting =
        context.findAncestorWidgetOfExactType<FlexibleForm>()?.isSubmitting ?? false;
    return ElevatedButton(
      style: style,
      onPressed:
          isSubmitting
              ? null
              : () {
                if (onPressed != null) {
                  onPressed!();
                  return;
                }

                form.submitForm();
              },
      child:
          isSubmitting
              ? loadingChild ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Procesando...'),
                    ],
                  )
              : Text(text),
    );
  }
}

class InputField extends StatelessWidget {
  final InputType type;
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool disabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final bool required;
  final String? errorText;
  final TextInputAction? textInputAction;
  final String? dateFormat;
  final Widget? prefix;
  final Widget? suffix;
  final InputDecoration? decoration;
  final Function(dynamic value)? onChanged;

  final List<DropdownMenuItem<dynamic>>? items;
  final bool? value;
  final List<FormValues>? options;

  const InputField({
    super.key,
    required this.type,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.disabled = false,
    this.readOnly = false,
    this.maxLines,
    this.maxLength,
    this.required = false,
    this.errorText,
    this.textInputAction,
    this.dateFormat,
    this.prefix,
    this.suffix,
    this.decoration,
    this.onChanged,
    this.items,
    this.value,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration =
        decoration ??
        InputDecoration(
          alignLabelWithHint: true,
          labelText: required ? "$label *" : label,
          hintText: hint,
          errorText: errorText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : prefix,
          suffixIcon:
              suffixIcon != null
                  ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixIconPressed)
                  : suffix,
        );

    switch (type) {
      case InputType.select:
        return _buildSelectField(context, baseDecoration);
      case InputType.switch_:
        return _buildSwitchField(context);
      case InputType.checkbox:
        return _buildCheckboxField(context);
      case InputType.radio:
        return _buildRadioField(context);
      case InputType.date:
        return _buildDateField(context, baseDecoration);
      case InputType.time:
        return _buildTimeField(context, baseDecoration);
      case InputType.datetime:
        return _buildDateTimeField(context, baseDecoration);
      case InputType.rrule:
        return _buildRRuleField(context, baseDecoration);
      default:
        return _buildTextField(context, baseDecoration);
    }
  }

  Widget _buildTextField(BuildContext context, InputDecoration decoration) {
    return TextField(
      controller: controller,
      decoration: decoration,
      obscureText: type == InputType.password,
      keyboardType: _getKeyboardType(),
      maxLines: type == InputType.password ? 1 : maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: !disabled,
      textInputAction: textInputAction,
      onChanged: (value) {
        if (onChanged != null) onChanged!(value);
      },
    );
  }

  Widget _buildSelectField(BuildContext context, InputDecoration decoration) {
    if (items == null || items!.isEmpty) {
      return const SizedBox.shrink();
    }

    dynamic currentValue;

    if (controller?.text.isNotEmpty == true) {
      final controllerText = controller!.text;

      for (var item in items!) {
        if (item.value.toString() == controllerText) {
          currentValue = item.value;
          break;
        }
      }

      currentValue ??= _parseControllerValue(controllerText);
    }

    return FormField<dynamic>(
      initialValue: currentValue,
      validator: (_) => errorText,
      builder: (state) {
        return InputDecorator(
          decoration: decoration.copyWith(errorText: state.errorText),
          isEmpty: controller?.text.isEmpty ?? true,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: currentValue,
              isDense: true,
              isExpanded: true,
              hint: Text(hint ?? ''),
              onChanged:
                  disabled || readOnly
                      ? null
                      : (newValue) {
                        if (newValue != null) {
                          controller?.text = newValue.toString();

                          if (onChanged != null) onChanged!(newValue);
                          state.didChange(newValue);
                        }
                      },
              items: items,
            ),
          ),
        );
      },
    );
  }

  dynamic _parseControllerValue(String text) {
    final intValue = int.tryParse(text);
    if (intValue != null) return intValue;

    final doubleValue = double.tryParse(text);
    if (doubleValue != null) return doubleValue;

    return text;
  }

  Widget _buildSwitchField(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(required ? "$label *" : label), if (hint != null) Text(hint!)],
          ),
        ),
        Switch(
          value: value ?? false,
          onChanged:
              disabled
                  ? null
                  : (newValue) {
                    if (onChanged != null) onChanged!(newValue);
                  },
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(errorText!, style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildCheckboxField(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value ?? false,
          onChanged:
              disabled
                  ? null
                  : (newValue) {
                    if (onChanged != null && newValue != null) onChanged!(newValue);
                  },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(required ? "$label *" : label), if (hint != null) Text(hint!)],
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(errorText!, style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildRadioField(BuildContext context) {
    if (options == null || options!.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentValue = controller?.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(required ? "$label *" : label),
        if (hint != null) Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(hint!)),
        ...options!.map((option) {
          final optionValue = option['value'];
          final optionLabel = option['label'] as String;

          return RadioListTile<dynamic>(
            title: Text(optionLabel),
            value: optionValue,
            groupValue: currentValue,
            onChanged:
                disabled
                    ? null
                    : (newValue) {
                      if (newValue != null) {
                        controller?.text = newValue.toString();
                        if (onChanged != null) onChanged!(newValue);
                      }
                    },
            dense: true,
          );
        }),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(errorText!, style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, InputDecoration decoration) {
    return TextField(
      controller: controller,
      decoration: decoration.copyWith(suffixIcon: const Icon(LucideIcons.calendarMinus2)),
      readOnly: true,
      enabled: !disabled,
      onTap:
          disabled || readOnly
              ? null
              : () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  locale: const Locale('es', 'ES'),
                  initialDatePickerMode: DatePickerMode.day,
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  final String formattedDate = _formatDate(pickedDate, dateFormat);
                  controller?.text = formattedDate;
                  if (onChanged != null) onChanged!(pickedDate);
                }
              },
    );
  }

  Widget _buildTimeField(BuildContext context, InputDecoration decoration) {
    return TextField(
      controller: controller,
      decoration: decoration.copyWith(suffixIcon: const Icon(LucideIcons.timer)),
      readOnly: true,
      enabled: !disabled,
      onTap:
          disabled || readOnly
              ? null
              : () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null) {
                  final String formattedTime = _formatTime(pickedTime);
                  controller?.text = formattedTime;
                  if (onChanged != null) onChanged!(formattedTime);
                }
              },
    );
  }

  Widget _buildDateTimeField(BuildContext context, InputDecoration decoration) {
    return TextField(
      controller: controller,
      decoration: decoration.copyWith(suffixIcon: const Icon(LucideIcons.calendarClock)),
      readOnly: true,
      enabled: !disabled,
      onTap:
          disabled || readOnly
              ? null
              : () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  locale: const Locale('es', 'ES'),
                  initialDatePickerMode: DatePickerMode.day,
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null && context.mounted) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialEntryMode: TimePickerEntryMode.input,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    final dateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );

                    final String formattedDateTime = _formatDateTime(dateTime, dateFormat);
                    controller?.text = formattedDateTime;
                    if (onChanged != null) onChanged!(dateTime);
                  }
                }
              },
    );
  }

  Widget _buildRRuleField(BuildContext context, InputDecoration decoration) {
    return RRuleField(
      label: label,
      hint: hint,
      value: controller?.text.isNotEmpty == true ? RRuleValue.fromString(controller!.text) : null,
      disabled: disabled,
      readOnly: readOnly,
      required: required,
      errorText: errorText,
      onChanged: (value) {
        final rruleString = value.toString();
        controller?.text = rruleString;
        if (onChanged != null) {
          onChanged!(rruleString);
        }
      },
    );
  }

  String _formatDate(DateTime date, String? format) {
    return DateTimeFmt.date(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDateTime(DateTime dateTime, String? format) {
    return DateFormat(format ?? 'dd/MM/yyyy HH:mm', 'es_ES').format(dateTime);
  }

  TextInputType _getKeyboardType() {
    switch (type) {
      case InputType.email:
        return TextInputType.emailAddress;
      case InputType.number:
        return TextInputType.number;
      case InputType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }
}

class Field extends StatefulWidget {
  final String id;
  final InputType type;
  final String label;
  final String? hint;
  final dynamic initialValue;
  final String? Function(dynamic value)? validator;
  final bool required;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool disabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final String? dateFormat;
  final bool autoValidate;
  final Widget? prefix;
  final Widget? suffix;
  final InputDecoration? decoration;
  final Function(dynamic value)? onChanged;

  final List<DropdownMenuItem<dynamic>>? items;
  final List<Map<String, dynamic>>? options;

  const Field({
    super.key,
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.required = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.disabled = false,
    this.readOnly = false,
    this.maxLines,
    this.maxLength,
    this.textInputAction,
    this.dateFormat,
    this.autoValidate = false,
    this.prefix,
    this.suffix,
    this.decoration,
    this.onChanged,
    this.items,
    this.options,
  });
  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late TextEditingController _controller;
  FormController? _formController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerField();
      if (widget.initialValue != null) {
        _setControllerValue(widget.initialValue);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final formData = context.dependOnInheritedWidgetOfExactType<FormData>();
      _formController = formData?.notifier;
    } catch (e) {
      throw FlutterError('Error accessing FormData: $e');
    }
  }

  void _registerField() {
    try {
      if (_formController == null) {
        final formData = context.dependOnInheritedWidgetOfExactType<FormData>();
        _formController = formData?.notifier;
      }

      if (_formController != null) {
        _formController!.registerField(
          FormFieldDefinition(
            id: widget.id,
            type: widget.type,
            label: widget.label,
            hint: widget.hint,
            initialValue: widget.initialValue,
            validator: widget.validator,
            required: widget.required,
            autoValidate: widget.autoValidate,
          ),
        );
      }
    } catch (e) {
      throw FlutterError('Error registering field: $e');
    }
  }

  @override
  void didUpdateWidget(Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id ||
        widget.type != oldWidget.type ||
        widget.label != oldWidget.label ||
        widget.hint != oldWidget.hint ||
        widget.initialValue != oldWidget.initialValue ||
        widget.validator != oldWidget.validator ||
        widget.required != oldWidget.required ||
        widget.autoValidate != oldWidget.autoValidate) {
      _registerField();
    }
  }

  void _setControllerValue(dynamic value) {
    if (value == null) {
      _controller.text = '';
      return;
    }
    if (value is DateTime) {
      _controller.text = DateTimeFmt.full(value);
    } else if (value is TimeOfDay) {
      _controller.text = DateFormat('HH:mm').format(DateTime(0, 0, 0, value.hour, value.minute));
    } else if (value is String) {
      _controller.text = value;
    } else {
      _controller.text = value.toString();
    }
  }

  @override
  void dispose() {
    if (_formController != null) {
      try {
        _formController!.unregisterField(widget.id);
      } catch (e) {
        throw FlutterError('Error unregistering field: $e');
      }
    }

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late FormController form;
    dynamic value;
    String? error;

    try {
      form = FormData.of(context);
      value = form.getValue(widget.id);
      error = form.getError(widget.id);

      _formController ??= form;

      if (form.isResetting &&
          widget.type != InputType.checkbox &&
          widget.type != InputType.switch_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.clear();
          }
        });
      } else if (value == null &&
          _controller.text.isNotEmpty &&
          widget.type != InputType.checkbox &&
          widget.type != InputType.switch_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.clear();
          }
        });
      } else if ((widget.type == InputType.checkbox || widget.type == InputType.switch_) &&
          (value == null || form.isResetting) &&
          widget.initialValue == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      value = null;
      error = null;
    }

    if (value != null && widget.type != InputType.checkbox && widget.type != InputType.switch_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.type == InputType.select) {
          if (_controller.text != value.toString()) {
            _controller.text = value.toString();
          }
        } else {
          final currentTextValue = _controller.text;
          final newTextValue = value.toString();
          if (currentTextValue != newTextValue) {
            _setControllerValue(value);
          }
        }
      });
    }

    return InputField(
      type: widget.type,
      label: widget.label,
      hint: widget.hint,
      controller: _controller,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      onSuffixIconPressed: widget.onSuffixIconPressed,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      required: widget.required,
      errorText: error,
      textInputAction: widget.textInputAction,
      dateFormat: widget.dateFormat,
      prefix: widget.prefix,
      suffix: widget.suffix,
      decoration: widget.decoration,

      value:
          (widget.type == InputType.checkbox || widget.type == InputType.switch_)
              ? value as bool? ?? false
              : null,

      items: widget.items,
      options: widget.options,
      onChanged: (newValue) {
        try {
          if (_formController != null) {
            _formController!.setValue(widget.id, newValue);
          }
          if (widget.onChanged != null) {
            widget.onChanged!(newValue);
          }
        } catch (e) {
          throw FlutterError('Error setting value: $e');
        }
      },
    );
  }
}

class RRuleFrequency {
  final String value;
  final String label;

  const RRuleFrequency(this.value, this.label);

  static const daily = RRuleFrequency('DAILY', 'Diario');
  static const weekly = RRuleFrequency('WEEKLY', 'Semanal');
  static const monthly = RRuleFrequency('MONTHLY', 'Mensual');
  static const yearly = RRuleFrequency('YEARLY', 'Anual');

  static const List<RRuleFrequency> values = [daily, weekly, monthly, yearly];
}

class WeekDay {
  final String value;
  final String label;
  final int index;

  const WeekDay(this.value, this.label, this.index);

  static const monday = WeekDay('MO', 'Lunes', 0);
  static const tuesday = WeekDay('TU', 'Martes', 1);
  static const wednesday = WeekDay('WE', 'Miércoles', 2);
  static const thursday = WeekDay('TH', 'Jueves', 3);
  static const friday = WeekDay('FR', 'Viernes', 4);
  static const saturday = WeekDay('SA', 'Sábado', 5);
  static const sunday = WeekDay('SU', 'Domingo', 6);

  static const List<WeekDay> values = [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  static WeekDay? fromValue(String value) {
    return values.firstWhere((weekDay) => weekDay.value == value, orElse: () => monday);
  }
}

class RRuleValue {
  RRuleFrequency frequency;
  int interval;
  DateTime? until;
  int? count;
  List<WeekDay> byDays;
  int? byMonthDay;
  List<int> byMonths;

  RRuleValue({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byDays = const [],
    this.byMonthDay,
    this.byMonths = const [],
  });

  factory RRuleValue.fromString(String rruleStr) {
    final result = RRuleValue(frequency: RRuleFrequency.daily);

    if (rruleStr.isEmpty) return result;

    final normalizedStr = rruleStr.startsWith('RRULE:') ? rruleStr.substring(6) : rruleStr;

    final parts = normalizedStr.split(';');

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length != 2) continue;

      final key = keyValue[0];
      final value = keyValue[1];

      switch (key) {
        case 'FREQ':
          result.frequency = RRuleFrequency.values.firstWhere(
            (f) => f.value == value,
            orElse: () => RRuleFrequency.daily,
          );
          break;

        case 'INTERVAL':
          result.interval = int.tryParse(value) ?? 1;
          break;

        case 'UNTIL':
          try {
            if (value.length >= 8) {
              final year = int.parse(value.substring(0, 4));
              final month = int.parse(value.substring(4, 6));
              final day = int.parse(value.substring(6, 8));

              DateTime dateTime = DateTime(year, month, day);

              if (value.length > 8 && value.contains('T')) {
                final timePart = value.substring(value.indexOf('T') + 1);
                if (timePart.length >= 6) {
                  final hour = int.parse(timePart.substring(0, 2));
                  final minute = int.parse(timePart.substring(2, 4));
                  final second = int.parse(timePart.substring(4, 6));

                  dateTime = DateTime(year, month, day, hour, minute, second);
                }
              }

              result.until = dateTime;
            }
          } catch (e) {}
          break;

        case 'COUNT':
          result.count = int.tryParse(value);
          break;

        case 'BYDAY':
          final dayStrings = value.split(',');
          result.byDays =
              dayStrings.map((dayStr) => WeekDay.fromValue(dayStr)).whereType<WeekDay>().toList();
          break;

        case 'BYMONTHDAY':
          result.byMonthDay = int.tryParse(value);
          break;

        case 'BYMONTH':
          try {
            result.byMonths =
                value.split(',').map((m) => int.tryParse(m)).whereType<int>().toList();
          } catch (e) {}
          break;
      }
    }

    return result;
  }

  @override
  String toString() {
    final parts = <String>[];

    parts.add('FREQ=${frequency.value}');

    if (interval != 1) {
      parts.add('INTERVAL=$interval');
    }

    if (until != null) {
      final year = until!.year.toString().padLeft(4, '0');
      final month = until!.month.toString().padLeft(2, '0');
      final day = until!.day.toString().padLeft(2, '0');
      final hour = until!.hour.toString().padLeft(2, '0');
      final minute = until!.minute.toString().padLeft(2, '0');
      final second = until!.second.toString().padLeft(2, '0');

      parts.add('UNTIL=$year$month${day}T$hour$minute${second}Z');
    }

    if (count != null) {
      parts.add('COUNT=$count');
    }

    if (byDays.isNotEmpty) {
      final dayValues = byDays.map((day) => day.value).join(',');
      parts.add('BYDAY=$dayValues');
    }

    if (byMonthDay != null) {
      parts.add('BYMONTHDAY=$byMonthDay');
    }

    if (byMonths.isNotEmpty) {
      final monthValues = byMonths.join(',');
      parts.add('BYMONTH=$monthValues');
    }

    return parts.join(';');
  }

  RRuleValue copyWith({
    RRuleFrequency? frequency,
    int? interval,
    DateTime? until,
    int? count,
    List<WeekDay>? byDays,
    int? byMonthDay,
    List<int>? byMonths,
    bool clearUntil = false,
    bool clearCount = false,
    bool clearByDays = false,
    bool clearByMonthDay = false,
    bool clearByMonths = false,
  }) {
    return RRuleValue(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      until: clearUntil ? null : until ?? this.until,
      count: clearCount ? null : count ?? this.count,
      byDays: clearByDays ? [] : byDays ?? List.from(this.byDays),
      byMonthDay: clearByMonthDay ? null : byMonthDay ?? this.byMonthDay,
      byMonths: clearByMonths ? [] : byMonths ?? List.from(this.byMonths),
    );
  }
}

class RRuleField extends StatefulWidget {
  final String label;
  final String? hint;
  final RRuleValue? value;
  final bool disabled;
  final bool readOnly;
  final bool required;
  final String? errorText;
  final Function(RRuleValue value)? onChanged;

  const RRuleField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    this.disabled = false,
    this.readOnly = false,
    this.required = false,
    this.errorText,
    this.onChanged,
  });

  @override
  State<RRuleField> createState() => _RRuleFieldState();
}

class _RRuleFieldState extends State<RRuleField> {
  late RRuleValue _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value ?? RRuleValue(frequency: RRuleFrequency.daily);
  }

  @override
  void didUpdateWidget(RRuleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value.toString() != _currentValue.toString()) {
      _currentValue = widget.value!;
    }
  }

  void _openDialog() async {
    final updated = await showDialog<RRuleValue>(
      useSafeArea: true,
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Frecuencia'),
            scrollable: true,
            insetPadding: const EdgeInsets.all(0),
            content: StatefulBuilder(
              builder: (context, setModalState) {
                void update(RRuleValue newVal) {
                  setModalState(() => _currentValue = newVal);
                }

                return SingleChildScrollView(
                  child: Col(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<RRuleFrequency>(
                        enableFeedback: true,
                        decoration: InputDecoration(labelText: 'Frecuencia'),
                        value: _currentValue.frequency,
                        items:
                            RRuleFrequency.values.map((frequency) {
                              return DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency.label),
                              );
                            }).toList(),
                        onChanged: (newFrequency) {
                          if (newFrequency != null) {
                            update(
                              _currentValue.copyWith(
                                frequency: newFrequency,
                                clearByDays: newFrequency.value != 'WEEKLY',
                                clearByMonthDay: newFrequency.value != 'MONTHLY',
                                clearByMonths: newFrequency.value != 'YEARLY',
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text('Repetir cada:')),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _currentValue.interval.toString(),
                              ),
                              onChanged: (value) {
                                final interval = int.tryParse(value) ?? 1;
                                if (interval > 0) {
                                  update(_currentValue.copyWith(interval: interval));
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text(_getIntervalUnitLabel(_currentValue.frequency))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_currentValue.frequency.value == 'WEEKLY')
                        _buildHorizontalWeekdayCheckboxes(update),
                      if (_currentValue.frequency.value == 'MONTHLY')
                        _buildMonthDaySelector(update),
                      if (_currentValue.frequency.value == 'YEARLY') _buildMonthSelector(update),
                      const SizedBox(height: 16),
                      _buildEndRuleSelector(update),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _currentValue),
                child: Text('Guardar'),
              ),
            ],
          ),
    );

    if (updated != null) {
      setState(() {
        _currentValue = updated;
      });
      widget.onChanged?.call(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (widget.disabled || widget.readOnly) ? null : _openDialog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.required ? "${widget.label} *" : widget.label),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: _getSummary()),
            readOnly: true,
            enabled: false,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: Icon(Icons.edit_calendar),
            ),
          ),
          if (widget.errorText != null && widget.errorText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(widget.errorText!, style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  String _getIntervalUnitLabel(RRuleFrequency frequency) {
    switch (frequency.value) {
      case 'DAILY':
        return 'día(s)';
      case 'WEEKLY':
        return 'semana(s)';
      case 'MONTHLY':
        return 'mes(es)';
      case 'YEARLY':
        return 'año(s)';
      default:
        return '';
    }
  }

  Widget _buildHorizontalWeekdayCheckboxes(void Function(RRuleValue) update) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repetir en los días:'),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  WeekDay.values.map((day) {
                    final selected = _currentValue.byDays.any((d) => d.value == day.value);
                    final letter = day.label.characters.first.toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          final updatedDays = List<WeekDay>.from(_currentValue.byDays);
                          if (selected) {
                            updatedDays.removeWhere((d) => d.value == day.value);
                          } else {
                            updatedDays.add(day);
                          }
                          update(_currentValue.copyWith(byDays: updatedDays));
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? Colors.blue : Colors.transparent,
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDaySelector(void Function(RRuleValue) update) {
    return DropdownButtonFormField<int>(
      value: _currentValue.byMonthDay,
      decoration: InputDecoration(labelText: 'Día del mes'),
      items:
          List.generate(31, (index) => index + 1).map((day) {
            return DropdownMenuItem<int>(value: day, child: Text(day.toString()));
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          update(_currentValue.copyWith(byMonthDay: value));
        }
      },
    );
  }

  Widget _buildMonthSelector(void Function(RRuleValue) update) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meses:'),
        const SizedBox(height: 8),
        SizedBox(
          // height: 48,
          child: Wrap(
            spacing: 1,
            runSpacing: 6,
            // scrollDirection: Axis.horizontal,
            // child: Row(
            children:
                List.generate(12, (index) {
                  final month = index + 1;
                  final selected = _currentValue.byMonths.contains(month);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        final updatedMonths = List<int>.from(_currentValue.byMonths);
                        if (selected) {
                          updatedMonths.remove(month);
                        } else {
                          updatedMonths.add(month);
                        }
                        update(_currentValue.copyWith(byMonths: updatedMonths));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue : Colors.transparent,
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          // ),
        ),
      ],
    );
  }

  Widget _buildEndRuleSelector(void Function(RRuleValue) update) {
    final hasCount = _currentValue.count != null;
    final hasUntil = _currentValue.until != null;
    String selected = hasCount ? 'count' : (hasUntil ? 'until' : 'never');

    return Col(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Termina:'),
        RadioListTile(
          value: 'never',
          groupValue: selected,
          onChanged: (val) => update(_currentValue.copyWith(clearCount: true, clearUntil: true)),
          title: Text('Nunca', style: AppTheme.smallContentStyle),
        ),
        RadioListTile(
          value: 'count',
          groupValue: selected,
          onChanged: (val) => update(_currentValue.copyWith(count: 1, clearUntil: true)),
          title: Row(
            children: [
              Text('Después de ', style: AppTheme.smallContentStyle),
              SizedBox(
                width: 50,
                child: TextField(
                  enabled: selected == 'count',
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _currentValue.count?.toString() ?? '1'),
                  onChanged: (val) {
                    final count = int.tryParse(val);
                    if (count != null && count > 0) {
                      update(_currentValue.copyWith(count: count, clearUntil: true));
                    }
                  },
                ),
              ),
              Text(' veces', style: AppTheme.smallContentStyle),
            ],
          ),
        ),
        RadioListTile(
          value: 'until',
          groupValue: selected,
          onChanged: (val) {
            final futureDate = DateTime.now().add(Duration(days: 30));
            update(_currentValue.copyWith(until: futureDate, clearCount: true));
          },
          title: Row(
            children: [
              Text('Hasta ', style: AppTheme.smallContentStyle),
              InkWell(
                onTap: selected == 'until' ? () => _selectUntilDate(update) : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _currentValue.until != null
                        ? DateTimeFmt.date(_currentValue.until!)
                        : 'Seleccionar fecha',
                    style: AppTheme.smallContentStyle.copyWith(
                      color: selected == 'until' ? Colors.blue : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectUntilDate(void Function(RRuleValue) update) async {
    final initialDate = _currentValue.until ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      update(_currentValue.copyWith(until: picked, clearCount: true));
    }
  }

  String _getSummary() {
    final freq = _currentValue.frequency.value;
    final interval = _currentValue.interval;
    String summary = '';

    switch (freq) {
      case 'DAILY':
        summary = interval == 1 ? 'Diariamente' : 'Cada $interval días';
        break;
      case 'WEEKLY':
        final days = _currentValue.byDays.map((d) => d.label).join(', ');
        summary =
            interval == 1
                ? 'Semanalmente${days.isNotEmpty ? ' los días: $days' : ''}'
                : 'Cada $interval semanas${days.isNotEmpty ? ' los días: $days' : ''}';
        break;
      case 'MONTHLY':
        if (_currentValue.byMonthDay != null) {
          summary =
              interval == 1
                  ? 'Mensualmente el día ${_currentValue.byMonthDay}'
                  : 'Cada $interval meses el día ${_currentValue.byMonthDay}';
        } else {
          final days = _currentValue.byDays.map((d) => d.label).join(', ');
          summary =
              interval == 1
                  ? 'Mensualmente${days.isNotEmpty ? ' los días: $days' : ''}'
                  : 'Cada $interval meses${days.isNotEmpty ? ' los días: $days' : ''}';
        }
        break;
      case 'YEARLY':
        final months = _currentValue.byMonths
            .map((m) {
              return DateFormat.MMMM('es').format(DateTime(0, m));
            })
            .join(', ');
        summary =
            interval == 1
                ? 'Anualmente${months.isNotEmpty ? ' en: $months' : ''}'
                : 'Cada $interval años${months.isNotEmpty ? ' en: $months' : ''}';
        break;
      default:
        summary = 'Personalizado';
    }

    if (_currentValue.count != null) {
      summary += ', ${_currentValue.count} veces';
    } else if (_currentValue.until != null) {
      summary += ', hasta ${DateTimeFmt.date(_currentValue.until!)}';
    }

    return summary;
  }
}
