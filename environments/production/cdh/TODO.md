# To Do:

## Hadoop

- Fix Oozie Server extjs install.
- Add hosts.exclude support for decommissioning nodes.
- Set default # map/reduce tasks automatically based on facter node stats.
- Handle ensure => absent
- Implement standalone yarn proxyserver support.
- Make log4j.properties more configurable.
- Make JMX ports configurable.
- Make hadoop-metrics2.properties more configurable.
- Support HA automatic failover.
- HA NameNode Fencing support.
- Create one variable for namenode address independent of nameservice_id and primary_namenode_host_
- Spark History Server?
- Impala documentation

## Zookeeper

Won't implement. A Zookeeper package is available upstream in Debian/Ubuntu.
Puppetization for this package can be found at
https://github.com/wikimedia/operations-puppet-zookeeper
