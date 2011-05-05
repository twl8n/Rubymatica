

create table puid_info (
       id integer primary key autoincrement,
       format_id int,
       format_name text,
       puid text,
       format_version text,
       format_mimetype text,
       rmatic_category text
);

