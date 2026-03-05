import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/navbar/navbar_bloc.dart';
import 'package:marketing/bloc/navbar/navbar_event.dart';
import 'package:marketing/bloc/navbar/navbar_state.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/services/auth_service.dart';
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
