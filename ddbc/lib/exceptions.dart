part of ddbc;

/// A marker interface implemented by all postgresql library exceptions.
abstract class SqlException implements Exception {}

/// A exception caused by a problem within the postgresql library.
class SqlClientException implements SqlException {
  final String msg;
  final dynamic error;
  SqlClientException(this.msg, [this.error]);
}

/// A exception representing an error reported by the postgresql server.
abstract class SqlServerException implements SqlException, SqlServerInformation {

  final SqlServerInformation _info;
  SqlServerException(this._info);

  bool get isError => _info.isError;
  String get code => _info.code;
  String get severity => _info.severity;
  String get message => _info.message;
  String get detail => _info.detail;
  int get position => _info.position;
  String get allInformation => _info.allInformation;
}

/// Information returned from the server about an error or a notice.
abstract class SqlServerInformation {
  
  SqlServerInformation(this.isError, this.code, this.severity, this.message, this.detail, this.position, this.allInformation);

  /// Returns true if this is a server error, otherwise it is a notice.
  final bool isError;

  /// A PostgreSQL error code.
  /// See http://www.postgresql.org/docs/9.2/static/errcodes-appendix.html
  final String code;

  /// For a english localized database the field contents are ERROR, FATAL, or
  /// PANIC, for an error message. Otherwise in a notice message they are
  /// WARNING, NOTICE, DEBUG, INFO, or LOG.
  final String severity;

  /// A human readible error message, typically one line.
  final String message;

  /// More detailed information.
  final String detail;

  /// The position as an index into the original query string where the syntax
  /// error was found. The first character has index 1, and positions are
  /// measured in characters not bytes. If the server does not supply a
  /// position this field is null.
  final int position;

  /// All of the information returned from the server.
  final String allInformation;
}
