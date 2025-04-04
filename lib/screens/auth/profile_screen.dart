import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final user = auth.userProfile;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await auth.signOut();
              context.goNamed('login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    child: user?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to update profile photo'),
            const SizedBox(height: 24),
            _sectionCard(
              context,
              title: 'Personal Information',
              items: [
                _infoTile('Name', user?.name ?? ''),
                _infoTile('Email', user?.email ?? ''),
                _infoTile('Phone', user?.phone ?? 'Not provided'),
                _infoTile('Age', user?.age?.toString() ?? ''),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Physical Information',
              items: [
                _infoTile('Weight (${user?.weightUnit ?? 'kg'})',
                    user?.weight?.toString() ?? ''),
                _infoTile('Height (${user?.heightUnit ?? 'cm'})',
                    user?.height?.toString() ?? ''),
                _infoTile(
                    'Injuries',
                    user?.injuries.isEmpty ?? true
                        ? 'None'
                        : user!.injuries.join(', ')),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Fitness Goals',
              items: [
                _infoTile('Training Goal', user?.fitnessGoal ?? ''),
                _infoTile(
                    'Diet Preferences', user?.dietaryHabits.join(', ') ?? ''),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Progress Photo',
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.background,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const Icon(Icons.image_outlined, size: 60),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              items: [
                _infoTile('Date', user?.progressPhotoDate ?? 'Not provided'),
                _infoTile('Description',
                    user?.progressPhotoDescription ?? 'No description'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          const SizedBox(height: 16),
          if (child != null) child else ...items,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.edit, size: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white10,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
