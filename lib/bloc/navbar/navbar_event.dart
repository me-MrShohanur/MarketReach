abstract class NavBarEvent {}

class NavBarTabChanged extends NavBarEvent {
  final int index;
  NavBarTabChanged(this.index);
}
