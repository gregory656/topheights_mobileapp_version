import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';
import '../../data/customer_profile.dart';
import '../../data/profile_repository.dart';
import '../shell/brand_mark.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.onProfileChanged,
  });
  final ProfileRepository repository;
  final CustomerProfile profile;
  final ValueChanged<CustomerProfile> onProfileChanged;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  late final TextEditingController _businessController = TextEditingController(
    text: widget.profile.businessName,
  );
  late bool _useTopBoss = widget.profile.useTopBossGreeting;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _nameController.text = widget.profile.displayName;
      _businessController.text = widget.profile.businessName;
      _useTopBoss = widget.profile.useTopBossGreeting;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    final profile = CustomerProfile(
      displayName: _nameController.text,
      businessName: _businessController.text,
      useTopBossGreeting: _useTopBoss,
    );
    try {
      await widget.repository.save(profile);
      if (!mounted) return;
      widget.onProfileChanged(profile);
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Your changes could not be saved. Please try again.';
      });
    }
  }

  Future<void> _clearProfile() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this local profile?'),
        content: const Text(
          'Your saved name and business name will be removed from this device. Other app data is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep profile'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear profile'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    try {
      await widget.repository.clearLocalProfile();
      if (!mounted) return;
      const empty = CustomerProfile(
        displayName: '',
        businessName: '',
        useTopBossGreeting: true,
      );
      _nameController.clear();
      _businessController.clear();
      setState(() {
        _useTopBoss = true;
        _saved = false;
        _error = null;
      });
      widget.onProfileChanged(empty);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local profile cleared.')));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The local profile could not be cleared. Try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tight = constraints.maxWidth < 620;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tight ? 20 : 42,
          tight ? 18 : 38,
          tight ? 20 : 42,
          34,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make this space yours.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: tight ? 34 : 42,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A few details make the experience feel a little more like home.',
                  style: TextStyle(fontSize: 14, color: BrandColors.muted),
                ),
                const SizedBox(height: 25),
                _ProfileFormCard(
                  nameController: _nameController,
                  businessController: _businessController,
                  useTopBoss: _useTopBoss,
                  onToggleGreeting: (value) =>
                      setState(() => _useTopBoss = value),
                ),
                const SizedBox(height: 14),
                _LocalDataCard(onClear: _clearProfile),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB33B36),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_saved) ...[
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: BrandColors.forestSoft,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Saved on this device.',
                        style: TextStyle(
                          color: BrandColors.forestSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: tight ? double.infinity : 210,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BrandColors.forest,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileFormCard extends StatelessWidget {
  const _ProfileFormCard({
    required this.nameController,
    required this.businessController,
    required this.useTopBoss,
    required this.onToggleGreeting,
  });
  final TextEditingController nameController;
  final TextEditingController businessController;
  final bool useTopBoss;
  final ValueChanged<bool> onToggleGreeting;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: BrandColors.card,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: BrandColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_outline_rounded, color: BrandColors.forest),
            SizedBox(width: 10),
            Text(
              'Your details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: BrandColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'What should we call you?',
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: businessController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Business or site name',
            hintText: 'Optional',
          ),
        ),
        const SizedBox(height: 11),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: useTopBoss,
          onChanged: onToggleGreeting,
          activeTrackColor: BrandColors.forest,
          title: const Text(
            'Use the “Top Boss” greeting',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'A little brand personality, only if it feels like you.',
            style: TextStyle(fontSize: 11, color: BrandColors.muted),
          ),
        ),
      ],
    ),
  );
}

class _LocalDataCard extends StatelessWidget {
  const _LocalDataCard({required this.onClear});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF1E9),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            BrandMark(size: 36),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A note about your data',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.forest,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'This early version saves your profile on this device only.',
                    style: TextStyle(
                      color: BrandColors.forestSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: Color(0xFFD7DFD4)),
        ),
        const Text(
          'There is no account sync or company connection yet. Clearing your local profile does not affect any other saved data.',
          style: TextStyle(
            color: BrandColors.forestSoft,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: const Text('Clear local profile'),
            style: TextButton.styleFrom(foregroundColor: BrandColors.forest),
          ),
        ),
      ],
    ),
  );
}
