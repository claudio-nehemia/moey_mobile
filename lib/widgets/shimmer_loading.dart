import 'package:flutter/material.dart';
import '../utils/constant.dart';

/// Shimmer animation wrapper — wraps child in a pulsing shimmer effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: 0.4 + (_animation.value * 0.4), child: child);
      },
      child: widget.child,
    );
  }
}

/// Reusable shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, this.width = double.infinity, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Constants.secondaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for notification list
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Constants.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Constants.secondaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 44, height: 44, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(height: 16, width: 200),
                            const SizedBox(height: 8),
                            ShimmerBox(height: 12, width: 260),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBox(width: 100, height: 24, radius: 8),
                      const SizedBox(width: 10),
                      ShimmerBox(width: 80, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}

/// Skeleton for dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            ShimmerBox(height: 120, radius: 20),
            const SizedBox(height: 20),
            // Summary cards
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 90, radius: 14)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 90, radius: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 90, radius: 14)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 90, radius: 14)),
              ],
            ),
            const SizedBox(height: 28),
            ShimmerBox(height: 18, width: 140),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShimmerBox(height: 72, radius: 14),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for task list
class TaskSkeleton extends StatelessWidget {
  const TaskSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 70, radius: 14)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 70, radius: 14)),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 80, radius: 14),
            )),
          ],
        ),
      ),
    );
  }
}
