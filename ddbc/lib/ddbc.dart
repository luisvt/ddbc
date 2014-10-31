library ddbc;

import 'dart:async';
import 'dart:collection';

part 'exceptions.dart';
part 'sql_formatter.dart';

/**
 * Holds query results.
 * 
 * If the query was an insert statement, the id of the inserted row is in [insertId].
 * 
 * If the query was an update statement, the number of affected rows is in [affectedRows].
 * 
 * If the query was a select statement, the stream contains the row results and
 * the [fields] are also available.
 */
class Result {
  /**
   * The id of the inserted row, or [null] if no row was inserted.
   */
  int insertedId;

  /**
   * The number of affected rows in an update statement, or
   * [null] in other cases.
   */
  int affectedRows;

  /**
   * A list of the fields returned by the query.
   */
  List<String> columns;
  
  List<Row> rows;
}

/// Row allows field values to be retrieved as if they were getters.
///
///     conn.execute("select 'blah' as my_field")
///        .then((result) => 
///           result.rows.forEach((row) => print(row.my_field)));
///
@proxy
abstract class Row extends ListBase<dynamic> {}

abstract class ConnectionPool  {
  final String user;
  final String password;
  final String dbName;
  final String host;
  final int port;
  final int min;
  final int max;
  final int maxPacketSize;
  final bool useSSL;
  final int timeout;
  
  ConnectionPool(
    this.user,
    this.password,
    this.dbName,
    {
      this.host: '127.0.0.1',
      this.port,
      this.min: 2,
      this.max: 5,
      this.maxPacketSize: 16 * 1024 * 1024,
//      bool useCompression: false,
      this.useSSL: false,
      this.timeout
    }) ;
  
  /**
   * Prepares and executes the [sql] with the given Map or List of [parameters].
   * Returns a [Future]<[Result]> that completes when the query has been
   * executed. For example:
   * 
   *      var conn = new ConnectionPool(),
   *          query = SELECT * FROM person WHERE name = @name AND age = @age
   *      
   *      conn.execute(query, {'name': 'luis', 'age': 25})
   *          .then((result) {
   *              print(result.affectedRows);
   *              print(result.insertedIds);
   *              print(result.rows);
   *          });
   */
  Future<Result> execute(String sql, [parameters, bool transactional = false, bool consistent = true]);
}

abstract class Connection {

  final String userName;
  final String password;
  final String dbName;
  final String host;
  final int port;
  final int maxPacketSize;
  final bool useSSL;
  final int timeout;
  
  Connection(
    this.userName,
    this.password,
    this.dbName,
    {
      this.host: '127.0.0.1',
      this.port,
      this.maxPacketSize: 16 * 1024 * 1024,
//      bool useCompression: false,
      this.useSSL: false,
      this.timeout
    }) ;
  
  /**
   * Prepares and executes the [sql] with the given Map of named [parameters].
   * Returns a [Future]<[Result]> that completes when the query has been
   * executed. For example:
   * 
   *      var conn = new Connection(),
   *          query = SELECT * FROM person WHERE name = @name AND age = @age
   *      
   *      conn.execute(query, {'name': 'luis', 'age': 25})
   *          .then((result) {
   *              print(result.affectedRows);
   *              print(result.insertedIds);
   *              print(result.rows);
   *          });
   */
  Future<Result> execute(String sql, [parameters, bool transactional = false, bool consistent = true]);

  void close();
  
  Future<Connection> connect();
}
