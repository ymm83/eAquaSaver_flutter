part of 'issue_bloc.dart';

abstract class IssueState extends Equatable {
  const IssueState();
  final int selectById=0; 
  @override
  List<Object> get props => [selectById];

  get issue => null;
}

class IssueLoading extends IssueState {}

class IssueSuccess extends IssueState {}

class IssueLoaded extends IssueState {
  final List issues;

  const IssueLoaded(this.issues);

  @override
  List<Object> get props => [issues];
}

class IssueError extends IssueState {
  final String message;

  const IssueError(this.message);

  @override
  List<Object> get props => [message];
}

class IssueDetail extends IssueState {
  final Map issue;

  const IssueDetail(this.issue);

  @override
  List<Object> get props => [issue];
}

class IssueSelected extends IssueState {
  final Issue issue;
     
  IssueSelected(this.issue);

  @override
  List<Object> get props => [issue];
}
