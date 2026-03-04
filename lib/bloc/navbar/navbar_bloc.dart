import 'package:flutter_bloc/flutter_bloc.dart';

import 'navbar_event.dart';
import 'navbar_state.dart';

class NavBarBloc extends Bloc<NavBarEvent, NavBarState> {
  NavBarBloc() : super(NavBarTabState(0)) {
    on<NavBarTabChanged>((event, emit) {
      emit(NavBarTabState(event.index));
    });
  }
}
