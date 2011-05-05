
-- Sqlite stores dates at text, real, or integer, depending on what we're doing.
-- http://www.sqlite.org/datatype3.html#datetime

-- user_id is only the remove_addr of a connection.

create table msg (
  id integer primary key autoincrement,
  user_id text,
  msg_text text
);
