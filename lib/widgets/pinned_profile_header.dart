import 'package:flutter/material.dart';

import 'profile_header_action.dart';

/// Compact pinned row; greetings, illustrations and data stay in the scroll body.
class PinnedProfileHeader extends StatelessWidget {
  const PinnedProfileHeader({
    super.key,
    required this.title,
    required this.onOpenProfile,
    this.isBrand = false,
    this.actionKey,
  });
  final Widget title;
  final VoidCallback onOpenProfile;
  final bool isBrand;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final height = isBrand
        ? 64.0
        : (MediaQuery.textScalerOf(context).scale(18) * 2.4 + 16).clamp(
            64.0,
            double.infinity,
          );
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        height: height,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF031B3B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ProfileHeaderAction(key: actionKey, onPressed: onOpenProfile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileHeaderDelegate({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: const Color(0xFFF8F9FA),
    elevation: overlapsContent ? 1 : 0,
    child: child,
  );
  @override
  bool shouldRebuild(_ProfileHeaderDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}
