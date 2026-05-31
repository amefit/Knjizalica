import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/books_provider.dart';
import '../providers/reference_data_provider.dart';
import '../services/api_service.dart';
import '../widgets/data_table.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({
    super.key,
    this.bookId,
    this.embedded = false,
    this.onCancel,
    this.onSaved,
  });

  final int? bookId;
  final bool embedded;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _editionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _copyCountController = TextEditingController(text: '1');

  int? _genreId;
  int? _categoryId;
  int? _languageId;
  int? _publisherId;
  List<int> _selectedAuthorIds = [];
  String? _coverImagePath;
  bool _isLoading = false;
  String? _error;
  List<Author> _authors = [];

  bool get isEditing => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final refData = context.read<ReferenceDataProvider>();
      final booksProvider = context.read<BooksProvider>();
      final api = context.read<AuthApiHolder>().api;

      if (refData.genres.isEmpty) {
        await refData.loadAll();
      }

      if (refData.error != null) {
        throw ApiException(refData.error!);
      }

      _authors = await api.getAuthors();

      if (isEditing) {
        final book = await booksProvider.loadBook(widget.bookId!);
        if (book != null && mounted) {
          _titleController.text = book.title;
          _editionController.text = book.edition ?? '';
          _descriptionController.text = book.description ?? '';
          _genreId = book.genreId;
          _categoryId = book.bookCategoryId;
          _languageId = book.languageId;
          _publisherId = book.publisherId;
          _selectedAuthorIds = book.authors.map((a) => a.id).toList();
          _coverImagePath = book.coverImagePath;
          _copyCountController.text = '${book.copies.length}';
        }
      } else if (refData.genres.isNotEmpty) {
        _genreId = refData.genres.first.id;
        _categoryId =
            refData.bookCategories.isNotEmpty ? refData.bookCategories.first.id : null;
        _languageId = refData.languages.isNotEmpty ? refData.languages.first.id : null;
        _publisherId = refData.publishers.isNotEmpty ? refData.publishers.first.id : null;
      } else {
        throw ApiException('Reference data is missing. Add genres in Administration first.');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load book form.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCancel() {
    if (widget.embedded) {
      widget.onCancel?.call();
      return;
    }
    Navigator.pop(context);
  }

  void _handleSaved() {
    if (widget.embedded) {
      widget.onSaved?.call();
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editionController.dispose();
    _descriptionController.dispose();
    _copyCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthApiHolder>().api;
      final upload = await api.uploadFile(
        filePath: result.files.single.path!,
        fileName: result.files.single.name,
        category: 'books',
      );
      setState(() => _coverImagePath = upload.path);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to upload image.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_genreId == null || _categoryId == null || _languageId == null || _publisherId == null) {
      setState(() => _error = 'Please select all required dropdown values.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<BooksProvider>();
    final ok = await provider.saveBook(
      id: widget.bookId,
      title: _titleController.text.trim(),
      edition: _editionController.text.trim().isEmpty ? null : _editionController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      coverImagePath: _coverImagePath,
      genreId: _genreId!,
      bookCategoryId: _categoryId!,
      languageId: _languageId!,
      publisherId: _publisherId!,
      authorIds: _selectedAuthorIds,
      copyCount: int.tryParse(_copyCountController.text) ?? 1,
    );

    if (ok) {
      _handleSaved();
    } else {
      setState(() {
        _error = provider.error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = context.watch<ReferenceDataProvider>();

    final formBody = _isLoading && _titleController.text.isEmpty && _error == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ErrorBanner(message: _error!),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _editionController,
                        decoration: const InputDecoration(labelText: 'Edition'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _genreId,
                              decoration: const InputDecoration(labelText: 'Genre *'),
                              items: refData.genres
                                  .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _genreId = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _categoryId,
                              decoration: const InputDecoration(labelText: 'Category *'),
                              items: refData.bookCategories
                                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _languageId,
                              decoration: const InputDecoration(labelText: 'Language *'),
                              items: refData.languages
                                  .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _languageId = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _publisherId,
                              decoration: const InputDecoration(labelText: 'Publisher *'),
                              items: refData.publishers
                                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _publisherId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Authors',
                          border: OutlineInputBorder(),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _authors.map((author) {
                            final selected = _selectedAuthorIds.contains(author.id);
                            return FilterChip(
                              label: Text(author.fullName),
                              selected: selected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedAuthorIds.add(author.id);
                                  } else {
                                    _selectedAuthorIds.remove(author.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _copyCountController,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'Total Copies' : 'Number of Copies',
                          helperText: isEditing
                              ? 'Increase this number to add more inventory copies. Existing copies cannot be removed here.'
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Enter at least 1 copy';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Cover Image'),
                          ),
                          const SizedBox(width: 16),
                          if (_coverImagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ApiConfig.resolveAssetUrl(_coverImagePath),
                                width: 60,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'Save Changes' : 'Create Book'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _handleCancel,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: isEditing ? 'Edit Book' : 'Add Book',
            subtitle: 'Create a new title and copies for the catalog',
          ),
          const SizedBox(height: 16),
          Expanded(child: formBody),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Book' : 'Add Book'),
      ),
      body: formBody,
    );
  }
}

/// Holds ApiService reference for widgets that need direct API access.
class AuthApiHolder {
  AuthApiHolder(this.api);
  final ApiService api;
}
