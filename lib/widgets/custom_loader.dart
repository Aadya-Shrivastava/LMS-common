import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Which page shape the loading skeleton imitates, so the skeleton
/// looks like the screen that's about to appear.
enum SkeletonLayout {
  /// A summary card, then rows of items (most list screens).
  list,

  /// A navy header, stat tiles, then cards (the dashboard).
  dashboard,

  /// A profile header, 2x2 tiles, then detail rows.
  profile,

  /// Day chips, then period rows (timetable).
  timetable,

  /// Form-style cards with fields (account settings).
  form,
}

/// Shown while a screen's data is loading for the first time: grey
/// placeholder shapes with a soft shimmer, in the shape of the screen
/// (instead of a spinner on a blank page).
///
/// Once a screen has loaded once, it opens instantly with saved data
/// (see `loadSavedThenFresh`), so this mostly shows on a first visit.
class CustomLoader extends StatelessWidget {
  final SkeletonLayout layout;

  const CustomLoader({super.key, this.layout = SkeletonLayout.list});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Shimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: switch (layout) {
            SkeletonLayout.list => _list(),
            SkeletonLayout.dashboard => _dashboard(),
            SkeletonLayout.profile => _profile(),
            SkeletonLayout.timetable => _timetable(),
            SkeletonLayout.form => _form(),
          },
        ),
      ),
    );
  }

  static List<Widget> _list() => [
        const _SkeletonCard(height: 92),
        const SizedBox(height: 16),
        _SkeletonSection(rows: 6, rowBuilder: (_) => const _SkeletonRow()),
      ];

  // The dashboard draws its own navy header above this, so it starts
  // with the stat tiles.
  static List<Widget> _dashboard() => [
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 76)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 76)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 76)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 76)),
          ],
        ),
        const SizedBox(height: 16),
        _SkeletonSection(rows: 3, rowBuilder: (_) => const _SkeletonRow()),
        const SizedBox(height: 16),
        _SkeletonSection(rows: 2, rowBuilder: (_) => const _SkeletonRow()),
      ];

  static List<Widget> _profile() => [
        const _SkeletonCard(height: 112, dark: true),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 62)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 62)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 62)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 62)),
          ],
        ),
        const SizedBox(height: 14),
        _SkeletonSection(rows: 6, rowBuilder: (_) => const _SkeletonDetailRow()),
      ];

  static List<Widget> _timetable() => [
        const Row(
          children: [
            Expanded(child: _SkeletonCard(height: 64)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonCard(height: 64)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              const Expanded(child: SkeletonBox(height: 34, radius: 20)),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _SkeletonSection(rows: 5, rowBuilder: (_) => const _SkeletonRow(leadingWidth: 56)),
      ];

  static List<Widget> _form() => [
        for (var card = 0; card < 2; card++) ...[
          _SkeletonSection(
            rows: 3,
            rowBuilder: (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 90, height: 10),
                  SizedBox(height: 8),
                  SkeletonBox(height: 44, radius: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ];
}

/// A grey placeholder shape. Inside a `Shimmer`, it shimmers.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6});

  static const _base = Color(0xFFE3E6EA);
  static const _highlight = Color(0xFFF1F3F5);

  @override
  Widget build(BuildContext context) {
    // Inside a Shimmer, gently pulse between two greys.
    final animation = context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.notifier;
    final t = animation == null ? 0.0 : Curves.easeInOut.transform(animation.value);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(_base, _highlight, t),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Makes every `SkeletonBox` inside it gently pulse, so the page looks
/// alive while loading. Turns itself off when the phone asks for
/// reduced motion.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(notifier: _controller, child: widget.child);
  }
}

/// Hands the pulse animation down to the `SkeletonBox`es.
class _ShimmerScope extends InheritedNotifier<Animation<double>> {
  const _ShimmerScope({required super.notifier, required super.child});
}

/// A plain rounded card-shaped placeholder.
class _SkeletonCard extends StatelessWidget {
  final double height;

  /// A darker placeholder for navy header cards.
  final bool dark;

  const _SkeletonCard({required this.height, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFFD5D9E0) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: dark
          ? null
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 60, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
    );
  }
}

/// A white section card with a title bar and `rows` placeholder rows.
class _SkeletonSection extends StatelessWidget {
  final int rows;
  final Widget Function(int index) rowBuilder;

  const _SkeletonSection({required this.rows, required this.rowBuilder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 130, height: 14),
          const SizedBox(height: 14),
          for (var i = 0; i < rows; i++) rowBuilder(i),
        ],
      ),
    );
  }
}

/// A list-item placeholder: a square, two lines of text, a pill.
class _SkeletonRow extends StatelessWidget {
  final double leadingWidth;

  const _SkeletonRow({this.leadingWidth = 40});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SkeletonBox(width: leadingWidth, height: 40, radius: 10),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 12),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  alignment: Alignment.centerLeft,
                  child: SkeletonBox(height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 54, height: 22, radius: 12),
        ],
      ),
    );
  }
}

/// A "label ...... value" placeholder, like the profile detail rows.
class _SkeletonDetailRow extends StatelessWidget {
  const _SkeletonDetailRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonBox(width: 18, height: 18, radius: 9),
          SizedBox(width: 10),
          SkeletonBox(width: 90, height: 11),
          Spacer(),
          SkeletonBox(width: 110, height: 12),
        ],
      ),
    );
  }
}
