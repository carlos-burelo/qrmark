import 'package:flutter/material.dart';
import 'package:qrmark/core/config/theme.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/distribution_list.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/core/widgets/user_card.dart';

class OrganizerManageMembers extends StatefulWidget {
  static const String path = '/organizer/distribution_list/members/manage_members';
  final int listId;
  const OrganizerManageMembers({super.key, required this.listId});
  @override
  State<OrganizerManageMembers> createState() => _OrganizerManageMembersState();
}

class _OrganizerManageMembersState extends State<OrganizerManageMembers> {
  List<User> allUsers = [];
  Map<int, bool> originalMembershipStatus = {};
  Map<int, bool> currentSelectionStatus = {};
  void toggleMemberSelection(User user) {
    setState(() {
      currentSelectionStatus[user.id] = !(currentSelectionStatus[user.id] ?? false);
    });
  }

  Future<List<User>> getUsers() async {
    final membersInList = await service.distributionList.getListMembers(widget.listId);
    final allUsers = await service.user.getAllUsers(UserRole.user);
    setState(() {
      this.allUsers = allUsers;
      for (var user in allUsers) {
        bool isMember = membersInList.any((member) => member.id == user.id);
        originalMembershipStatus[user.id] = isMember;
        currentSelectionStatus[user.id] = isMember;
      }
    });
    return allUsers;
  }

  List<User> _getUsersToAdd() {
    return allUsers
        .where(
          (user) =>
              (currentSelectionStatus[user.id] ?? false) == true &&
              (originalMembershipStatus[user.id] ?? false) == false,
        )
        .toList();
  }

  List<User> _getUsersToRemove() {
    return allUsers
        .where(
          (user) =>
              (currentSelectionStatus[user.id] ?? false) == false &&
              (originalMembershipStatus[user.id] ?? false) == true,
        )
        .toList();
  }

  Future<bool> _confirmChanges() async {
    final usersToAdd = _getUsersToAdd();
    final usersToRemove = _getUsersToRemove();
    if (usersToAdd.isEmpty && usersToRemove.isEmpty) {
      Sonner.warning('No has realizado cambios');
      return false;
    }
    if (usersToRemove.isEmpty) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmar cambios'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (usersToAdd.isNotEmpty)
                      Text('Se añadirán ${usersToAdd.length} miembros a la lista.'),
                    if (usersToRemove.isNotEmpty)
                      Text('Se eliminarán ${usersToRemove.length} miembros de la lista.'),
                    const SizedBox(height: 16),
                    const Text('¿Deseas continuar?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _saveChanges() async {
    final shouldProceed = await _confirmChanges();
    if (!shouldProceed) return;
    final usersToAdd = _getUsersToAdd();
    final usersToRemove = _getUsersToRemove();
    bool success = true;
    if (usersToAdd.isNotEmpty) {
      final addResult = await service.distributionList.addMultipleMembersToList(
        widget.listId,
        usersToAdd.map((e) => e.id).toList(),
      );
      if (!addResult) {
        success = false;
        Sonner.error('Error al añadir miembros');
      }
    }
    if (usersToRemove.isNotEmpty && success) {
      final removeResult = await service.distributionList.removeMultipleMembersFromList(
        widget.listId,
        usersToRemove.map((e) => e.id).toList(),
      );
      if (!removeResult) {
        success = false;
        Sonner.error('Error al eliminar miembros');
      }
    }
    if (success) {
      Sonner.success('Miembros actualizados correctamente');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalToAdd = _getUsersToAdd().length;
    final totalToRemove = _getUsersToRemove().length;
    return Body(
      appBar: AppBar(title: const Text('Gestionar miembros')),
      body: SearchableAsyncList(
        enablePullToRefresh: true,
        enableSearch: true,
        wait: getUsers,
        emptyBuilder: const Center(child: Text('No hay usuarios disponibles')),
        builder: (context, user, i) {
          final isSelected = currentSelectionStatus[user.id] ?? false;
          return UserCard(
            user: user,
            trailingWidget: UserCardActions.checkbox(
              value: isSelected,
              onChanged: (_) {
                toggleMemberSelection(user);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getUsersToRemove().isNotEmpty ? AppColors.warningColor : null,
          ),
          child: Text(_buildButtonText(totalToAdd, totalToRemove)),
        ),
      ),
    );
  }

  String _buildButtonText(int toAdd, int toRemove) {
    if (toAdd == 0 && toRemove == 0) {
      return 'Sin cambios';
    }
    final List<String> actions = [];
    if (toAdd > 0) {
      actions.add('añadir $toAdd');
    }
    if (toRemove > 0) {
      actions.add('eliminar $toRemove');
    }
    return 'Guardar cambios (${actions.join(', ')})';
  }
}

extension DistributionListServiceExtension on DistributionListService {
  Future<bool> removeMultipleMembersFromList(int listId, List<int> userIds) async {
    try {
      for (final userId in userIds) {
        await removeMemberFromList(listId, userId);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMemberFromList(int listId, int userId) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}
