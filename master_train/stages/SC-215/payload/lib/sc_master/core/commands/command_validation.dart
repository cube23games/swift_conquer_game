final class CommandValidation {
  final bool accepted;
  final String reason;

  const CommandValidation.accepted()
      : accepted = true,
        reason = '';

  const CommandValidation.rejected(this.reason) : accepted = false;
}

abstract interface class CommandValidator<T> {
  CommandValidation validate(T command);
}
