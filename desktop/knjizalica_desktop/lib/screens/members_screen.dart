import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
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

  Future<void> _openMemberForm([Member? member]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MemberFormDialog(member: member),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member ${member == null ? 'created' : 'updated'} successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MembersProvider>();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Members',
          subtitle: 'View and manage library members',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _openMemberForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
            ),
          ],
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
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit member',
                      onPressed: () => _openMemberForm(member),
                    ),
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

class MemberFormDialog extends StatefulWidget {
  const MemberFormDialog({super.key, this.member});

  final Member? member;

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();

  int? _cityId;
  int? _membershipStatusId;
  DateTime? _expiryDate;

  List<City> _cities = [];
  List<LookupItem> _statuses = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _firstNameController.text = widget.member!.firstName;
      _lastNameController.text = widget.member!.lastName;
      _emailController.text = widget.member!.email;
      _phoneNumberController.text = widget.member!.phoneNumber ?? '';
      _cardNumberController.text = widget.member!.memberCardNumber;
      _cityId = widget.member!.cityId;
      _expiryDate = widget.member!.expiryDate;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getCities(),
        api.getMembershipStatuses(),
      ]);
      setState(() {
        _cities = results[0] as List<City>;
        _statuses = results[1] as List<LookupItem>;
        if (widget.member != null) {
          _membershipStatusId = _statuses
              .firstWhere((s) => s.name == widget.member!.membershipStatus)
              .id;
        }
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load form data')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
      'memberCardNumber': _cardNumberController.text,
      'cityId': _cityId,
      'membershipStatusId': _membershipStatusId,
      'expiryDate': _expiryDate?.toIso8601String(),
    };

    final provider = context.read<MembersProvider>();
    final bool ok;
    if (widget.member == null) {
      ok = await provider.createMember(body);
    } else {
      ok = await provider.updateMember(widget.member!.id, body);
    }

    if (ok && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      title: Text(widget.member == null ? 'Add Member' : 'Edit Member'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          hintText: 'Enter first name',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          hintText: 'Enter last name',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter email address',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +38761123456',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (!RegExp(r'^\+?[\d\s-]{6,}$').hasMatch(v)) {
                        return 'Enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'Enter member card number',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _cityId,
                        decoration: const InputDecoration(labelText: 'City'),
                        items: _cities.map((c) {
                          return DropdownMenuItem(value: c.id, child: Text(c.name));
                        }).toList(),
                        onChanged: (v) => setState(() => _cityId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _membershipStatusId,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statuses.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name));
                        }).toList(),
                        onChanged: (v) => setState(() => _membershipStatusId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Membership Expiry Date'),
                  subtitle: Text(_expiryDate == null
                      ? 'No expiry date set'
                      : DateFormat('MMM d, yyyy').format(_expiryDate!)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _expiryDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setState(() => _expiryDate = date);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
