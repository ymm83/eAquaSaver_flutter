part of 'issue_bloc.dart';

class IssueState extends Equatable {
  final int selectId;
  IssueState({this.selectId = 0});

  @override
  List<Object> get props => [selectId];

  IssueState copyWith({
    int? selectId,
  }) {
    return IssueState(
      selectId: selectId ?? this.selectId,
  );
  }
}

class IssueLoading extends IssueState {
  IssueLoading();
}

class IssueSuccess extends IssueState {
  IssueSuccess();
}

class IssueLoaded extends IssueState {
  final List issues;

  IssueLoaded(this.issues);

  @override
  List<Object> get props => [issues];
}

class IssueError extends IssueState {
  final String message;

  IssueError(this.message);

  @override
  List<Object> get props => [message];
}

class IssueDetail extends IssueState {
  final Map issue;

  IssueDetail(this.issue);

  @override
  List<Object> get props => [issue];
}

class IssueSelected extends IssueState {
  final int id;
     
  IssueSelected(this.id):super(selectId: id);

  @override
  List<Object> get props => [id];
}