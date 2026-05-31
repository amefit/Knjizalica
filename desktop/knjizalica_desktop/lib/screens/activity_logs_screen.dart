import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/members_provider.dart';
import '../widgets/data_table.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityLogsProvider>();
      _searchController.text = provider.search;
      provider.loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityLogsProvider>();
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Activity History',
          subtitle: 'Audit trail of system actions and changes',
        ),
        if (provider.error != null) ErrorBanner(message: provider.error!),
        Row(
          children: [
            SearchField(
              controller: _searchController,
              hint: 'Search activity logs...',
              width: 480,
              onSearch: provider.applySearch,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            isLoading: provider.isLoading,
            emptyMessage: 'No activity logs found.',
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Entity')),
              DataColumn(label: Text('Description')),
            ],
            rows: provider.logs.map((log) {
              return DataRow(cells: [
                DataCell(Text(dateFormat.format(log.createdAt.toLocal()))),
                DataCell(Text(log.userName ?? 'System')),
                DataCell(Text(log.activityType)),
                DataCell(Text('${log.entityName}${log.entityId != null ? ' #${log.entityId}' : ''}')),
                DataCell(Text(log.description)),
              ]);
            }).toList(),
          ),
        ),
        PaginationBar(
          page: provider.page,
          pageSize: provider.pageSize,
          totalCount: provider.totalCount,
          onPageChanged: (p) => provider.loadLogs(pageOverride: p),
        ),
      ],
    );
  }
}
