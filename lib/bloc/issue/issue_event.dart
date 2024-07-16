part of 'issue_bloc.dart';

abstract class IssueEvent extends Equatable {
  const IssueEvent();

  @override
  List<Object> get props => [];
}

class LoadIssues extends IssueEvent {}


class AddIssue extends IssueEvent {
  final String summary;
  final String description;
  final int target;

  const AddIssue(this.summary, this.description, this.target,);

  @override
  List<Object> get props => [summary, description, target];
}

class DeleteIssue extends IssueEvent {
  final int id;

  const DeleteIssue(this.id);

  @override
  List<Object> get props => [id];
}

class EditIssue extends IssueEvent {
  final int id;
  final String summary;
  final String description;
  final int target;

  const EditIssue(this.id, this.summary, this.description, this.target);

  @override
  List<Object> get props => [id, summary, description, target];
}

class GetIssue extends IssueEvent {
  final int id;

  const GetIssue(this.id);

  @override
  List<Object> get props => [id];
}

class SelectIssueID extends IssueEvent {
  final Issue issue;

  SelectIssueID(this.issue);

  @override
  List<Object> get props => [issue];
}

class ClearSelectedIssueId extends IssueEvent {}