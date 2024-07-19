import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'issue_event.dart';
part 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final Supabase supabase;
  //final String userid;

  IssueBloc() : super(IssueState()) {
    on<LoadIssues>(_onLoadIssues);
    on<AddIssue>(_onAddIssue);
    on<DeleteIssue>(_onDeleteIssue);
    on<EditIssue>(_onEditIssue);
    on<GetIssue>(_onGetIssue);
    on<SelectIssueID>(_onSelectIssueID);
  }

  void _onLoadIssues(LoadIssues event, Emitter<IssueState> emit) async {
    try {
      final data = await supabase.from('issue').select().eq('submitter', userid);
      emit(IssueLoaded(data));
    } catch (error) {
      emit(IssueError('Unexpected error occurred'));
    }
  }

  void _onAddIssue(AddIssue event, Emitter<IssueState> emit) async {
    try {
      final data = await supabase.from('issue').insert({
        'submitter': userid,
        'summary': event.summary,
        'description': event.description,
        'target': event.target == 1 ? 'app' : 'device'
      }).select();
      final issues = (state as IssueLoaded).issues;
      issues.add(data[0]);
      emit(IssueLoaded(issues));
    } catch (error) {
      emit(IssueError('Error: $error'));
    }
  }

  void _onDeleteIssue(DeleteIssue event, Emitter<IssueState> emit) async {
    try {
      final response = await supabase.from('issue').delete().eq('id', event.id).eq('status', 'new').select();
      if (response.length == 1) {
        final issues = (state as IssueLoaded).issues;
        issues.removeWhere((issue) => issue['id'] == event.id);
        emit(IssueLoaded(issues));
      } else {
        emit(IssueError('Error: no se pudo eliminar'));
      }
    } catch (error) {
      emit(IssueError('Error: $error'));
    }
  }

  void _onEditIssue(EditIssue event, Emitter<IssueState> emit) async {
    try {
      final data = await supabase
          .from('issue')
          .update({
            'summary': event.summary,
            'description': event.description,
            'target': event.target == 1 ? 'app' : 'device'
          })
          .eq('id', event.id)
          .select();
      final issues = (state as IssueLoaded).issues;
      final index = issues.indexWhere((issue) => issue['id'] == event.id);
      issues[index] = data[0];
      emit(IssueLoaded(issues));
    } catch (error) {
      emit(IssueError('Error: $error'));
    }
  }

  void _onGetIssue(GetIssue event, Emitter<IssueState> emit) async {
    try {
      final data = await supabase.from('issue').select().eq('id', event.id);
      if (data.isNotEmpty) {
        emit(IssueDetail(data[0]));
      } else {
        emit(IssueError('Issue not found'));
      }
    } catch (error) {
      emit(IssueError('Error: $error'));
    }
  }

  void _onSelectIssueID(SelectIssueID event, Emitter<IssueState> emit) {
    emit(state.copyWith(selectId: event.selectId));
  }

}
