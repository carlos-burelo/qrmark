import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/column.dart';
import 'package:qrmark/core/widgets/confirm.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/core/widgets/user_card.dart';
import 'package:qrmark/screens/organizer/moderators/widgets/role_tabs.dart';

class OrganizerModeratorsTab extends ScreenWithState {
  final IconData icon = LucideIcons.shield;
  final String label = 'Moderadores';
  final String path = '/organizer/moderators';

  const OrganizerModeratorsTab({super.key});

  @override
  State<OrganizerModeratorsTab> createState() => OrganizerModeratorsScreenState();
}

class OrganizerModeratorsScreenState extends State<OrganizerModeratorsTab> {
  UserRole _currentUserRole = UserRole.moderator;
  Key _listKey = UniqueKey();

  void _onStatusChanged(UserRole status) {
    setState(() {
      _currentUserRole = status;
      _listKey = UniqueKey();
    });
  }

  Future<List<User>> getUsersByRole() async {
    final users = await service.user.getAllUsers(_currentUserRole);
    return users;
  }

  void onPromote(int userId) async {
    final response = await showConfirm(
      context,
      title: 'Promover a moderador',
      content: '¿Estás seguro de promover a moderador?',
      cancelText: 'Cancelar',
      confirmText: 'Promover a moderador',
    );
    if (response != true) return;

    final success = await service.user.promoteToModerator(userId);

    if (success) {
      Sonner.success('Moderador creado con éxito');
      setState(() {
        _listKey = UniqueKey();
      });
    } else {
      Sonner.error('Error al crear moderador');
    }
  }

  onDemote(int userId) async {
    final response = await showConfirm(
      context,
      title: 'Despromover a moderador',
      content: '¿Estás seguro de despromover a moderador?',
      cancelText: 'Cancelar',
      confirmText: 'Despromover a moderador',
    );
    if (response != true) return;

    final success = await service.user.demoteToUser(userId);

    if (success) {
      Sonner.success('Moderador despromovido con éxito');
      setState(() {
        _listKey = UniqueKey();
      });
    } else {
      Sonner.error('Error al despromover moderador');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Moderadores'),
      body: Col(
        gap: 1,
        children: [
          UserRoleTabs(onStatusChanged: _onStatusChanged, initialStatus: _currentUserRole),
          Expanded(
            key: _listKey,
            child: SearchableAsyncList(
              enablePullToRefresh: true,
              enableSearch: true,
              // searchFilter: _filterUser,
              emptyBuilder: const Center(child: Text('No tienes moderadores creados.')),
              wait: getUsersByRole,
              builder: (context, item, index) {
                return UserCard(
                  user: item,
                  trailingWidget: UserCardActions.promoteButton(
                    user: item,
                    onPromote: () => onPromote(item.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
