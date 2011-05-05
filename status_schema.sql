
-- Sqlite stores dates at text, real, or integer, depending on what we're doing.
-- http://www.sqlite.org/datatype3.html#datetime

create table status (
  id integer primary key autoincrement,
  uuid text,
  msg text,
  date text
);

create table meta (
  id integer primary key autoincrement,
  name text,
  value text
);
