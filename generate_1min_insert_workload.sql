select now();
create table t_random as select s, md5(random()::text) from generate_Series(1,5000000) s;
select now();
select pg_size_pretty(pg_total_relation_size('t_random'));
