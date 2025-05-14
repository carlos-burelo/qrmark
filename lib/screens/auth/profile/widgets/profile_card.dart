import 'package:flutter/material.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/widgets/column.dart';

class ProfileCard extends StatelessWidget {
  final User user;
  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Col(
        gap: 10,
        children: [
          ListTile(
            title: const Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.fullName, style: const TextStyle(fontSize: 18)),
          ),
          ListTile(
            title: const Text('Correo', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
          ),
          ListTile(
            title: const Text('Fecha de registro', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.joinDate),
          ),
          ListTile(
            title: const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.role.displayName),
          ),
        ],
      ),
    );
  }
}
