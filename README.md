# Bats-core: Bash Automated Testing System (2018)

[![Latest release](https://img.shields.io/github/release/bats-core/bats-core.svg)](https://github.com/bats-core/bats-core/releases/latest)
[![npm package](https://img.shields.io/npm/v/bats.svg)](https://www.npmjs.com/package/bats)
[![License](https://img.shields.io/github/license/bats-core/bats-core.svg)](https://github.com/bats-core/bats-core/blob/master/LICENSE.md)
[![Continuous integration status for Linux and macOS](https://img.shields.io/travis/bats-core/bats-core/master.svg?label=travis%20build)](https://travis-ci.org/bats-core/bats-core)
[![Continuous integration status for Windows](https://img.shields.io/appveyor/ci/bats-core/bats-core/master.svg?label=appveyor%20build)](https://ci.appveyor.com/project/bats-core/bats-core)

[![Join the chat in bats-core/bats-core on gitter](https://badges.gitter.im/bats-core/bats-core.svg)][gitter]

Bats is a [TAP][]-compliant testing framework for Bash.  It provides a simple
way to verify that the UNIX programs you write behave as expected.

[TAP]: https://testanything.org

A Bats test file is a Bash script with special syntax for defining test cases.
Under the hood, each test case is just a function with a description.

```bash
#!/usr/bin/env bats

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}
```
