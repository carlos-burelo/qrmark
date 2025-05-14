import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/form.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';

class OrganizerEventCreateScreen extends StatefulWidget {
  static final String path = '/organizer/events/create';

  const OrganizerEventCreateScreen({super.key});

  @override
  State<OrganizerEventCreateScreen> createState() => OrganizerEventCreateScreenState();
}

class OrganizerEventCreateScreenState extends State<OrganizerEventCreateScreen> {
  final _formController = FormController();
  bool _isSubmitting = false;
  bool _isRecurring = false;

  Future<void> _handleSubmit(FormValues values) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await service.event.createEvent(
        title: values['event_name'] as String,
        description: values['content'] as String,
        capacity: values['capacity'] as int,
        isRecurring: _isRecurring,
        startTime: values['start_date'] as DateTime,
        endTime: values['end_date'] as DateTime,
        locationId: values['location'] as int,
        requiresCheckout: values['require_checkout'],
        recurrencePattern: _isRecurring ? values['recurrence_pattern'] : null,
      );
      Sonner.success('Evento creado con éxito');
      _resetForm();
      Navigate.back(true);
    } catch (e) {
      Sonner.error('Error al crear el evento: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formController.resetWithControllers();
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      scrollable: true,
      appBar: AppBarWidget(title: 'Crear evento'),
      body: FlexibleForm(
        isSubmitting: _isSubmitting,
        controller: _formController,
        onSubmit: _handleSubmit,
        child: Col(
          children: [
            Field(
              id: 'event_name',
              label: 'Nombre del evento',
              type: InputType.text,
              required: true,
            ),
            Field(id: 'content', type: InputType.text, maxLines: 5, label: 'Contenido'),
            Row(
              children: [
                Expanded(
                  child: Field(
                    id: 'start_date',
                    label: 'Fecha de inicio',
                    type: InputType.datetime,
                    required: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    id: 'end_date',
                    label: 'Fecha de fin',
                    type: InputType.datetime,
                    required: true,
                  ),
                ),
              ],
            ),
            Field(
              id: 'location',
              label: 'Ubicacion',
              type: InputType.select,
              required: true,
              items: [
                DropdownMenuItem(value: 1, child: Text('Centro de convenciones')),
                DropdownMenuItem(value: 2, child: Text('Auditorio')),
                DropdownMenuItem(value: 3, child: Text('Otro lugar')),
              ],
            ),
            Field(id: 'capacity', label: 'Capacidad', type: InputType.number, required: true),
            Field(
              id: 'require_checkout',
              label: 'Requiere checkout',
              type: InputType.switch_,
              initialValue: false,
              required: false,
            ),
            Field(
              id: 'is_recurring',
              label: 'Es recurrente',
              type: InputType.switch_,
              initialValue: false,
              required: false,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring)
              Field(
                id: 'recurrenceRule',
                type: InputType.rrule,
                label: 'Repetición',
                hint: 'Define la regla de repetición',
                required: true,
              ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : () => _formController.submitForm(),
          icon: Icon(LucideIcons.plus),
          label: Text('Crear evento'),
        ),
      ),
    );
  }
}
