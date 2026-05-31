import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/loans_provider.dart';
import '../providers/members_provider.dart';
import '../services/api_service.dart';
import '../widgets/data_table.dart';
import '../widgets/status_badge.dart';
import 'book_form_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LoansProvider>();
      _searchController.text = provider.search;
      provider.loadLoans(tab: LoanTab.active);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = switch (_tabController.index) {
      0 => LoanTab.active,
      1 => LoanTab.overdue,
      _ => LoanTab.history,
    };
    context.read<LoansProvider>().loadLoans(pageOverride: 1, tab: tab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showNewLoanDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => const _NewLoanDialog(),
    );
  }

  Future<void> _confirmLoan(int id) async {
    final ok = await context.read<LoansProvider>().confirmLoan(id);
    if (!ok && mounted) {
      _showError(context.read<LoansProvider>().error);
    }
  }

  Future<void> _returnLoan(int id) async {
    final ok = await context.read<LoansProvider>().returnLoan(id);
    if (!ok && mounted) {
      _showError(context.read<LoansProvider>().error);
    }
  }

  Future<void> _cancelLoan(int id) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Loan'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Loan'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await context.read<LoansProvider>().cancelLoan(
            id,
            reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          );
      if (!ok && mounted) _showError(context.read<LoansProvider>().error);
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Operation failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoansProvider>();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Loans',
          subtitle: 'Track active, overdue, and historical loans',
          actions: [
            ElevatedButton.icon(
              onPressed: _showNewLoanDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Loan'),
            ),
          ],
        ),
        if (provider.error != null) ErrorBanner(message: provider.error!),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
            Tab(text: 'History'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SearchField(
              controller: _searchController,
              hint: 'Search loans...',
              width: 400,
              onSearch: provider.applySearch,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            isLoading: provider.isLoading,
            emptyMessage: 'No loans found.',
            columns: const [
              DataColumn(label: Text('Book')),
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Inventory')),
              DataColumn(label: Text('Borrowed')),
              DataColumn(label: Text('Due')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: provider.loans.map((loan) {
              return DataRow(cells: [
                DataCell(Text(loan.bookTitle)),
                DataCell(Text('${loan.memberName}\n${loan.memberCardNumber}')),
                DataCell(Text(loan.inventoryCode)),
                DataCell(Text(dateFormat.format(loan.borrowedAt.toLocal()))),
                DataCell(Text(dateFormat.format(loan.dueDate.toLocal()))),
                DataCell(StatusBadge(status: loan.status)),
                DataCell(_buildActions(loan)),
              ]);
            }).toList(),
          ),
        ),
        PaginationBar(
          page: provider.page,
          pageSize: provider.pageSize,
          totalCount: provider.totalCount,
          onPageChanged: (p) => provider.loadLoans(pageOverride: p),
        ),
      ],
    );
  }

  Widget _buildActions(Loan loan) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loan.status == 'Pending')
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            tooltip: 'Confirm',
            onPressed: () => _confirmLoan(loan.id),
          ),
        if (loan.status == 'Confirmed' || loan.status == 'Overdue')
          IconButton(
            icon: const Icon(Icons.assignment_return_outlined),
            tooltip: 'Return',
            onPressed: () => _returnLoan(loan.id),
          ),
        if (loan.status == 'Pending' || loan.status == 'Confirmed' || loan.status == 'Overdue')
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            tooltip: 'Cancel',
            onPressed: () => _cancelLoan(loan.id),
          ),
      ],
    );
  }
}

class _NewLoanDialog extends StatefulWidget {
  const _NewLoanDialog();

  @override
  State<_NewLoanDialog> createState() => _NewLoanDialogState();
}

class _NewLoanDialogState extends State<_NewLoanDialog> {
  Member? _selectedMember;
  BookCopy? _selectedCopy;
  BookDetail? _selectedBook;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  List<Member> _members = [];
  List<BookListItem> _books = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = context.read<AuthApiHolder>().api;
    try {
      final membersResult = await api.getMembers(pageSize: 200);
      final booksResult = await api.getBooks(pageSize: 200, availableOnly: true);
      setState(() {
        _members = membersResult.items.where((m) => m.membershipStatus == 'Active').toList();
        _books = booksResult.items;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load data.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onBookSelected(int? bookId) async {
    if (bookId == null) return;
    setState(() => _isLoading = true);
    final api = context.read<AuthApiHolder>().api;
    try {
      final book = await api.getBook(bookId);
      setState(() {
        _selectedBook = book;
        _selectedCopy = book.copies.where((c) => c.isAvailable).isEmpty
            ? null
            : book.copies.where((c) => c.isAvailable).first;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedMember == null || _selectedCopy == null) {
      setState(() => _error = 'Please select a member and an available book copy.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ok = await context.read<LoansProvider>().createLoan(
          memberProfileId: _selectedMember!.id,
          bookCopyId: _selectedCopy!.id,
          dueDate: _dueDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _error = context.read<LoansProvider>().error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Loan'),
      content: SizedBox(
        width: 480,
        child: _isLoading && _members.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      ErrorBanner(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<Member>(
                      value: _selectedMember,
                      decoration: const InputDecoration(labelText: 'Member *'),
                      items: _members
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('${m.fullName} (${m.memberCardNumber})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMember = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Book *'),
                      items: _books
                          .map((b) => DropdownMenuItem(value: b.id, child: Text(b.title)))
                          .toList(),
                      onChanged: _onBookSelected,
                    ),
                    if (_selectedBook != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BookCopy>(
                        value: _selectedCopy,
                        decoration: const InputDecoration(labelText: 'Book Copy *'),
                        items: _selectedBook!.copies
                            .where((c) => c.isAvailable)
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.inventoryCode),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCopy = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date *'),
                      subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _dueDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('Create Loan'),
        ),
      ],
    );
  }
}
