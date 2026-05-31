import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/reference_data_provider.dart';
import '../widgets/data_table.dart';
import 'authors_screen.dart';
import 'news_screen.dart';
import 'reports_screen.dart';

class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferenceDataProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferenceDataProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Administration',
          subtitle: 'Manage reference data and lookup tables',
        ),
        if (provider.error != null) ErrorBanner(message: provider.error!),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Countries'),
            Tab(text: 'Cities'),
            Tab(text: 'Genres'),
            Tab(text: 'Categories'),
            Tab(text: 'Languages'),
            Tab(text: 'Publishers'),
            Tab(text: 'News'),
            Tab(text: 'Authors'),
            Tab(text: 'Reports'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: provider.isLoading && provider.countries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _LookupTab(
                      type: 'country',
                      items: provider.countries.map((c) => _LookupRow(c.id, c.name)).toList(),
                    ),
                    _CityTab(cities: provider.cities, countries: provider.countries),
                    _LookupTab(
                      type: 'genre',
                      items: provider.genres.map((g) => _LookupRow(g.id, g.name)).toList(),
                    ),
                    _LookupTab(
                      type: 'category',
                      items: provider.bookCategories.map((c) => _LookupRow(c.id, c.name)).toList(),
                    ),
                    _LookupTab(
                      type: 'language',
                      items: provider.languages.map((l) => _LookupRow(l.id, l.name)).toList(),
                    ),
                    _LookupTab(
                      type: 'publisher',
                      items: provider.publishers.map((p) => _LookupRow(p.id, p.name)).toList(),
                    ),
                    const NewsScreen(embedded: true),
                    const AuthorsScreen(embedded: true),
                    const ReportsScreen(embedded: true),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LookupRow {
  _LookupRow(this.id, this.name);
  final int id;
  final String name;
}

class _LookupTab extends StatelessWidget {
  const _LookupTab({required this.type, required this.items});

  final String type;
  final List<_LookupRow> items;

  Future<void> _showDialog(BuildContext context, {_LookupRow? item}) async {
    final controller = TextEditingController(text: item?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true || !context.mounted) return;

    final provider = context.read<ReferenceDataProvider>();
    final ok = await provider.saveLookup(
      type: type,
      id: item?.id,
      name: controller.text.trim(),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save')),
      );
    }
  }

  Future<void> _delete(BuildContext context, _LookupRow item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${item.name}"?'),
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

    if (confirmed == true && context.mounted) {
      final provider = context.read<ReferenceDataProvider>();
      final ok = await provider.deleteLookup(type, item.id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to delete')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AppDataTable(
            emptyMessage: 'No items found.',
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Actions')),
            ],
            rows: items.map((item) {
              return DataRow(cells: [
                DataCell(Text(item.name)),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showDialog(context, item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _delete(context, item),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CityTab extends StatelessWidget {
  const _CityTab({required this.cities, required this.countries});

  final List<City> cities;
  final List<Country> countries;

  Future<void> _showDialog(BuildContext context, {City? city}) async {
    final nameController = TextEditingController(text: city?.name ?? '');
    int? countryId = city?.countryId ?? (countries.isNotEmpty ? countries.first.id : null);
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(city == null ? 'Add City' : 'Edit City'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: countryId,
                  decoration: const InputDecoration(labelText: 'Country *'),
                  items: countries
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => countryId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && countryId != null) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save != true || !context.mounted || countryId == null) return;

    final provider = context.read<ReferenceDataProvider>();
    final ok = await provider.saveLookup(
      type: 'city',
      id: city?.id,
      name: nameController.text.trim(),
      countryId: countryId,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save')),
      );
    }
  }

  Future<void> _delete(BuildContext context, City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete City'),
        content: Text('Delete "${city.name}"?'),
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

    if (confirmed == true && context.mounted) {
      final provider = context.read<ReferenceDataProvider>();
      final ok = await provider.deleteLookup('city', city.id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to delete')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add City'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AppDataTable(
            emptyMessage: 'No cities found.',
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Country')),
              DataColumn(label: Text('Actions')),
            ],
            rows: cities.map((city) {
              return DataRow(cells: [
                DataCell(Text(city.name)),
                DataCell(Text(city.countryName ?? '—')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showDialog(context, city: city),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _delete(context, city),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
