import 'package:flutter/material.dart';

class BottomNavigationTabItem {
  const BottomNavigationTabItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
}

const _kBlue = Color(0xFF1565C0);
const _kBlueLight = Color(0xFFE3F2FD);
const _kTextMid = Color(0xFF546E7A);

class UniYouthBottomNavigation extends StatelessWidget {
  const UniYouthBottomNavigation({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelectTab,
  }) : assert(tabs.length == 4, 'Bottom navigation requires exactly 4 tabs.');

  final List<BottomNavigationTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavigationTabButton(
                  tab: tabs[0],
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelectTab(0),
                ),
              ),
              Expanded(
                child: _BottomNavigationTabButton(
                  tab: tabs[1],
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelectTab(1),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: _BottomNavigationTabButton(
                  tab: tabs[2],
                  isSelected: selectedIndex == 2,
                  onTap: () => onSelectTab(2),
                ),
              ),
              Expanded(
                child: _BottomNavigationTabButton(
                  tab: tabs[3],
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelectTab(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationTabButton extends StatelessWidget {
  const _BottomNavigationTabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavigationTabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall;
    final Widget iconWidget;
    if (isSelected) {
      iconWidget = Container(
        key: ValueKey('active_${tab.label}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: _kBlueLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(tab.activeIcon, color: _kBlue, size: 22),
      );
    } else {
      iconWidget = Icon(
        tab.inactiveIcon,
        key: ValueKey('inactive_${tab.label}'),
        color: _kTextMid,
        size: 22,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: iconWidget,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: (textStyle ?? const TextStyle()).copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? _kBlue : _kTextMid,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}
