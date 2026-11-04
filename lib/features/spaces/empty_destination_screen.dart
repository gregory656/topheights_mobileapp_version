import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';
import '../shell/brand_mark.dart';

class EmptyDestinationScreen extends StatelessWidget {
  const EmptyDestinationScreen.shop({super.key})
    : _icon = Icons.grid_view_rounded,
      _eyebrow = 'THE ENERGY SHOP',
      _title = 'Good energy starts\nwith the right things.',
      _body =
          'A considered catalogue for solar, electrical and everyday energy needs is coming into view here.',
      _pill = 'Catalogue foundation · next up',
      _stamp = 'NO PRODUCTS ADDED YET';
  const EmptyDestinationScreen.studio({super.key})
    : _icon = Icons.bolt_rounded,
      _eyebrow = 'ENERGY STUDIO',
      _title = 'A clearer picture\nof your power.',
      _body =
          'Map the appliances and moments that matter. Your saved energy assessment will live here.',
      _pill = 'Assessment tools · being prepared',
      _stamp = 'NO ASSESSMENTS YET';
  const EmptyDestinationScreen.energy({super.key})
    : _icon = Icons.solar_power_rounded,
      _eyebrow = 'MY ENERGY',
      _title = 'Your energy story\nbegins here.',
      _body =
          'Installed systems, service notes and the things you want to keep close will have a home here.',
      _pill = 'No connected devices',
      _stamp = 'NO SYSTEMS ADDED YET';

  final IconData _icon;
  final String _eyebrow;
  final String _title;
  final String _body;
  final String _pill;
  final String _stamp;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tight = constraints.maxWidth < 580;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tight ? 20 : 40,
          tight ? 18 : 42,
          tight ? 20 : 40,
          30,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(tight ? 23 : 39),
                  decoration: BoxDecoration(
                    color: BrandColors.card,
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: BrandColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: BrandColors.paleGreen,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              _icon,
                              color: BrandColors.forest,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _eyebrow,
                            style: const TextStyle(
                              color: BrandColors.forestSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.55,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontSize: tight ? 34 : 45),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Text(
                          _body,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: BrandColors.muted),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4EE),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: BrandColors.forestSoft,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _pill,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.forestSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF0E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const BrandMark(size: 33),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stamp,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.15,
                                color: BrandColors.forest,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Nothing is being simulated or shown as live data.',
                              style: TextStyle(
                                fontSize: 12,
                                color: BrandColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
