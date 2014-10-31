part of ddbc;

const int _a = 97;
const int _A = 65;
const int _z = 122;
const int _Z = 90;
const int _0 = 48;
const int _9 = 57;
const int _at = 64;
const int _colon = 58;
const int _underscore = 95;

const int _apos = 39;
const int _return = 13;
const int _newline = 10;
const int _backslash = 92;

final _escapeRegExp = new RegExp(r"['\r\n\\]");


typedef void _ValueWriterFunc(StringSink buf, String identifier, String type);

class SqlFormatter {
  String substitute(String source, values) {
    _ValueWriterFunc valueWriter;

    if (values is List) {
      valueWriter = _createListValueWriter(values);
    } else if (values is Map) {
      valueWriter = _createMapValueWriter(values);
    } else if (values == null) {
      valueWriter = (_, _1, _2) => throw new ParseException('Template contains a parameter, but no values were passed.');
    } else {
      throw new ArgumentError('Unexpected type.');
    }

    var buf = new StringBuffer();
    var s = new _Scanner(source);

    while (s.hasMore()) {
      var t = s.read();
      if (t.type == _TOKEN_IDENT) {
        valueWriter(buf, t.value, t.typeName);
      } else {
        buf.write(t.value);
      }
    }

    return buf.toString();
  }

  String format(value, [String type]) {
    err(rt, t) => new Exception('Invalid runtime type and type modifier combination ($rt to $t).');

    if (value is num || value is bool || value == null) {
      return value.toString(); //TODO test that corner cases of dart.toString() match postgresql number types.
    } else if (value is String) return _escape(value);


    if (value is DateTime) {
      //TODO check types.
      return _formatDateTime(value, type);
    }

    //if (value is List<int>)
    // return _formatBinary(value, type);

    throw new Exception('Unsupported runtime type as query parameter.');
  }

  _ValueWriterFunc _createListValueWriter(List list) => (StringSink buf, String identifier, String type) {

    int i = int.parse(identifier, onError: (_) => throw new ParseException('Expected integer parameter.'));

    if (i < 0 || i >= list.length) throw new ParseException('Substitution token out of range.');

    var s = format(list[i], type);
    buf.write(s);
  };

  _ValueWriterFunc _createMapValueWriter(Map map) => (StringSink buf, String identifier, String type) {

    var val;

    if (_isDigit(identifier.codeUnits.first)) {
      int i = int.parse(identifier, onError: (_) => throw new ParseException('Expected integer parameter.'));

      if (i < 0 || i >= map.values.length) throw new ParseException("Substitution token out of range.");

      val = map.values.elementAt(i);

    } else {

      if (!map.keys.contains(identifier)) throw new ParseException("Substitution token not passed: $identifier.");

      val = map[identifier];
    }

    var s = format(val, type);
    buf.write(s);
  };

}

//TODO test if this works without escaping unicode characters.
// Uses an string constant E''.
// See http://www.postgresql.org/docs/9.0/static/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS-ESCAPE
_escape(String s) {
  if (s == null) return ' null ';

  var escaped = s.replaceAllMapped(_escapeRegExp, (m) {
    switch (s.codeUnitAt(m.start)) {
      case _apos:
        return r"\'";
      case _return:
        return r'\r';
      case _newline:
        return r'\n';
      case _backslash:
        return r'\\';
      default:
        assert(false);
    }
  });

  return "'$escaped'";
}

_formatDateTime(DateTime datetime, [String type]) {

  if (datetime == null) return 'null';

  String escaped;
  var t = (type == null) ? 'timestamp' : type.toLowerCase();

  if (t != 'date' && t != 'timestamp' && t != 'timestamptz') {
    throw new Exception('Unexpected type: $type.'); //TODO exception type
  }

  pad(i) {
    var s = i.toString();
    return s.length == 1 ? '0$s' : s;
  }

  //2004-10-19 10:23:54.4455+02
  var sb = new StringBuffer()
      ..write(datetime.year)
      ..write('-')
      ..write(pad(datetime.month))
      ..write('-')
      ..write(pad(datetime.day));

  if (t == 'timestamp' || t == 'timestamptz') {
    sb
        ..write(' ')
        ..write(pad(datetime.hour))
        ..write(':')
        ..write(pad(datetime.minute))
        ..write(':')
        ..write(pad(datetime.second));

    final int ms = datetime.millisecond;
    if (ms != 0) {
      sb.write('.');
      final s = ms.toString();
      if (s.length == 1) sb.write('00'); else if (s.length == 2) sb.write('0');
      sb.write(s);
    }
  }

  if (t == 'timestamptz') {
    // Add timezone offset.
    throw new Exception('Not implemented'); //TODO
  }

  return "'${sb.toString()}'";
}


