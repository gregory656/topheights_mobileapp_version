import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';
import '../../data/customer_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });
  final CustomerProfile profile;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth > 900
          ? 42.0
          : constraints.maxWidth > 600
          ? 30.0
          : 20.0;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          constraints.maxWidth > 600 ? 30 : 14,
          horizontal,
          34,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPanel(
                  profile: profile,
                  onDesign: () => onNavigate(2),
                  onShop: () => onNavigate(1),
                ),
                const SizedBox(height: 30),
                const _SectionHeading(
                  eyebrow: 'YOUR NEXT CHAPTER',
                  title: 'Start wherever you are.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final columns = rowConstraints.maxWidth > 850;
                    final cards = [
                      _JourneyCard(
                        number: '01',
                        icon: Icons.auto_awesome_outlined,
                        color: const Color(0xFFEAF2E5),
                        title: 'Explore energy',
                        body:
                            'Find practical ways to make your place work smarter.',
                        action: 'Browse the shop',
                        onTap: () => onNavigate(1),
                      ),
                      _JourneyCard(
                        number: '02',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFF4EFD8),
                        title: 'Plan your power',
                        body:
                            'Tell us what matters. Build a first picture of your needs.',
                        action: 'Open Energy Studio',
                        onTap: () => onNavigate(2),
                      ),
                      _JourneyCard(
                        number: '03',
                        icon: Icons.solar_power_outlined,
                        color: const Color(0xFFE7EFF0),
                        title: 'Care for a system',
                        body:
                            'Keep your installation notes and next steps together.',
                        action: 'Visit My Energy',
                        onTap: () => onNavigate(3),
                      ),
                    ];
                    if (columns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 14),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          cards[i],
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _QuietNote(onTap: () => onNavigate(4)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.profile,
    required this.onDesign,
    required this.onShop,
  });
  final CustomerProfile profile;
  final VoidCallback onDesign;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 590;
      final greeting = profile.useTopBossGreeting
          ? 'Hello, ${profile.greetingName == 'there' ? 'Top Boss' : profile.greetingName}.'
          : 'Hello, ${profile.greetingName}.';
      return Container(
        constraints: BoxConstraints(minHeight: compact ? 510 : 365),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF194D3B), Color(0xFF0D3028), Color(0xFF09271F)],
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.forest.withValues(alpha: .12),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeroAtmospherePainter()),
            ),
            if (compact)
              Positioned(
                top: 175,
                right: -14,
                left: 0,
                height: 310,
                child: IgnorePointer(
                  child: CustomPaint(painter: _SolarIllustrationPainter()),
                ),
              ),
            if (!compact)
              Positioned(
                right: 5,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * .49,
                child: IgnorePointer(
                  child: CustomPaint(painter: _SolarIllustrationPainter()),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 23 : 42,
                compact ? 27 : 39,
                compact ? 23 : 42,
                compact ? 24 : 38,
              ),
              child: SizedBox(
                width: compact ? double.infinity : constraints.maxWidth * .58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: BrandColors.leaf,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'A BRIGHTER WAY FORWARD',
                          style: TextStyle(
                            color: Color(0xFFC8D7CA),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 20 : 26),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .83),
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Power your\nnext good thing.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 39 : 51,
                        height: 1.01,
                      ),
                    ),
                    const SizedBox(height: 13),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 395),
                      child: const Text(
                        'Solar, smarter energy and the people who make it all work — together, in one place.',
                        style: TextStyle(
                          color: Color(0xFFD1DDD3),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 21),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onDesign,
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Explore Energy Studio'),
                        ),
                        TextButton.icon(
                          onPressed: onShop,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                          ),
                          label: const Text('Browse the shop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 14,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: BrandColors.leaf,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'MADE FOR REAL LIFE IN KENYA',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.35,
                      color: Color(0xFFB9CBBB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _HeroAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final haze = Paint()
      ..shader =
          RadialGradient(
            colors: [
              BrandColors.leaf.withValues(alpha: .12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .83, size.height * .18),
              radius: size.height * .72,
            ),
          );
    canvas.drawRect(Offset.zero & size, haze);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(
        Offset(x, size.height * .72),
        Offset(x, size.height),
        grid,
      );
    }
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.77 + i * .055);
      canvas.drawLine(Offset(size.width * .35, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SolarIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .55, size.height * .42);
    final sunRect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide * .23,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * .31,
      Paint()..color = BrandColors.leaf.withValues(alpha: .035),
    );
    canvas.drawCircle(
      center,
      size.shortestSide * .235,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE9AA), Color(0xFFF1B74A), Color(0xFFDB9441)],
        ).createShader(sunRect),
    );
    final halo = Paint()
      ..color = Colors.white.withValues(alpha: .19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .83,
        height: size.height * .53,
      ),
      halo,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.22);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .76,
        height: size.height * .42,
      ),
      Paint()
        ..color = BrandColors.leaf.withValues(alpha: .42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width * .16, size.height * .49),
      4,
      Paint()..color = BrandColors.leaf,
    );
    canvas.drawCircle(
      Offset(size.width * .89, size.height * .43),
      3,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );

    final hill = Path()
      ..moveTo(0, size.height * .76)
      ..cubicTo(
        size.width * .22,
        size.height * .63,
        size.width * .5,
        size.height * .76,
        size.width * .72,
        size.height * .67,
      )
      ..cubicTo(
        size.width * .86,
        size.height * .63,
        size.width * .93,
        size.height * .68,
        size.width,
        size.height * .61,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF153C30));
    final farHill = Path()
      ..moveTo(0, size.height * .86)
      ..cubicTo(
        size.width * .25,
        size.height * .74,
        size.width * .47,
        size.height * .9,
        size.width * .7,
        size.height * .79,
      )
      ..cubicTo(
        size.width * .84,
        size.height * .72,
        size.width * .94,
        size.height * .77,
        size.width,
        size.height * .74,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farHill, Paint()..color = const Color(0xFF0E3028));

    final panelPaint = Paint()
      ..color = const Color(0xFF214D45)
      ..style = PaintingStyle.fill;
    final panelLine = Paint()
      ..color = const Color(0xFFA8D6A8).withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final panel = Path()
      ..moveTo(size.width * .25, size.height * .79)
      ..lineTo(size.width * .65, size.height * .72)
      ..lineTo(size.width * .83, size.height * .87)
      ..lineTo(size.width * .38, size.height * .94)
      ..close();
    canvas.drawPath(panel, panelPaint);
    canvas.drawPath(panel, panelLine);
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      canvas.drawLine(
        Offset(size.width * (.25 + .13 * t), size.height * (.79 + .15 * t)),
        Offset(size.width * (.65 + .18 * t), size.height * (.72 + .15 * t)),
        panelLine,
      );
    }
    for (var i = 1; i <= 2; i++) {
      final t = i / 3;
      canvas.drawLine(
        Offset(size.width * (.25 + .4 * t), size.height * (.79 - .07 * t)),
        Offset(size.width * (.38 + .45 * t), size.height * (.94 - .07 * t)),
        panelLine,
      );
    }

    final house = Paint()..color = const Color(0xFFEDE9D9);
    final roof = Paint()..color = const Color(0xFFB9C5AB);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .73,
        size.height * .69,
        size.width * .2,
        size.height * .2,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, house);
    final roofPath = Path()
      ..moveTo(size.width * .69, size.height * .7)
      ..lineTo(size.width * .82, size.height * .61)
      ..lineTo(size.width * .97, size.height * .7)
      ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .8,
        size.height * .77,
        size.width * .048,
        size.height * .12,
      ),
      Paint()..color = BrandColors.forest,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .87,
        size.height * .73,
        size.width * .042,
        size.height * .04,
      ),
      Paint()..color = const Color(0xFF91BFAD),
    );

    final tree = Paint()..color = const Color(0xFF82AE75);
    canvas.drawCircle(
      Offset(size.width * .13, size.height * .76),
      size.width * .062,
      tree,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .117,
        size.height * .79,
        size.width * .026,
        size.height * .12,
      ),
      Paint()..color = const Color(0xFF674D33),
    );
    canvas.drawCircle(
      Offset(size.width * .07, size.height * .82),
      size.width * .043,
      Paint()..color = const Color(0xFF5F986B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: BrandColors.forestSoft,
        ),
      ),
      const SizedBox(height: 4),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
    ],
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: BrandColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: const BorderSide(color: BrandColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: BrandColors.forest, size: 21),
                ),
                const Spacer(),
                Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFFADB8AE),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: BrandColors.forest,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: BrandColors.forest,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEEF1E9),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: BrandColors.forestSoft,
              size: 19,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your profile stays on this device for now. You can edit or clear it any time.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: BrandColors.forestSoft,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
              color: BrandColors.forestSoft,
            ),
          ],
        ),
      ),
    ),
  );
}
