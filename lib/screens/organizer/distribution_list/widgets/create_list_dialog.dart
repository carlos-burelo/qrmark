import 'package:flutter/material.dart';

class CreateListDialog extends StatefulWidget {
  @override
  CreateListDialogState createState() => CreateListDialogState();

  const CreateListDialog({super.key});
}

class CreateListDialogState extends State<CreateListDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      title: const Text('Crear lista de difusión'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ingrese un nombre para la lista',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un nombre';
                }
                if (value.length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Descripción (opcional)',
                hintText: 'Ingrese una descripción para la lista',
              ),
              maxLines: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nombreController.text,
                'description':
                    _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
              });
            }
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
