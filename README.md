# Esquis

Esquis is a statically-typed programming language.

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