abstract class NavBarState {}

class NavBarTabState extends NavBarState {
  final int selectedIndex;
  NavBarTabState(this.selectedIndex);
}
