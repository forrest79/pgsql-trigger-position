# PostgreSQL - auto manage positions with a trigger

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/forrest79/pgsql-triggerposition/blob/master/LICENSE.md)
[![Build](https://github.com/forrest79/PgSQL-TriggerPosition/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/forrest79/PgSQL-TriggerPosition/actions/workflows/build.yml)

## How to use

TODO

## How it works

TODO

### Tests

```bash
PGPASSWORD=postgres tests/run-tests
```

### ToDo?

- add settings to group column not by its value, but just NULL/NOT NULL (can be solved with generated columns right now, it can be handy for columns like `deleted_datetime` - when `NULL` is for active records and timestamp is for deleted records - but with this, deleted record can't be sorted with `position` - every timestamp will have `position = 1`...)
