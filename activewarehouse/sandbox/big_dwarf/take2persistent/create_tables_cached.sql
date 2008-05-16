drop table if exists nodes;

create table nodes (
    id bigint unsigned not null primary key auto_increment,
    contents text
) ENGINE=myisam
partition by hash(id)
partitions 20;