drop table if exists cells;

create table cells (
  id bigint unsigned not null auto_increment,
  node_id bigint unsigned not null,
  child_node_id bigint unsigned,
  dimension_value varchar(4000) not null,
  facts varchar(255),
  all_cell int not null default 0,
  primary key(id, node_id)
) ENGINE=myisam
partition by hash(node_id)
partitions 10;

create index cells_node_id on cells (node_id);

drop table if exists nodes;

create table nodes (
    id bigint unsigned not null primary key auto_increment,
    level int not null,
    leaf int default 0,
    closed int default 0
) ENGINE=myisam
partition by hash(id)
partitions 10;