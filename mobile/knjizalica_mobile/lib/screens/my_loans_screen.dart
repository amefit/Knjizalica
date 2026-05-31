import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/loan_models.dart';
import '../providers/loans_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/mobile_header.dart';
import '../widgets/status_badge.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoansProvider>();
    final allLoans = [...loans.activeLoans, ...loans.historyLoans];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MobileHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'My Loans',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: loans.isLoading
                  ? const LoadingWidget(message: 'Loading your loans...')
                  : RefreshIndicator(
                      onRefresh: () => context.read<LoansProvider>().loadMyLoans(),
                      child: allLoans.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('You have no loans yet.')),
                              ],
                            )
                          : ListView.separated(
                              itemCount: allLoans.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) {
                                return _LoanTile(
                                  loan: allLoans[index],
                                  index: index + 1,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan, required this.index});

  final LoanDto loan;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final imageUrl = ApiConfig.resolveMediaUrl(loan.coverImagePath);
    final isReturned = loan.status.toLowerCase() == 'completed' || loan.returnedAt != null;
    final isOverdue = loan.isOverdue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.toString().padLeft(3, '0'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isEmpty
                ? Container(
                    width: 52,
                    height: 68,
                    color: const Color(0xFFE8E0D4),
                    child: const Icon(Icons.menu_book_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 52,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.bookTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  loan.inventoryCode,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  status: isReturned
                      ? 'Returned'
                      : isOverdue
                          ? 'Overdue'
                          : 'Active',
                ),
                const SizedBox(height: 6),
                Text(
                  isReturned && loan.returnedAt != null
                      ? 'Returned: ${dateFormat.format(loan.returnedAt!.toLocal())}'
                      : 'Return by: ${dateFormat.format(loan.dueDate.toLocal())}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
