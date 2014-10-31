import 'package:unittest/unittest.dart';
import 'package:ddbc/ddbc.dart';

void main() {
  
  var sf = new SqlFormatter();

  group('Substitute by id', () {
    test('Substitute 1', () {
      var result = sf.substitute('@id', {'id': 20});
      expect(result, equals('20'));
    });

    test('Substitute 2', () {
      var result = sf.substitute('@id ', {'id': 20});
      expect(result, equals('20 '));
    });

    test('Substitute 3', () {
      var result = sf.substitute(' @id ', {'id': 20});
      expect(result, equals(' 20 '));
    });

    test('Substitute 4', () {
      var result = sf.substitute('@id@bob', {'id': 20, 'bob': 13});
      expect(result, equals('2013'));
    });

    test('Substitute 5', () {
      var result = sf.substitute('..@id..', {'id': 20});
      expect(result, equals('..20..'));
    });

    test('Substitute 6', () {
      var result = sf.substitute('...@id...', {'id': 20});
      expect(result, equals('...20...'));
    });

    test('Substitute 7', () {
      var result = sf.substitute('...@id.@bob...', {'id': 20, 'bob': 13});
      expect(result, equals('...20.13...'));
    });

    test('Substitute 8', () {
      var result = sf.substitute('...@id@bob', {'id': 20, 'bob': 13});
      expect(result, equals('...2013'));
    });

    test('Substitute 9', () {
      var result = sf.substitute('@id@bob...', {'id': 20, 'bob': 13});
      expect(result, equals('2013...'));
    });

//    test('Substitute 10', () {
//      var result = sf.substitute('@id:string', {'id': 20, 'bob': 13});
//      expect(result, equals("'20'"));
//    });

    test('Substitute 11', () {
      var result = sf.substitute('@blah_blah', {'blah_blah': 20});
      expect(result, equals("20"));
    });

    test('Substitute 12', () {
      var result = sf.substitute('@_blah_blah', {'_blah_blah': 20});
      expect(result, equals("20"));
    });
  });


  test('Format value', () {
    expect(sf.format('bob'), equals("'bob'"));
    expect(sf.format('bo\nb'), equals(r"'bo\nb'"));
    expect(sf.format('bo\rb'), equals(r"'bo\rb'"));
    expect(sf.format(r'bo\b'), equals(r"'bo\\b'"));

    expect(sf.format(r"'"), equals(r"'\''"));
    expect(sf.format(r" '' "), equals(r"' \'\' '"));
    expect(sf.format(r"\''"), equals(r"'\\\'\''"));
  });
  
  test('Format SQL', () {
    var sql = sf.substitute(
          'select @num, @num, @num, '
          '@int, @int, @int, '
          '@string, '
          '@datetime, @datetime:date, @datetime:timestamp, '
          '@boolean, @boolean_false, @boolean_null',
          { 
            'num': 1.2,
            'int': 3,
            'string': 'bob\njim',
            'datetime': new DateTime(2013, 1, 1),
            'boolean' : true,
            'boolean_false' : false,
            'boolean_null' : null,
          });
    expect(sql, r"select 1.2, 1.2, 1.2, 3, 3, 3, 'bob\njim', '2013-01-01 00:00:00', '2013-01-01', '2013-01-01 00:00:00', true, false, null");
  });

}