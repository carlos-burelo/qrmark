import 'package:flutter/material.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/form.dart';
import 'package:qrmark/core/widgets/link.dart';
import 'package:qrmark/core/widgets/logo.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/screens/auth/register/register_screen.dart';
import 'package:qrmark/screens/router.dart';

class LoginScreen extends StatefulWidget {
  static const String path = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formController = FormController();

  bool _isSubmitting = false;

  Future<void> _handleSubmit(FormValues values) async {
    setState(() {
      _isSubmitting = false;
    });

    try {
      final isValid = await service.auth.login(
        email: values['email'],
        password: values['password'],
      );

      final role = await service.auth.getCurrentUserRole();

      if (isValid) {
        Sonner.success('Formulario enviado correctamente');
        _resetForm();
        Navigate.replace(AppRouter.getRouter(role!));
      } else {
        Sonner.error('Error: Credenciales inválidas');
      }
    } catch (e) {
      Sonner.error(e.toString());
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
              id: 'email',
              type: InputType.email,
              label: 'Ingrese su correo electrónico',
              hint: 'Correo electrónico',
              required: true,
              prefixIcon: Icons.email_outlined,
            ),
            Field(
              id: 'password',
              type: InputType.password,
              label: 'Ingrese su contraseña',
              hint: 'Contraseña',
              required: true,
              prefixIcon: Icons.lock_outline,
            ),
            Submit(text: 'Iniciar sesión'),
            Link(
              text: 'No tienes una cuenta? Regístrate aquí',
              onTap: () => Navigate.to(RegisterScreen.path),
            ),
          ],
        ),
      ),
    );
  }
}
