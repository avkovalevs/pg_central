psql -c "create user repmgr with replication createdb createrole superuser encrypted password '{{ repmgrpass }}';" 
psql -c "create user pgpooler with superuser encrypted password '{{ pgpoolerpass }}';" 
psql -c 'alter user repmgr set search_path to repmgr, "$user", public;'
psql -c 'create database repmgr owner = repmgr;' 
psql -c "alter user postgres with password '{{ pgpass }}';"
