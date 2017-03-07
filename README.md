# Esquis

Esquis is a statically-typed programming language.

## Status

Pre-alpha. Everything may change.

## How to run

Prerequisites:

- Ruby >= 2.3
- Boehm GC (brew install boehmgc)
  - Tested with 7.6.0
  - Currently path of boehmgc is hard-coded in `lib/esquis.rb`,
    so you may need to edit the path.

```
$ bundle install
$ bundle exec esquis exec examples/a.es
$ bundle exec rake test
```

## Language spec (memo)

This is a memo of 'how esquis behaves now', not 'how esquis should behave'.

- lvar
  - It is not allowed to reassign to local variable
- stdlib
  - putd(n: Float) -> Void : print n as decimal number(%d)
  - putf(n: Float) -> Void : print n as flonum (%f)

## License

MIT

## Contact

https://github.com/yhara/esquis
