import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'bloc_event.dart';
part 'bloc_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final SupabaseClient supabase;
  IssueBloc(this.supabase) : super(IssueState()) {
    on<EditIssue>((event, emit) => emit(state.copyWith(selectId: event.issueId)));

    on<ClearEdit>((event, emit) => emit(state.copyWith(selectId: 0)));
  }
}
