import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int? _selectedCityId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCities();
    });
  }

  Future<void> _loadCities() async {
    final auth = context.read<AuthProvider>();
    await auth.loadCities(silent: true);
    if (!mounted) {
      return;
    }
    if (auth.cities.isNotEmpty) {
      setState(() {
        _selectedCityId = auth.cities.first.id;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCityId == null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final request = RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      cityId: _selectedCityId!,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    final success = await auth.register(request);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'At least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: 'e.g. +38761123456',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (!RegExp(r'^\+?[\d\s-]{6,}$').hasMatch(v)) {
                        return 'Enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (auth.isLoading && auth.cities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Loading cities...',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                else if (auth.cities.isEmpty)
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      errorText:
                          'Failed to load cities. Check your connection.',
                    ),
                    validator: (_) => 'Cities must be loaded to continue',
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    decoration: const InputDecoration(labelText: 'City'),
                    items: auth.cities
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                      });
                    },
                    validator: (v) => v == null ? 'Select a city' : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'At least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
