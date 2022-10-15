---
title: SQLite Gotchas
description: Things to keep in mind when using SQLite.
---

- Primary keys can be `NULL` [1].

    > According to the SQL standard, PRIMARY KEY should always imply NOT NULL.
    > Unfortunately, due to a bug in some early versions, this is not the case
    > in SQLite. Unless the column is an INTEGER PRIMARY KEY or the table is a
    > WITHOUT ROWID table or the column is declared NOT NULL, SQLite allows
    > NULL values in a PRIMARY KEY column.

- Data types are not enforced (unless using `STRICT`) [2].

    > The type affinity of a column is the recommended type for data stored in
    > that column. The important idea here is that the type is recommended, not
    > required. Any column can still store any type of data.

[1]: <https://sqlite.org/lang_createtable.html>
[2]: <https://sqlite.org/datatype3.html>
