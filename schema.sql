
create table meta (
  id integer primary key autoincrement,
  name text,
  value text
);


insert into meta (name,value) values ('pie', 'cherry');
insert into meta (name,value) values ('cake', 'chocolate');
insert into meta (name,value) values ('pie', 'apple');
