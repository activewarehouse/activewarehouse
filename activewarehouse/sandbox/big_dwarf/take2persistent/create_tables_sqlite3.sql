drop table if exists cells;

create table cells (
  id integer primary key autoincrement not null,
  node_id integer not null,
  child_node_id integer,
  dimension_value text not null,
  facts text,
  all_cell integer not null default 0
);

create index cells_node_id on cells (node_id);

drop table if exists nodes;

create table nodes (
    id integer primary key autoincrement not null,
    level integer not null,
    leaf integer default 0,
    closed integer default 0
);