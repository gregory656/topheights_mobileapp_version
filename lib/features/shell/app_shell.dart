import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';
import '../../data/customer_profile.dart';
import '../../data/profile_repository.dart';
import '../spaces/account_screen.dart';
import '../spaces/empty_destination_screen.dart';
import '../spaces/home_screen.dart';
import '../spaces/energy_studio_screen.dart';
import '../shop/catalogue_screen.dart';
import 'brand_mark.dart';

enum _Destination { home, shop, studio, energy, account }

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.profileRepository});
  final ProfileRepository profileRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Destination _destination = _Destination.home;
  late Future<CustomerProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<CustomerProfile> _loadProfile() async {
    return widget.profileRepository.load();
  }

  void _select(_Destination destination) =>
      setState(() => _destination = destination);

  void _profileChanged(CustomerProfile profile) {
    setState(() {
      _profileFuture = Future.value(profile);
    });
  }

  String get _title => switch (_destination) {
    _Destination.home => 'Your energy, in good hands.',
    _Destination.shop => 'The energy shop',
    _Destination.studio => 'Energy Studio',
    _Destination.energy => 'My Energy',
    _Destination.account => 'Your account',
  };

  Widget _page(CustomerProfile profile) => switch (_destination) {
    _Destination.home => HomeScreen(
      profile: profile,
      onNavigate: (index) => _select(_Destination.values[index]),
    ),
    _Destination.shop => const CatalogueScreen(),
    _Destination.studio => const EnergyStudioScreen(),
    _Destination.energy => const EmptyDestinationScreen.energy(),
    _Destination.account => AccountScreen(
      repository: widget.profileRepository,
      profile: profile,
      onProfileChanged: _profileChanged,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadFailure(
            onRetry: () => setState(() => _profileFuture = _loadProfile()),
          );
        }
        if (!snapshot.hasData) return const _StartingUp();
        final profile = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final expandedRail = constraints.maxWidth >= 1120;
            final content = _page(profile);
            if (!wide) {
              return Scaffold(
                body: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _MobileTopBar(
                        title: _title,
                        onTapAccount: () => _select(_Destination.account),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_destination),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _destination.index,
                  height: 72,
                  onDestinationSelected: (index) =>
                      _select(_Destination.values[index]),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: 'Shop',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bolt_outlined),
                      selectedIcon: Icon(Icons.bolt_rounded),
                      label: 'Studio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.solar_power_outlined),
                      selectedIcon: Icon(Icons.solar_power_rounded),
                      label: 'My Energy',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Account',
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    _DesktopRail(
                      selected: _destination,
                      expanded: expandedRail,
                      onSelect: _select,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _DesktopTopBar(
                            title: _title,
                            profile: profile,
                            onTapAccount: () => _select(_Destination.account),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              child: KeyedSubtree(
                                key: ValueKey(_destination),
                                child: content,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.title, required this.onTapAccount});
  final String title;
  final VoidCallback onTapAccount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
    child: Row(
      children: [
        const BrandMark(size: 37),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOP HEIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: BrandColors.forest,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onTapAccount,
          tooltip: 'Open account',
          icon: const Icon(
            Icons.account_circle_outlined,
            color: BrandColors.forest,
          ),
        ),
      ],
    ),
  );
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.profile,
    required this.onTapAccount,
  });
  final String title;
  final CustomerProfile profile;
  final VoidCallback onTapAccount;

  @override
  Widget build(BuildContext context) => Container(
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 34),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: BrandColors.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              const Text(
                'A brighter way to power what matters.',
                style: TextStyle(fontSize: 12, color: BrandColors.muted),
              ),
            ],
          ),
        ),
        const _LocalBadge(),
        const SizedBox(width: 16),
        InkWell(
          onTap: onTapAccount,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: BrandColors.paleGreen,
                  child: Text(
                    profile.displayName.isEmpty
                        ? 'T'
                        : profile.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: BrandColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  profile.displayName.isEmpty
                      ? 'Your account'
                      : profile.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: BrandColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selected,
    required this.expanded,
    required this.onSelect,
  });
  final _Destination selected;
  final bool expanded;
  final ValueChanged<_Destination> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: expanded ? 238 : 86,
    decoration: const BoxDecoration(
      color: BrandColors.card,
      border: Border(right: BorderSide(color: BrandColors.line)),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            expanded ? 24 : 0,
            25,
            expanded ? 24 : 0,
            30,
          ),
          child: expanded
              ? const Row(
                  children: [
                    BrandMark(size: 42),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: BrandColors.forest,
                          ),
                        ),
                        Text(
                          'HEIGHTS',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: BrandColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const BrandMark(size: 42),
        ),
        for (final item in _Destination.values)
          _RailItem(
            destination: item,
            selected: selected == item,
            expanded: expanded,
            onTap: () => onSelect(item),
          ),
        const Spacer(),
        if (expanded)
          const Padding(
            padding: EdgeInsets.fromLTRB(19, 0, 19, 22),
            child: _LocalBadge(),
          ),
        if (!expanded)
          const Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: BrandColors.amber,
            ),
          ),
      ],
    ),
  );
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });
  final _Destination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  String get _label => switch (destination) {
    _Destination.home => 'Home',
    _Destination.shop => 'Shop',
    _Destination.studio => 'Energy Studio',
    _Destination.energy => 'My Energy',
    _Destination.account => 'Account',
  };
  IconData get _icon => switch (destination) {
    _Destination.home => selected ? Icons.home_rounded : Icons.home_outlined,
    _Destination.shop =>
      selected ? Icons.grid_view_rounded : Icons.grid_view_outlined,
    _Destination.studio => selected ? Icons.bolt_rounded : Icons.bolt_outlined,
    _Destination.energy =>
      selected ? Icons.solar_power_rounded : Icons.solar_power_outlined,
    _Destination.account =>
      selected ? Icons.person_rounded : Icons.person_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        expanded ? 12 : 14,
        3,
        expanded ? 12 : 14,
        3,
      ),
      child: Tooltip(
        message: expanded ? '' : _label,
        child: Material(
          color: selected ? BrandColors.paleGreen : Colors.transparent,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (expanded) const SizedBox(width: 15),
                  Icon(
                    _icon,
                    size: 21,
                    color: selected ? BrandColors.forest : BrandColors.muted,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 14),
                    Text(
                      _label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? BrandColors.forest
                            : BrandColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F3EC),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: BrandColors.line),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.phone_iphone_rounded,
          size: 13,
          color: BrandColors.forestSoft,
        ),
        SizedBox(width: 6),
        Text(
          'Saved on this device',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: BrandColors.forestSoft,
          ),
        ),
      ],
    ),
  );
}

class _StartingUp extends StatelessWidget {
  const _StartingUp();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: 54),
          SizedBox(height: 18),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: BrandColors.forest,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Getting your energy space ready…',
            style: TextStyle(fontSize: 12, color: BrandColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 56),
            const SizedBox(height: 20),
            Text(
              'We couldn’t open your local workspace.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your saved information has not been deleted. Try opening it again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}
