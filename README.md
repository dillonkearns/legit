# Legit

[![Build Status](https://travis-ci.org/dillonkearns/legit.png)](https://travis-ci.org/dillonkearns/legit)
[![Coverage Status](https://coveralls.io/repos/dillonkearns/legit/badge.png?branch=master)](https://coveralls.io/r/dillonkearns/legit)
[![Gem Version](https://fury-badge.herokuapp.com/rb/legit.png)](http://badge.fury.io/rb/legit)
[![Dependency Status](https://gemnasium.com/dillonkearns/legit.png)](https://gemnasium.com/dillonkearns/legit)
[![Code Climate](https://codeclimate.com/github/dillonkearns/legit.png)](https://codeclimate.com/github/dillonkearns/legit)

## Installation
```bash
$ gem install legit
```

Requires ruby >= 1.9

## Usage
Run `legit` with no options to see a list of commands and options.

### legit checkout
Recommended alias: `lco`

Fuzzy git checkout

![legit checkout example](http://i.imgur.com/3RS02IB.png)

### Setting Up a `catch-todos` `pre-commit` Hook
![$ git up](http://i.imgur.com/rv0AfQi.png)

1. Add the following to `.git/hooks/pre-commit` in the desired repository:
```bash
#! /bin/bash
legit catch-todos TODO
```

2. Make the hook executable (git will silently ignore your hook otherwise):
```bash
chmod +x .git/hooks/pre-commit
```

Enable or disable catch-todos with the `--enable` and `--disable` options
```
legit catch-todos --disable     # will not check todos until re-enabled
legit catch-todos --enable      # sets it back to normal
```

Note: some graphical git tools may not run git hooks.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
