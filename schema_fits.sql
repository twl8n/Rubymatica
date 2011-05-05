-- Capture data from FITS XML file.

-- Track the current id manually as though we had a real sequence.
-- This is one record for each pk we want to track.
-- insert into pk (id,name) values (last_insert_rowid(),'file.id');
-- insert pk set id=last_insert_rowid() where name='file.id';
-- select id from pk where name='file.id';

-- We seem to only create a pk value for 'file.id' so I don't know why
-- this is generalized to creating pk values for other tables/fields.

create table pk (
       id int not null,
       name text not null
);

-- There is only one record here for each file. Other tables have one
-- or more records per file.

-- called file_core in rails

create table file (
       id integer primary key autoincrement,
       name text,
       size int,
       checksum text,
       fs_last_modified int,
       status text
);

-- There can be multiple identities per file. Even droid can have
-- multiple FileFormatHit's per file.

-- The element field is the xml element where we are getting this
-- identity info. The DROID id that we want is only from the
-- FileFormatHit element.

create table identity (
       id integer primary key autoincrement,
       file_id integer not null, -- fk to file.id
       element text, 
       tool_name text not null,
       format text,
       mime_type text,
       ext_id text,
       ext_type text,
       ext_version text,
       ext_tool text
);


-- A table of name-value pairs for things that FITS has discovered
-- about each file. May be multiple records with one record per
-- name/value pair.

-- Called file_extra in rails

create table info (
       id integer primary key autoincrement,
       file_id integer not null, -- fk to file.id
       tool_name text not null,
       name text,
       value text
);