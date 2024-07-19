part of 'bloc_bloc.dart';

@immutable
abstract class IssueEvent {}

class EditIssue extends IssueEvent {
  final int issueId;
  EditIssue(this.issueId);
}

class ClearEdit extends IssueEvent {}

class LoadIssues extends IssueEvent {}
