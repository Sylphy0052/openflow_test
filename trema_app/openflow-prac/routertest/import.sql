create table migrations (
       source_ip string,
       destination_ip string
);
create table clones(
       source_ip string,
       destination_ip string
);
create table load_balances(
       source_ip string,
       source_mac string,
       balance_ip string,
       balance_mac string
);
