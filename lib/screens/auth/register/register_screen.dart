import 'package:flutter/material.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/utils/validators.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/form.dart';
// import 'package:qrmark/core/widgets/input.dart';
import 'package:qrmark/core/widgets/link.dart';
import 'package:qrmark/core/widgets/logo.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/auth/login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String path = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formController = FormController();
  bool _isSubmitting = false;

  Future<void> _handleSubmit(FormValues values) async {
    if (values['password'] != values['confirm_password']) {
      Sonner.error('Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await service.auth.register(
        email: values['email'],
        fullName: values['name'],
        password: values['password'],
      );

      if (success) {
        Sonner.success('¡Registro exitoso! Bienvenido a QRMark');
        _resetForm();

        Navigate.to(LoginScreen.path);
      }
    } catch (e) {
      Sonner.error('Error durante el registro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formController.reset();
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
      body: FlexibleForm(
        controller: _formController,
        onSubmit: _handleSubmit,
        isSubmitting: _isSubmitting,
        child: Col(
          gap: 24,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            AppLogo(),
            Field(
              id: 'name',
              type: InputType.text,
              label: 'Ingrese su nombre completo',
              hint: 'Nombre completo',
              required: true,
              prefixIcon: Icons.person_outline,
              autoValidate: true,
              validator: Validators.name,
            ),
            Field(
              id: 'email',
              type: InputType.email,
              label: 'Ingrese su correo electrónico',
              hint: 'Correo electrónico',
              required: true,
              prefixIcon: Icons.email_outlined,
              autoValidate: true,
              validator: Validators.email,
            ),
            Field(
              id: 'password',
              type: InputType.password,
              label: 'Ingrese su contraseña',
              hint: 'Contraseña',
              required: true,
              prefixIcon: Icons.lock_outline,
              autoValidate: true,
              validator: Validators.password,
            ),
            Field(
              id: 'confirm_password',
              type: InputType.password,
              label: 'Confirme su contraseña',
              hint: 'Confirmar contraseña',
              required: true,
              prefixIcon: Icons.lock_outline,
              autoValidate: true,
              validator: Validators.password,
            ),
            Submit(text: _isSubmitting ? 'Registrando...' : 'Registrarse 🚀'),
            Link(
              text: 'Ya tienes una cuenta? Inicia sesión aquí',
              onTap: () => Navigate.to(LoginScreen.path),
            ),
          ],
        ),
      ),
    );
  }
}
