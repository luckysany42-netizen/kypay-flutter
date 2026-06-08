abstract class TopUpState {}

class TopUpInitial extends TopUpState {}

class TopUpMethodsLoading extends TopUpState {}

class TopUpMethodsLoaded extends TopUpState {
  final List<dynamic> methods;
  final Map<String, dynamic>? selectedMethod;
  TopUpMethodsLoaded({required this.methods, this.selectedMethod});
}

class TopUpMethodsError extends TopUpState {
  final String message;
  TopUpMethodsError(this.message);
}

class TopUpSubmitting extends TopUpState {
  final List<dynamic> methods;
  final Map<String, dynamic>? selectedMethod;
  TopUpSubmitting({required this.methods, this.selectedMethod});
}

class TopUpSuccess extends TopUpState {
  final String referenceNumber;
  final double amount;
  final String methodName;
  TopUpSuccess({
    required this.referenceNumber,
    required this.amount,
    required this.methodName,
  });
}

class TopUpError extends TopUpState {
  final String message;
  TopUpError(this.message);
}

/// Ada top up yang baru diapprove oleh admin
class TopUpApproved extends TopUpState {
  final double amount;
  final String methodName;
  final String referenceNumber;
  final String approvedAt;

  TopUpApproved({
    required this.amount,
    required this.methodName,
    required this.referenceNumber,
    required this.approvedAt,
  });
}

/// Ada top up yang ditolak oleh admin
class TopUpRejected extends TopUpState {
  final double amount;
  final String methodName;
  final String referenceNumber;
  final String adminNote;
  final String rejectedAt;

  TopUpRejected({
    required this.amount,
    required this.methodName,
    required this.referenceNumber,
    required this.adminNote,
    required this.rejectedAt,
  });
}