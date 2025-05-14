import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/models/distribution_list.dart';
import 'package:qrmark/core/models/user.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/core/widgets/user_card.dart';
import 'package:qrmark/screens/organizer/distribution_list/widgets/distribution_list_card.dart';
import 'package:qrmark/screens/organizer/invitations/send-invitations/widgets/distribution_tab.dart';

class OrganizerSendInvitationsScreen extends StatefulWidget {
  const OrganizerSendInvitationsScreen({super.key, required this.eventId});
  static const String path = '/organizer/invitations/send-invitations';
  final int eventId;
  @override
  State<OrganizerSendInvitationsScreen> createState() => OrganizerSendInvitationsScreenState();
}

class OrganizerSendInvitationsScreenState extends State<OrganizerSendInvitationsScreen> {
  Key _listKey = UniqueKey();
  DistributionMode? _selectedMode = DistributionMode.users;

  void _onStatusChanged(DistributionMode? mode) {
    setState(() {
      _selectedMode = mode;
      _listKey = UniqueKey();
    });
  }

  Future<List<User>> _loadUsers() async {
    return await service.user.getAllUsers(UserRole.user);
  }

  final List<int> _selectedUserIds = [];
  final List<int> _selectedListIds = [];

  Future<List<DistributionList>> _loadLists() async {
    return await service.distributionList.getMyLists();
  }

  void _sendInvitations() async {
    if (_selectedMode == DistributionMode.users && _selectedUserIds.isNotEmpty) {
      await service.invitation.bulkCreateInvitations(
        eventId: widget.eventId,
        userIds: _selectedUserIds,
      );
      Sonner.success('Invitaciones enviadas a ${_selectedUserIds.length} usuarios.');
      Navigate.back();
    } else if (_selectedMode == DistributionMode.lists && _selectedListIds.isNotEmpty) {
      for (final listId in _selectedListIds) {
        final users = await service.distributionList.getListMembers(listId);
        final userIds = users.map((user) => user.id).toList();
        await service.invitation.bulkCreateInvitations(eventId: widget.eventId, userIds: userIds);
      }
      Sonner.success('Invitaciones enviadas a ${_selectedListIds.length} listas.');
      Navigate.back();
    } else {
      Sonner.error('No has seleccionado ningún usuario o lista.');
    }
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _toggleListSelection(int listId) {
    setState(() {
      if (_selectedListIds.contains(listId)) {
        _selectedListIds.remove(listId);
      } else {
        _selectedListIds.add(listId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedMode == DistributionMode.users) {
        _selectedUserIds.clear();
        _listKey = UniqueKey();
        _loadUsers().then((users) {
          for (final user in users) {
            _selectedUserIds.add(user.id);
          }
        });
      } else {
        _selectedListIds.clear();
        _listKey = UniqueKey();
        _loadLists().then((lists) {
          for (final list in lists) {
            _selectedListIds.add(list.id);
          }
        });
      }
    });
  }

  bool isAllSelected() {
    if (_selectedMode == DistributionMode.users) {
      return _selectedUserIds.isNotEmpty;
    } else {
      return _selectedListIds.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserMode = DistributionMode.users == _selectedMode;
    return Body(
      appBar: AppBar(
        title: const Text('Enviar invitaciones'),
        actions: [
          // seleccionar todos los usuarios o listas
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            onPressed: _selectAll,
            color: isAllSelected() ? Colors.green : null,
          ),
        ],
      ),
      body: Column(
        children: [
          DistributionTabs(onStatusChanged: _onStatusChanged, initialStatus: _selectedMode!),
          Expanded(
            child:
                isUserMode
                    ? SearchableAsyncList(
                      key: _listKey,
                      wait: _loadUsers,
                      enableSearch: true,
                      enablePullToRefresh: true,
                      emptyBuilder: Center(child: Text('No tienes usuarios registrados.')),
                      builder: (ctx, user, index) {
                        final isSelected = _selectedUserIds.contains(user.id);
                        return UserCard(
                          user: user,
                          trailingWidget: UserCardActions.checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              if (value != null) {
                                _toggleUserSelection(user.id);
                              }
                            },
                          ),
                        );
                      },
                    )
                    : SearchableAsyncList(
                      key: _listKey,
                      wait: _loadLists,
                      enableSearch: true,
                      enablePullToRefresh: true,
                      emptyBuilder: Center(
                        child: Text('No tienes listas de distribución creadas.'),
                      ),
                      builder: (ctx, list, index) {
                        return DistributionListCard(
                          list: list,
                          onTap: () {
                            _toggleListSelection(list.id);
                          },
                          trailingWidget: DistributionListCardActions.checkbox(
                            value: _selectedListIds.contains(list.id),
                            onChanged: (value) {
                              if (value != null) {
                                _toggleListSelection(list.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ElevatedButton.icon(
          onPressed: _sendInvitations,
          icon: Icon(LucideIcons.send),
          label: const Text('Enviar invitaciones'),
        ),
      ),
    );
  }
}
