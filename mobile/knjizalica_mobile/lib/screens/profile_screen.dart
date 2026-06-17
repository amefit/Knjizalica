import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../models/member_models.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  final _passwordFormKey = GlobalKey<FormState>();
  int? _selectedCityId;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _selectedCityId = profile?.cityId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.refreshProfile();
      await auth.loadCities();
      if (!mounted) {
        return;
      }
      final updated = auth.profile;
      if (updated != null) {
        _firstNameController.text = updated.firstName;
        _lastNameController.text = updated.lastName;
        _phoneController.text = updated.phoneNumber ?? '';
        setState(() {
          _selectedCityId = updated.cityId;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedCityId == null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      UpdateProfileRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        cityId: _selectedCityId!,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    } else if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      ChangePasswordRequest(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Password change failed.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: auth.isLoading && profile == null
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    title: 'Account',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? profile?.fullName ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(user?.email ?? profile?.email ?? ''),
                        Text('@${user?.username ?? profile?.username ?? ''}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Membership',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'Member card',
                          value: profile?.memberCardNumber ?? '—',
                        ),
                        _InfoRow(
                          label: 'Status',
                          value: profile?.membershipStatus ?? '—',
                        ),
                        _InfoRow(
                          label: 'Registered',
                          value: profile != null
                              ? DateFormat.yMMMd()
                                  .format(profile.registrationDate.toLocal())
                              : '—',
                        ),
                        _InfoRow(
                          label: 'Valid until',
                          value: profile != null
                              ? DateFormat.yMMMd()
                                  .format(profile.expiryDate.toLocal())
                              : '—',
                        ),
                        _InfoRow(
                          label: 'City',
                          value: profile?.cityName ?? '—',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Edit profile',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
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
                          if (auth.cities.isNotEmpty)
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
                              onChanged: (v) {
                                setState(() {
                                  _selectedCityId = v;
                                });
                              },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _saveProfile,
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Change password',
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Current password',
                            ),
                            obscureText: true,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'At least 8 characters';
                              }
                              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$').hasMatch(v)) {
                                return 'Must have digit, lower, upper and special char';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm new password',
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: auth.isLoading ? null : _changePassword,
                            child: const Text('Update password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notifications'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: auth.isLoading ? null : _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Sign out',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
