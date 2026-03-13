import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/navbar/navbar_bloc.dart';
import 'package:marketing/bloc/navbar/navbar_event.dart';
import 'package:marketing/bloc/navbar/navbar_state.dart';
import 'package:marketing/views/home/home_view.dart';

class NavigatorView extends StatelessWidget {
  const NavigatorView({super.key});

  final List<Widget> _pages = const [
    // LoginView(),
    HomeView(),
    Center(child: Text('Settings')),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavBarBloc(),
      child: BlocBuilder<NavBarBloc, NavBarState>(
        builder: (context, state) {
          final selectedIndex = (state as NavBarTabState).selectedIndex;
          return Scaffold(
            body: IndexedStack(index: selectedIndex, children: _pages),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) =>
                      context.read<NavBarBloc>().add(NavBarTabChanged(index)),
                  backgroundColor: Colors.white,
                  selectedItemColor: Colors.blueAccent,
                  unselectedItemColor: Colors.black45,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  elevation: 0,
                  items: [
                    _navBarItem(
                      imagePath: 'assets/icons/home.png',
                      label: 'Home',
                    ),
                    _navBarItem(
                      imagePath: 'assets/icons/order.png',
                      label: 'Orders',
                    ),
                    _navBarItem(
                      imagePath: 'assets/icons/setting.png',
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

BottomNavigationBarItem _navBarItem({
  required String imagePath,
  required String label,
}) {
  return BottomNavigationBarItem(
    icon: Image.asset(
      imagePath,
      width: 28,
      height: 28,
      color: Colors.black54,
      colorBlendMode: BlendMode.srcIn,
    ),
    activeIcon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        imagePath,
        width: 28,
        height: 28,
        color: Colors.blueAccent,
        colorBlendMode: BlendMode.srcIn,
      ),
    ),
    label: label,
  );
}

// class NavigatorView extends StatelessWidget {
//   const NavigatorView({super.key});

//   final List<Widget> _pages = const [
//     HomeView(),
//     Center(child: Text('Orders')),
//     Center(child: Text('Settings')),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => NavBarBloc(),
//       child: BlocBuilder<NavBarBloc, NavBarState>(
//         builder: (context, state) {
//           final selectedIndex = (state as NavBarTabState).selectedIndex;
//           return Scaffold(
//             backgroundColor: Colors.white,
//             body: IndexedStack(index: selectedIndex, children: _pages),
//             bottomNavigationBar: _FloatingNavBar(
//               selectedIndex: selectedIndex,
//               onTap: (index) =>
//                   context.read<NavBarBloc>().add(NavBarTabChanged(index)),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _FloatingNavBar extends StatelessWidget {
//   const _FloatingNavBar({
//     required this.selectedIndex,
//     required this.onTap,
//   });

//   final int selectedIndex;
//   final ValueChanged<int> onTap;

//   static const _items = [
//     _NavItem(imagePath: 'assets/icons/home.png', label: 'Home'),
//     _NavItem(imagePath: 'assets/icons/order.png', label: 'Orders'),
//     _NavItem(imagePath: 'assets/icons/setting.png', label: 'Settings'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
//         child: Container(
//           height: 68,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.10),
//                 blurRadius: 24,
//                 spreadRadius: 0,
//                 offset: const Offset(0, 8),
//               ),
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.05),
//                 blurRadius: 8,
//                 spreadRadius: 0,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(_items.length, (i) {
//               final isSelected = i == selectedIndex;
//               return _NavTile(
//                 item: _items[i],
//                 isSelected: isSelected,
//                 onTap: () => onTap(i),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavTile extends StatelessWidget {
//   const _NavTile({
//     required this.item,
//     required this.isSelected,
//     required this.onTap,
//   });

//   final _NavItem item;
//   final bool isSelected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: SizedBox(
//         width: 80,
//         height: 68,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               curve: Curves.easeInOut,
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? Colors.black.withValues(alpha: 0.08)
//                     : Colors.transparent,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Image.asset(
//                 item.imagePath,
//                 width: 22,
//                 height: 22,
//                 color: isSelected ? Colors.black : Colors.black38,
//                 colorBlendMode: BlendMode.srcIn,
//               ),
//             ),
//             const SizedBox(height: 3),
//             AnimatedDefaultTextStyle(
//               duration: const Duration(milliseconds: 200),
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight:
//                     isSelected ? FontWeight.w700 : FontWeight.w400,
//                 color: isSelected ? Colors.black : Colors.black38,
//                 letterSpacing: -0.1,
//               ),
//               child: Text(item.label),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NavItem {
//   const _NavItem({required this.imagePath, required this.label});
//   final String imagePath;
//   final String label;
// }
