import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';

/// States for the report generation flow.
sealed class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no report selected yet.
class ReportInitial extends ReportState {
  const ReportInitial();
}

/// Loading state — report is being generated.
class ReportLoading extends ReportState {
  const ReportLoading();
}

/// Success state — report PDF bytes and metadata are ready.
class ReportSuccess extends ReportState {
  final ReportResult result;

  const ReportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// Error state — report generation failed.
class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}