const int _TOKEN_TEXT = 1;
const int _TOKEN_AT = 2;
const int _TOKEN_IDENT = 3;

class _Token {
  _Token(this.type, this.value, [this.typeName]);
  final int type;
  final String value;
  final String typeName;
  String toString() => 'type: ${['?', 'Text', 'At', 'Ident'][type]}, value: "$value", typeName: "$typeName"';
}

bool _isIdentifier(int charCode) =>
    (charCode >= _a && charCode <= _z) || (charCode >= _A && charCode <= _Z) || (charCode >= _0 && charCode <= _9) || (charCode == _underscore);

bool _isAlphabetic(int charCode) =>
    (charCode >= _a && charCode <= _z) || (charCode >= _A && charCode <= _Z);

bool _isDigit(int charCode) =>
    (charCode >= _0 && charCode <= _9);

class ParseException {
  ParseException(this.message, [this.source, this.index]);
  final String message;
  final String source;
  final int index;
  String toString() => 
      (source == null || index == null) ? message : '$message At character: $index, in source "$source"';
}

//TODO
// See http://www.postgresql.org/docs/9.0/static/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS-ESCAPE
_formatBinary(List<int> buffer) {
  //var b64String = ...;
  //return " decode('$b64String', 'base64') ";
}

class _Scanner {
  _Scanner(String source)
      : _source = source,
        _r = new _CharReader(source) {

    if (_r.hasMore) _t = _read();
  }

  final String _source;
  final _CharReader _r;
  _Token _t;

  bool hasMore() {
//    _t = _read();
    return _t != null;
  }

  _Token peek() => _t;

  _Token read() {
    var t = _t;
    _t = _r.hasMore ? _read() : null;
    return t;
  }

  _Token _read() {

    assert(_r.hasMore);

    // '@@', '@ident', or '@ident:type'
    if (_r.current == _at) {
      _r.read();

      if (!_r.hasMore) throw new ParseException('Unexpected end of input.');

      // Escaped '@' character.
      if (_r.current == _at) {
        _r.read();
        return new _Token(_TOKEN_AT, '@');
      }

      if (!_isIdentifier(_r.current))
        throw new ParseException('Expected alphanumeric identifier character after "@".');

      // Identifier
      var ident = _r.readWhile(_isIdentifier);

      // Optional type modifier
      String type;
      if (_r.current == _colon) {
        _r.read();
        type = _r.readWhile(_isIdentifier);
      }
      return new _Token(_TOKEN_IDENT, ident, type);
    }

    // Read plain text
    var text = _r.readWhile((c) => c != _at);
    return new _Token(_TOKEN_TEXT, text);
  }
}

class _CharReader {
  _CharReader(String source)
      : _source = source,
        _itr = source.codeUnits.iterator {

    if (source == null) throw new ArgumentError('Source is null.');

    _i = 0;

    if (source != '') {
      _itr.moveNext();
      _c = _itr.current;
    }
  }

  String _source;
  Iterator<int> _itr;
  int _i, _c;

  bool get hasMore => _i < _source.length;

  int read() {
    var c = _c;
    _itr.moveNext();
    _i++;
    _c = _itr.current;
    return c;
  }

  int get current => _c;

  String readWhile([bool test(int charCode)]) {

    if (!hasMore) throw new ParseException('Unexpected end of input.', _source, _i);

    int start = _i;

    while (hasMore && test(current)) {
      read();
    }

    int end = hasMore ? _i : _source.length;
    return _source.substring(start, end);
  }
}
