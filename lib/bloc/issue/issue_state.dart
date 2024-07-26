part of 'issue_bloc.dart';

class IssueState {
  final int selectId;
  final List issues;

  IssueState({
    this.selectId = 0,
    this.issues = const [],
  });

  IssueState copyWith({
    int? selectId,
    List? issues = const [],
    Supabase? supabase
  }) =>
      IssueState(
        selectId: selectId ?? this.selectId, 
        issues: issues ?? this.issues,
      );
}

class IssueLoading extends IssueState {
  IssueLoading();
}

class IssueLoaded extends IssueState {
  final List issuesList;

  IssueLoaded(this.issuesList);
}

class IssueError extends IssueState {
  final String message;

  IssueError(this.message);
}

class IssueEdit extends IssueState {
  final int issueId;

  IssueEdit(this.issueId);
}