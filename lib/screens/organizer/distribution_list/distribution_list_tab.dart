import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qrmark/core/libs/service_hub.dart';
import 'package:qrmark/core/utils/navigation.dart';
import 'package:qrmark/core/widgets/appbar.dart';
import 'package:qrmark/core/widgets/await.dart';
import 'package:qrmark/core/widgets/scaffold.dart';
import 'package:qrmark/core/widgets/sonner.dart';
import 'package:qrmark/core/widgets/tabs.dart';
import 'package:qrmark/screens/organizer/distribution_list/members/add_members.dart';
import 'package:qrmark/screens/organizer/distribution_list/widgets/create_list_dialog.dart';
import 'package:qrmark/screens/organizer/distribution_list/widgets/distribution_list_card.dart';

class OrganizerDistributionListTab extends ScreenWithState {
  final IconData icon = LucideIcons.clipboardList;
  final String label = 'Listas';
  final String path = '/organizer/distribution_list';

  const OrganizerDistributionListTab({super.key});

  @override
  State<OrganizerDistributionListTab> createState() => OrganizerDistributionListScreenState();
}

class OrganizerDistributionListScreenState extends State<OrganizerDistributionListTab> {
  void onCreate() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      useSafeArea: true,
      builder: (context) => CreateListDialog(),
    );

    final name = result?['name'];
    final description = result?['description'];

    await service.distributionList.createList(name: name!, description: description);
    Sonner.success('Lista de difusión creada con éxito.');
    await service.distributionList.getMyLists();
  }

  @override
  Widget build(BuildContext context) {
    return Body(
      appBar: AppBarWidget(title: 'Listas de distribución'),
      body: SearchableAsyncList(
        wait: service.distributionList.getMyLists,
        enablePullToRefresh: true,
        enableSearch: true,
        emptyBuilder: const Center(child: Text('No tienes listas de distribución creadas.')),
        searchFilter: (query, item) {
          final queryLower = query.toLowerCase();
          return item.name.toLowerCase().contains(queryLower);
        },
        builder: (context, list, index) {
          return DistributionListCard(
            list: list,
            onTap: () {
              Navigate.to(OrganizerManageMembers.path, arguments: {'listId': list.id});
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'create-distribution-list',
        onPressed: onCreate,
        tooltip: 'Crear lista de distribución',
        child: Icon(LucideIcons.plus),
      ),
    );
  }
}
