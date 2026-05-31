import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/members_provider.dart';
import '../widgets/data_table.dart';
import '../widgets/status_badge.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MembersProvider>();
      _searchController.text = provider.search;
      provider.loadMembers(tab: MemberTab.all);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = switch (_tabController.index) {
      0 => MemberTab.all,
      1 => MemberTab.active,
      _ => MemberTab.blocked,
    };
    context.read<MembersProvider>().loadMembers(pageOverride: 1, tab: tab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _blockMember(int id) async {
    final ok = await context.read<MembersProvider>().blockMember(id);
    if (!ok && mounted) _showError();
  }

  Future<void> _unblockMember(int id) async {
    final ok = await context.read<MembersProvider>().unblockMember(id);
    if (!ok && mounted) _showError();
  }

  Future<void> _deleteMember(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Delete member "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await context.read<MembersProvider>().deleteMember(id);
      if (!ok && mounted) _showError();
    }
  }

  void _showError() {
    final error = context.read<MembersProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Operation failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MembersProvider>();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Members',
          subtitle: 'View and manage library members',
        ),
        if (provider.error != null) ErrorBanner(message: provider.error!),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Blocked'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SearchField(
              controller: _searchController,
              hint: 'Search by name, email, card number...',
              width: 480,
              onSearch: provider.applySearch,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            isLoading: provider.isLoading,
            emptyMessage: 'No members found.',
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Card Number')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('City')),
              DataColumn(label: Text('Registered')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: provider.members.map((member) {
              return DataRow(cells: [
                DataCell(Text(member.fullName)),
                DataCell(Text(member.memberCardNumber)),
                DataCell(Text(member.email)),
                DataCell(Text(member.cityName)),
                DataCell(Text(dateFormat.format(member.registrationDate.toLocal()))),
                DataCell(StatusBadge(status: member.membershipStatus)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline, size: 20),
                      tooltip: 'Email member',
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: member.email,
                          query: 'subject=Knjizalica library',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    if (member.membershipStatus == 'Active')
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.orange),
                        tooltip: 'Block',
                        onPressed: () => _blockMember(member.id),
                      ),
                    if (member.membershipStatus == 'Blocked')
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Unblock',
                        onPressed: () => _unblockMember(member.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _deleteMember(member.id, member.fullName),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
        PaginationBar(
          page: provider.page,
          pageSize: provider.pageSize,
          totalCount: provider.totalCount,
          onPageChanged: (p) => provider.loadMembers(pageOverride: p),
        ),
      ],
    );
  }
}
