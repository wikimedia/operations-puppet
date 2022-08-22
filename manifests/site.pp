# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp
# Base nodes

# Node definitions (alphabetic order)

# Ganeti VMs for acme-chief service
node 'acmechief1001.eqiad.wmnet' {
    role(acme_chief)
}

node 'acmechief2001.codfw.wmnet' {
    role(acme_chief)
}

# Ganeti VMs for acme-chief staging environment
node 'acmechief-test1001.eqiad.wmnet' {
    role(acme_chief)
}

node 'acmechief-test2001.codfw.wmnet' {
    role(acme_chief)
}

# The Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'an-master1001.eqiad.wmnet' {
    role(analytics_cluster::hadoop::master)
}

# The Hadoop (stanby) master node:
# - primary active NameNode
# - YARN ResourceManager
node 'an-master1002.eqiad.wmnet' {
    role(analytics_cluster::hadoop::standby)
}

node 'an-coord1001.eqiad.wmnet' {
    role(analytics_cluster::coordinator)
}

node 'an-coord1002.eqiad.wmnet' {
    role(analytics_cluster::coordinator::replica)
}

node /^an-db100[1-2]\.eqiad\.wmnet$/ {
    role(insetup)
}

node 'an-launcher1002.eqiad.wmnet' {
    role(analytics_cluster::launcher)
}

# Analytics Hadoop test cluster
node 'an-test-master1001.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::master)
}

node 'an-test-master1002.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::standby)
}

node /^an-test-worker100[1-3]\.eqiad\.wmnet$/ {
    role(analytics_test_cluster::hadoop::worker)
}

# new an-test-coord1001  T255518
node 'an-test-coord1001.eqiad.wmnet' {
    role(analytics_test_cluster::coordinator)
}

# new an-test-coord1002  T293938
node 'an-test-coord1002.eqiad.wmnet' {
    role(insetup)
}

node 'an-test-client1001.eqiad.wmnet' {
    role(analytics_test_cluster::client)
}

node 'an-test-ui1001.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::ui)
}

node 'an-test-presto1001.eqiad.wmnet' {
    role(analytics_test_cluster::presto::server)
}

# new an-worker hosts T293922
node /^an-worker114[2-8]\.eqiad\.wmnet$/ {
    role(insetup)
}

# analytics1058-analytics1077 and an-worker10XX
# are Analytics Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(5[89]|6[0-9]|7[0-7]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /an-worker10(7[89]|8[0-9]|9[0-9]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker11(0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[01])\.eqiad\.wmnet$/ {
    role(analytics_cluster::hadoop::worker)
}

# Staging environment of Superset and Turnilo
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo
node 'an-tool1005.eqiad.wmnet' {
    role(analytics_cluster::ui::superset::staging)
}

# turnilo.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot
node 'an-tool1007.eqiad.wmnet' {
    role(analytics_cluster::turnilo)
}

# yarn.wikimedia.org
node 'an-tool1008.eqiad.wmnet' {
    role(analytics_cluster::hadoop::yarn)
}

# hue.wikimedia.org
node 'an-tool1009.eqiad.wmnet' {
    role(analytics_cluster::hadoop::ui)
}

node 'an-tool1010.eqiad.wmnet' {
    role(analytics_cluster::ui::superset)
}

node 'an-tool1011.eqiad.wmnet' {
    role(analytics_cluster::turnilo::staging)
}

# analytics-search instance of Apache Airflow
node 'an-airflow1001.eqiad.wmnet' {
    role(search::airflow)
}

# analytics-research instance of Apache Airflow
node 'an-airflow1002.eqiad.wmnet' {
    role(analytics_cluster::airflow::research)
}

# [Deprecated] analytics-platform-eng instance of Apache Airflow
node 'an-airflow1003.eqiad.wmnet' {
    role(analytics_cluster::airflow::platform_eng_legacy)
}

# analytics-platform-eng instance of Apache Airflow to replace an-airflow1003
node 'an-airflow1004.eqiad.wmnet' {
    role(analytics_cluster::airflow::platform_eng)
}

# Analytics Zookepeer cluster
node /an-conf100[1-3]\.eqiad\.wmnet/ {
    role(analytics_cluster::zookeeper)
}

# Analytics Presto nodes.
node /^an-presto100[1-5]\.eqiad\.wmnet$/ {
    role(analytics_cluster::presto::server)
}

# New an-presto nodes in eqiad T306835
node /^an-presto10(0[6-9]|1[0-5])\.eqiad\.wmnet/ {
    role(insetup)
}

# Analytics Web Node.
node 'an-web1001.eqiad.wmnet' {
    role(analytics_cluster::webserver)
}

# API Feature Usage log pipeline procesors
node /^apifeatureusage[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(apifeatureusage::logstash)
}

# notification server for Phabricator (T257617)
node 'aphlict1001.eqiad.wmnet' {
    role(aphlict)
}

# new APT repositories (NOT DHCP/TFTP)
node /^apt[12]001\.wikimedia\.org/ {
    role(apt_repo)
}

# Analytics Query Service
node /aqs100[456789]\.eqiad\.wmnet/ {
    role(aqs)
}

# Analytics Query Service - buster+cassandra311
node /aqs101[0-5]\.eqiad\.wmnet/ {
    role(aqs_next)
}

# New aqs nodes in eqiad T305570
node /^aqs10(1[6-9]|2[0-1])\.eqiad\.wmnet/ {
    role(insetup)
}

# New aqs nodes in codfw T305568
node /^aqs200[1-9]|aqs201[0-2]\.codfw\.wmnet/ {
    role(aqs_next)
}

# New Archiva host on Buster
# T254890
node 'archiva1002.wikimedia.org' {
    role(archiva)
}

node /^authdns[12]001\.wikimedia\.org$/ {
    role(dns::auth)
}

# Primary bacula director and storage daemon
node 'backup1001.eqiad.wmnet' {
    role(backup)
}
# eqiad backup generation for External Storage databases
node 'backup1002.eqiad.wmnet' {
    role(dbbackups::content)
}

# eqiad bacula storage for External Storage databases
node 'backup1003.eqiad.wmnet' {
    role(backup::es)
}

# eqiad media backup storage
node /^backup100[4567]\.eqiad\.wmnet$/ {
    role(mediabackup::storage)
}

# new backup storage eqiad T294974
node 'backup1008.eqiad.wmnet' {
    role(insetup)
}

# new backup storage eqiad T307048
node 'backup1009.eqiad.wmnet' {
    role(insetup)
}

# codfw storage daemon
node 'backup2001.codfw.wmnet' {
    role(backup::offsite)
}
# codfw backup generation for External Storage databases
node 'backup2002.codfw.wmnet' {
    role(dbbackups::content)
}

# codfw bacula for External Storage DBs
node 'backup2003.codfw.wmnet' {
    role(backup::es)
}

# codfw media backup storage
node /^backup200[4567]\.codfw\.wmnet$/ {
    role(mediabackup::storage)
}
# New backup node for codfw T294973
node 'backup2008.codfw.wmnet' {
    role(insetup)
}

# New backup node for codfw T307049
node 'backup2009.codfw.wmnet' {
    role(insetup)
}

node 'backupmon1001.eqiad.wmnet' {
    role(dbbackups::monitoring)
}

# New bastion in Virginia T276396
node 'bast1003.wikimedia.org' {
    role(bastionhost)
}

# Bastion in Texas - (T196665, replaced bast2001)
node 'bast2002.wikimedia.org' {
    role(bastionhost)
}

# To be repurposed, T257324
node 'bast3004.wikimedia.org' {
    role(spare::system)
}

# esams/bastion on Ganeti
node 'bast3005.wikimedia.org' {
    role(bastionhost)
}

# To be repurposed, T257324
node 'bast4002.wikimedia.org' {
    role(spare::system)
}

# ulsfo/bastion on Ganeti
node 'bast4003.wikimedia.org' {
    role(bastionhost)
}

# To be repurposed, T257324
node 'bast5001.wikimedia.org' {
    role(spare::system)
}

# eqsin/bastion on Ganeti
node 'bast5002.wikimedia.org' {
    role(bastionhost)
}

# drmrs/bastion on Ganeti
node 'bast6001.wikimedia.org' {
    role(bastionhost)
}

# Debian package/docker images building host in production
node 'build2001.codfw.wmnet' {
    role(builder)
}

node 'centrallog1001.eqiad.wmnet', 'centrallog2002.codfw.wmnet' {
    role(syslog::centralserver)
}

node 'centrallog2001.codfw.wmnet' {
    role(spare::system)
}

node /^chartmuseum[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(chartmuseum)
}

node /^cloudgw100[12]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::cloudgw)
}

node /^cloudgw200[12]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::cloudgw)
}

# New cloudgw node T306854
node 'cloudgw2003-dev.codfw.wmnet' {
    role(insetup)
}

node /^cloudcephosd200[123]-dev\.codfw\.wmnet/ {
    role(wmcs::ceph::osd)
}

node /^cloudcephmon200[2-3]-dev\.codfw\.wmnet$/ {
    role(spare::system)
}

node /^cloudcephmon200[4-6]-dev\.codfw\.wmnet$/ {
    role(wmcs::ceph::mon)
}

# new dumps hosts T302981
node /^clouddumps100[12]\.wikimedia\.org/ {
    role(dumps::distribution::server)
}

# All gerrit servers (swap master status in hiera)
node 'gerrit1001.wikimedia.org', 'gerrit2002.wikimedia.org' {
    role(gerrit)
}

# Zookeeper and Etcd discovery service nodes
node /^conf200[456]\.codfw\.wmnet$/ {
    role(configcluster)
}

node /^conf100[789]\.eqiad\.wmnet$/ {
    role(configcluster)
}

# Test zookeeper in eqiad
node 'zookeeper-test1002.eqiad.wmnet' {
    role(zookeeper::test)
}

# Test kafka cluster
node /^kafka-test10(10|0[6-9])\.eqiad\.wmnet/ {
    role(kafka::test::broker)
}

# CI master / CI standby (switch in Hiera)
node /^(contint1001|contint2001)\.wikimedia\.org$/ {
    role(ci::master)
}
# New contint and gerrit node T299575
node /^(contint2002)\.wikimedia\.org$/ {
    role(insetup)

}

# HAproxy test T290005
node /^cp10(7[579]|8[13579])\.eqiad\.wmnet$/ {
    role(cache::text_haproxy)
}

# HAProxy test T290005
node /^cp10(7[68]|8[02468]|90)\.eqiad\.wmnet$/ {
    role(cache::upload_haproxy)
}

# HAProxy test T290005
node /^cp20(2[79]|3[13579]|41)\.codfw\.wmnet$/ {
    role(cache::text_haproxy)
}

# HAProxy test T290005
node /^cp20(28|3[02468]|4[02])\.codfw\.wmnet$/ {
    role(cache::upload_haproxy)
}

#
# esams caches
#

# HAProxy test - T290005
node /^cp30(5[02468]|6[024])\.esams\.wmnet$/ {
    role(cache::text_haproxy)
}

# HAProxy test T290005
node /^cp30(5[13579]|6[135])\.esams\.wmnet$/ {
    role(cache::upload_haproxy)
}

#
# ulsfo caches
#

# HAProxy test
node /^cp40(2[1-6]|3[34])\.ulsfo\.wmnet$/ {
    role(cache::upload_haproxy)
}

# HAProxy test - T290005
node /^cp40(2[789]|3[0256])\.ulsfo.wmnet$/ {
    role(cache::text_haproxy)
}

#
# eqsin caches
#

# HAProxy test T290005
node /^cp50(0[123456]|1[34])\.eqsin\.wmnet$/ {
    role(cache::upload_haproxy)
}

# HAProxy test - T290005
node /^cp50(0[7-9]|1[01256])\.eqsin\.wmnet$/ {
    role(cache::text_haproxy)
}

#
# cp drmrs nodes
#

# HAProxy test T290005
node /^cp600[1-8]\.drmrs\.wmnet$/ {
    role(cache::upload_haproxy)
}

# HAProxy test T290005
node /^cp60(09|1[0-6])\.drmrs\.wmnet$/ {
    role(cache::text_haproxy)
}

node 'cumin1001.eqiad.wmnet' {
    role(cluster::management)
}

node 'cumin2002.codfw.wmnet' {
    role(cluster::management)
}

node 'cuminunpriv1001.eqiad.wmnet' {
    role(cluster::unprivmanagement)
}

node /^datahubsearch100[1-3]\.eqiad\.wmnet$/ {
    role(analytics_cluster::datahub::opensearch)
}

# MariaDB 10
# new db servers T306928
node /^db11(8[5-9]|9[0-4]).eqiad.wmnet$/ {
    role(insetup)
}

# s1 (enwiki) core production dbs on eqiad
# See also db1099 and db1105 below
# db1132 is a testing mariadb 10.6 host T303395
node /^db1(118|119|128|132|134|135|163|169|184)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1106.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
# See also db2167 and db2170 below
node /^db2(103|112|116|130|145|146|153|174|176)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2173.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on eqiad
# See also db1105, db1146, db1170 below
node /^db1(122|129|162|182)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1156.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
# See also db2170 and db2138 below
node /^db2(104|107|125|148|175)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2126.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on eqiad
node /^db1(123|157|166|175|179)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1112.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on codfw
node /^db2(105|109|127|149|177)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2156.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s4 (commons) core production dbs on eqiad
# See also db1144 and db1146 below
node /^db1(138|141|142|143|147|148|149|160)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1121.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# Testing cluster
# Testing master
node 'db1124.eqiad.wmnet' {
    role(mariadb::core_test)
}

# Testing replica
node 'db1125.eqiad.wmnet' {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
# See also db2137 and db2138 below
node /^db2(106|110|119|136|147|172|179)\.codfw\.wmnet/ {
    role(mariadb::core)
}
# replacement codfw master T252985
node 'db2140.codfw.wmnet' {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2155.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on eqiad
# See also db1096, db1113 and db1144 below
node /^db1(100|110|130)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1161.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
# See also db2171 and db2137 below
node /^db2(111|113|123|157|178)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2128.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s6 (frwiki, jawiki, ruwiki) core production dbs on eqiad
# See also db1096, db1098 and db1113 below
node /^db1(131|168|173|180)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1165.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s6 core production dbs on codfw
# See also db2169 and db2171 below
node /^db2(114|117|124|129|180)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2158.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# See also db1098, db1101, db1170 below
node /^db1(069|127|136|174|178|181)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1158.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# See also db2168 and db2169 below
node /^db2(108|118|120|121|122|150|182)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2159.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on eqiad
# See also db1099 and db1101 below
node /^db1(104|109|111|114|126|172|177)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1167.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on codfw
# See also db2167 db2168 below
node /^db2(152|154|161|162|163|165|166|181)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2164.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# multi-instance hosts with multiple shards
node /^db1(096|098|099|101|105|113|144|146|170)\.eqiad\.wmnet/ {
    role(mariadb::core_multiinstance)
}
node /^db2(137|138|167|168|169|170|171)\.codfw\.wmnet/ {
    role(mariadb::core_multiinstance)
}

## x1 shard
# eqiad
node /^db1(103|120|137)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# codfw
node /^db2(096|115|131)\.codfw\.wmnet/ {
    role(mariadb::core)
}



# x2 shard
# eqiad
node /^db11(51|52|53)\.eqiad\.wmnet$/ {
    role(mariadb::objectstash)
}

# codfw
node /^db21(42|43|44)\.codfw\.wmnet$/ {
    role(mariadb::objectstash)
}

## m1 shard
# See also multiinstance misc hosts db1117, db2160 below

# m1 master T309286
node 'db1164.eqiad.wmnet' {
    role(mariadb::misc)
}

# Future m1 master T315856
node 'db1195.eqiad.wmnet' {
    role(mariadb::misc)
}

# m1 codfw master
node 'db2132.codfw.wmnet' {
    role(mariadb::misc)
}

## m2 shard
# See also multiinstance misc hosts db1117, db2160 below

# m2 eqiad master
node 'db1159.eqiad.wmnet' {
    role(mariadb::misc)
}

# m2 codfw master
node 'db2133.codfw.wmnet' {
    role(mariadb::misc)
}

## m3 shard
# See also multiinstance misc hosts db1117, db2160 below

# m3 master
node 'db1183.eqiad.wmnet' {
    role(mariadb::misc::phabricator)
}

# m3 codfw master
node 'db2134.codfw.wmnet' {
    role(mariadb::misc::phabricator)
}

## Analytics Backup Multi-instance
node 'db1108.eqiad.wmnet' {
    role(mariadb::misc::analytics::backup)
}

## m5 shard
# See also multiinstance misc hosts db1117, db2160 below

# m5 eqiad master T301654
node 'db1107.eqiad.wmnet' {
    role(mariadb::misc)
}

# m5 codfw master
node 'db2135.codfw.wmnet' {
    role(mariadb::misc)
}

# misc multiinstance
node 'db1117.eqiad.wmnet' {
    role(mariadb::misc::multiinstance)
}
node 'db2160.codfw.wmnet' {
    role(mariadb::misc::multiinstance)
}

# sanitarium hosts
node /^db1(154|155)\.eqiad\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

node /^db2(094|095)\.codfw\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

# zarcillo master
node 'db1115.eqiad.wmnet' {
    role(mariadb::misc::db_inventory)
}

# zarcillo slave
node 'db2093.codfw.wmnet' {
    role(mariadb::misc::db_inventory)
}

# Orchestrator central node (VM on ganeti)
node 'dborch1001.wikimedia.org' {
    role(orchestrator)
}

# temporary misc hosts for media backups
node 'db1176.eqiad.wmnet' {
    role(mariadb::misc)
}
node 'db2151.codfw.wmnet' {
    role(mariadb::misc)
}

# eqiad backup sources
## s2, s3 & x1, buster
node 'db1102.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s8 & x1, buster
node 'db1116.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s1 & s2, buster
node 'db1139.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s1 & s6, buster
node 'db1140.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s4 & s3, buster
node 'db1145.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s4 & s5, buster
node 'db1150.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s7 & s8, buster
node 'db1171.eqiad.wmnet' {
    role(mariadb::backup_source)
}

# codfw backup sources
## s1, buster
node 'db2097.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s7 & s8, buster
node 'db2098.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s4, buster
node 'db2099.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s8, buster
node 'db2100.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s2, s5, & x1, buster
node 'db2101.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s3 & s4, buster
node 'db2139.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s1 & s6, buster
node 'db2141.codfw.wmnet' {
    role(mariadb::backup_source)
}

# backup testing hosts
node 'db1133.eqiad.wmnet' {
    role(mariadb::core_test)
}

node 'db2102.codfw.wmnet' {
    role(mariadb::core_test)
}

# Analytics production replicas
node /^dbstore100([3-5]|7)\.eqiad\.wmnet$/ {
    role(mariadb::analytics_replica)
}

# database-provisioning and short-term/postprocessing backups servers

node 'dbprov1001.eqiad.wmnet' {
    role(dbbackups::metadata)
}
node 'dbprov1002.eqiad.wmnet' {
    role(dbbackups::metadata)
}
node 'dbprov1003.eqiad.wmnet' {
    role(dbbackups::metadata)
}
node 'dbprov2001.codfw.wmnet' {
    role(dbbackups::metadata)
}
node 'dbprov2002.codfw.wmnet' {
    role(dbbackups::metadata)
}
node 'dbprov2003.codfw.wmnet' {
    role(dbbackups::metadata)
}
# Active eqiad proxies for misc databases
node /^dbproxy10(12|13|14|15|16|17|20|21)\.eqiad\.wmnet$/ {
    role(mariadb::proxy::master)
}

# Passive codfw proxies for misc databases
node /^dbproxy20(01|02|03|04)\.codfw\.wmnet$/ {
    role(mariadb::proxy::master)
}


# clouddb proxies (controling replica service dbs)
# analytics proxy
node 'dbproxy1018.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}

# web proxy
node 'dbproxy1019.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}

node /^debmonitor[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(debmonitor::server)
}

node /^dns[123456]00[12]\.wikimedia\.org$/ {
    role(dnsbox)
}


# backends for https://doc.wikimedia.org (T211974) on buster (T247653)
node 'doc1002.eqiad.wmnet', 'doc2001.codfw.wmnet' {
    role(doc)
}

# Wikidough (T252132)
node /^(doh[123456]00[12])\.wikimedia\.org$/ {
    role(wikidough)
}

# durum for Wikidough (T289536)
node /^durum[123456]00[12]\.(eqiad|codfw|esams|ulsfo|eqsin|drmrs)\.wmnet$/ {
    role(durum)
}

# Dragonfly Supernode (T286054)
node /^dragonfly-supernode[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(dragonfly::supernode)
}

# Druid analytics-eqiad (non public) servers.
# These power internal backends and queries.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^an-druid100[1-5]\.eqiad\.wmnet$/ {
    role(druid::analytics::worker)
}

node /^an-test-druid1001\.eqiad\.wmnet$/ {
    role(druid::test_analytics::worker)
}

# Druid public-eqiad servers.
# These power AQS and wikistats 2.0 and contain non sensitive datasets.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[4-8]\.eqiad\.wmnet$/ {
    role(druid::public::worker)
}

# new dse-k8s-crtl control plane servers T310171
node /^dse-k8s-ctrl100[12]\.eqiad\.wmnet$/ {
    role(dse_k8s::master)
}

# new dse-k8s-etcd etcd cluster servers T310170
node /^dse-k8s-etcd100[1-3]\.eqiad\.wmnet$/ {
    role(etcd::v3::dse_k8s_etcd)
}

# new dse-k8s-workers T29157 and T3074009
node /^dse-k8s-worker100[1-8]\.eqiad\.wmnet$/ {
    role(dse_k8s::worker)
}


# nfs server for xml dumps generation, also rsyncs xml dumps
# data to fallback nfs server(s)
node /^dumpsdata1003\.eqiad\.wmnet$/ {
    role(dumps::generation::server::xmldumps)
}

# nfs server for misc dumps generation, also rsyncs misc dumps
node /^dumpsdata1002\.eqiad\.wmnet$/ {
    role(dumps::generation::server::misccrons)
}

# fallback nfs server for dumps generation, also
# will rsync data to web servers
node /^dumpsdata1001\.eqiad\.wmnet$/ {
    role(dumps::generation::server::xmlfallback)
}
# new dumpsdata servers T283290
node /^dumpsdata100[4-5]\.eqiad\.wmnet/ {
    role(insetup)
}

node /^dumpsdata100[67]\.eqiad\.wmnet$/ {
    role(insetup)
}

node /^elastic104[8-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic105[0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic106[0-7]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

# new elastic servers T281989
node /^(elastic106[8-9]|elastic107[0-9]|elastic108[0-3])\.eqiad\.wmnet$/ {
    role(elasticsearch::cirrus)
}

# new elastic servers T291655 and T299609
node /^(elastic108[4-9]|elastic109[0-9]|elastic110[0-2])\.eqiad\.wmnet$/ {
    role(elasticsearch::cirrus)
}

node /^elastic202[5-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node 'elastic2049.codfw.wmnet' {
    role(spare::system)
}

node /^elastic203[0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic204[0-8]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic205[0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node 'elastic2060.codfw.wmnet' {
    role(elasticsearch::cirrus)
}

# new codfw refresh servers T300943
node /^(elastic206[1-9]|elastic207[0-2])\.codfw\.wmnet$/ {
    role(elasticsearch::cirrus)
}

# new codfw elastic servers T300943
node /^(elastic207[3-9]|elastic208[0-6])\.codfw\.wmnet$/ {
    role(insetup)
}

# new eqiad row e-f elastic servers T299609
node /^(elastic1089|elastic109[0-9]|elastic110[0-2])\.eqiad\.wmnet$/ {
    role(insetup)
}

# External Storage, Shard 1 (es1) databases

## eqiad servers
node 'es1027.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1029.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1032.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
# es2028
node 'es2028.codfw.wmnet' {
    role(mariadb::core)
}

# es2030
node 'es2030.codfw.wmnet' {
    role(mariadb::core)
}

# es2032
node 'es2032.codfw.wmnet' {
    role(mariadb::core)
}


# External Storage, Shard 2 (es2) databases

## eqiad servers
node 'es1026.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1030.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1033.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
node 'es2026.codfw.wmnet' {
    role(mariadb::core)
}

## es2031
node 'es2031.codfw.wmnet' {
    role(mariadb::core)
}

## es2033
node 'es2033.codfw.wmnet' {
    role(mariadb::core)
}

# External Storage, Shard 3 (es3) databases

## eqiad servers
node 'es1028.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1031.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1034.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
# es2027
node 'es2027.codfw.wmnet' {
    role(mariadb::core)
}

# es2029
node 'es2029.codfw.wmnet' {
    role(mariadb::core)
}

# es2034
node 'es2034.codfw.wmnet' {
    role(mariadb::core)
}

# External Storage, Shard 4 (es4) databases
## eqiad servers
node 'es1020.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1021.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1022.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
node 'es2021.codfw.wmnet' {
    role(mariadb::core)
}

node /^es202[02]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# External Storage, Shard 5 (es5) databases
## eqiad servers
node /^es102[345]\.eqiad\.wmnet/ {
    role(mariadb::core)
}

## codfw servers

node /^es202[345]\.codfw\.wmnet/ {
    role(mariadb::core)
}

node /^failoid[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(failoid)
}

# 9 expansion hosts T273566
# Set them to spare individually as it will take take to transfer the data
node /^db11(76)\.eqiad\.wmnet$/ {
    role(insetup)
}

# Backup system, see T176505.
# This is a reserved system. Ask Otto or Faidon.
node 'flerovium.eqiad.wmnet' {
    role(analytics_cluster::hadoop::client)
}

node 'flowspec1001.eqiad.wmnet' {
    role(flowspec)
}

# Backup system, see T176506.
# This is a reserved system. Ask Otto or Faidon.
node 'furud.codfw.wmnet' {
    role(analytics_cluster::hadoop::client)
}

# Etcd clusters for kubernetes, v3
node /^kubetcd[12]00[456]\.(eqiad|codfw)\.wmnet$/ {
    role(etcd::v3::kubernetes)
}

# Etcd cluster for kubernetes staging, v3
node /^kubestagetcd100[456]\.eqiad\.wmnet$/ {
    role(etcd::v3::kubernetes::staging)
}

# etc cluster for kubernetes staging, v3, codfw
node /^kubestagetcd200[123]\.codfw\.wmnet$/ {
    role(etcd::v3::kubernetes::staging)
}

# kubernetes master for staging
node /^kubestagemaster[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(kubernetes::staging::master)
}

# kubernetes masters
node /^kubemaster[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(kubernetes::master)
}


# Etherpad on bullseye (virtual machine) (T300568)
node 'etherpad1003.eqiad.wmnet' {
    role(etherpad)
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node 'eventlog1003.eqiad.wmnet' {
    role(eventlogging::analytics)
}

# virtual machine for mailman list server
node 'lists1001.wikimedia.org' {
    role(lists)
}

# new ganeti servers T299459
node /^ganeti10(2[9]|3[0-2])\.eqiad\.wmnet$/ {
    role(insetup)
}

node /^ganeti10(0[5-9]|1[0-9]|2[0-8])\.eqiad\.wmnet$/ {
    role(ganeti)
}

node /^ganeti20(09|1[0-9]|2[0-9]|30)\.codfw\.wmnet$/ {
    role(ganeti)
}

# Ganeti test cluster
node /^ganeti-test200[123]\.codfw\.wmnet/ {
    role(ganeti_test)
}

node /^ganeti300[123]\.esams\.wmnet$/ {
    role(ganeti)
}

node /^ganeti400[1234]\.ulsfo\.wmnet$/ {
    role(ganeti)
}

node /^ganeti500[123]\.eqsin\.wmnet$/ {
    role(ganeti)
}

node /^ganeti600[1234]\.drmrs\.wmnet$/ {
    role(ganeti)
}

# gitlab servers - eqiad (T274459, T301177)
node 'gitlab1003.wikimedia.org' {
    role(gitlab)
}

node 'gitlab1004.wikimedia.org' {
    role(gitlab)
}

# gitlab runners - eqiad (T301177)
node /^gitlab-runner100[234]\.eqiad\.wmnet$/ {
    role(gitlab_runner)
}


# gitlab servers - codfw (T301183, T285867)
node 'gitlab2002.wikimedia.org' {
    role(gitlab)
}

node /^gitlab2003\.wikimedia\.org$/ {
    role(insetup)
}

# gitlab runners - codfw (T3011183)
node /^gitlab-runner200[234]\.codfw\.wmnet$/ {
    role(gitlab_runner)
}

# Virtual machines for Grafana 6.x (T220838, T244357)
node 'grafana1002.eqiad.wmnet' {
    role(grafana)
}

node 'grafana2001.codfw.wmnet' {
    role(grafana)
}

# Serves dumps of revision content from restbase, in HTML format
# T245567 - replaced francium.eqiad.wmnet
node 'htmldumper1001.eqiad.wmnet' {
    role(dumps::web::htmldumps)
}

# irc.w.o failover host in eqiad
node 'irc1001.wikimedia.org' {
    role(mw_rc_irc)
}

# Replacement of irc.wikimedia.org
# see T232483
node 'irc2001.wikimedia.org' {
    role(mw_rc_irc)
}

# cloudservices1003/1004 hosts openstack-designate
# and the powerdns auth and recursive services for instances in eqiad1.
node /^cloudservices100[34]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::services)
}

#new cloudweb hosts T305414
node /^cloudweb100[34]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::labweb)
}

node 'cloudweb2002-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::cloudweb)
}

node /^cloudnet200[5-6]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::net)
}

node 'clouddb2001-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::db)
}

# New clouddb node T306854
node 'clouddb2002-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::db)
}

node /^cloudcontrol200[145]-dev\.wikimedia\.org/ {
    role(wmcs::openstack::codfw1dev::control)
}

# cloudrabbit servers T304888
node /^cloudrabbit100[123]\.wikimedia\.org/ {
    role(wmcs::openstack::eqiad1::rabbitmq)
}

# new cloudservices1005 node T304888
node 'cloudservices1005.wikimedia.org' {
    role(insetup)
}

node /^cloudservices200[4-5]-dev\.wikimedia\.org$/ {
    role(wmcs::openstack::codfw1dev::services)
}

# Primary graphite host
node 'graphite1004.eqiad.wmnet' {
    role(graphite::production)
    # TODO: move the roles below to ::role::alerting::host
    include ::role::graphite::alerts
    include ::role::elasticsearch::alerts
}

# Standby graphite host
node 'graphite2003.codfw.wmnet' {
    role(graphite::production)
}

# New graphite host T313851
node 'graphite2004.codfw.wmnet' {
    role(insetup)
}

node /^idp[12]002\.wikimedia\.org$/ {
    role(idp)
}

node /^idp-test[12]002\.wikimedia\.org$/ {
    role(idp_test)
}

# TFTP/DHCP/webproxy but NOT APT repo (T224576)
node /^install[12]003\.wikimedia\.org$/ {
    role(installserver::light)
}

# new install servers in POPs (T254157, T252526, T242602)
node /^install[3456]001\.wikimedia\.org$/ {
    role(installserver::light)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T255072, T255070)
node /^alert[12]001\.wikimedia\.org$/ {
    role(alerting_host)
}


# Phabricator
node /^phab[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(phabricator)
}

# Phabricator - new hardware (T280540, T279176)
node 'phab1004.eqiad.wmnet' {
    role(phabricator::migration)
}

# Phabricator - new hardware (T280544, T279177)
node 'phab2002.codfw.wmnet' {
    role(phabricator)
}

# PKI server
node /^pki[12]001\.(eqiad|codfw)\.wmnet/ {
    role(pki::multirootca)
}

# New pki node # T305489
node 'pki2002.codfw.wmnet' {
    role(insetup)
}

# pki-root server T276625
node 'pki-root1001.eqiad.wmnet' {
    role(pki::root)
}

node /kafka-logging100[123]\.eqiad\.wmnet/ {
    role(kafka::logging)
}

node /^kafka-logging200[123]\.codfw\.wmnet/ {
    role(kafka::logging)
}

# New kafka node T313959
node /^kafka-logging200[45]\.codfw\.wmnet/ {
    role(insetup)
}

node /kafka-main100[1-5]\.eqiad\.wmnet/ {
    role(kafka::main)
}

node /kafka-main200[1-5]\.codfw\.wmnet/ {
    role(kafka::main)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo100[1-9]\.eqiad\.wmnet$/ {
    role(kafka::jumbo::broker)
}

# Kafka Burrow Consumer lag monitoring (T187901, T187805)
node /kafkamon[12]002\.(codfw|eqiad)\.wmnet/ {
    role(kafka::monitoring_buster)
}

# New Kafka nodes T314160
node /kafka-stretch200[12]\.codfw\.wmnet/ {
    role(insetup)
}

# Karapace VM in support of DataHub
node /karapace1001\.eqiad\.wmnet/ {
    role(karapace)
}

# virtual machines for misc. applications and static sites
# replaced miscweb1001/2001 in T247648 and bromine/vega in T247650
#
# profile::iegreview                   # https://iegreview.wikimedia.org
# profile::racktables                  # https://racktables.wikimedia.org
# profile::microsites::annualreport    # https://annual.wikimedia.org
# profile::microsites::static_rt       # https://static-rt.wikimedia.org
# profile::microsites::transparency    # https://transparency.wikimedia.org
# profile::microsites::research        # https://research.wikimedia.org (T183916)
# profile::microsites::design          # https://design.wikimedia.org (T185282)
# profile::microsites::sitemaps        # https://sitemaps.wikimedia.org
# profile::microsites::bienvenida      # https://bienvenida.wikimedia.org (T207816)
# profile::microsites::wikiworkshop    # https://wikiworkshop.org (T242374)
# profile::microsites::static_codereview # https://static-codereview.wikimedia.org (T243056)
# profile::microsites::static_tendril  # https://tendril.wikimedia.org and https://dbtree.wikimedia.org (T297605)
node 'miscweb1002.eqiad.wmnet', 'miscweb2002.codfw.wmnet' {
    role(miscweb)
}

# This node will eventually replace kerberos1001
# It is part of the Kerberos eqiad/codfw infrastructure.
node 'krb1001.eqiad.wmnet' {
    role(kerberos::kdc)
}

# Kerberos KDC in codfw, replicates from krb1001
# It is part of the Kerberos eqiad/codfw infrastructure.
node 'krb2001.codfw.wmnet' {
    role(kerberos::kdc)
}

# New pki node # T305488
node 'krb2002.codfw.wmnet' {
    role(insetup)
}

node /kubernetes[12]0(0[5-9]|1[0-9]|2[0-2])\.(codfw|eqiad)\.wmnet/ {
    role(kubernetes::worker)
}

# New kubernetes node T313870
node /kubernetes202[34]\.codfw\.wmnet/ {
    role(insetup)
}

node /kubestage100[34]\.eqiad\.wmnet/ {
    role(kubernetes::staging::worker)
}

# codfw new kubernetes staging nodes T252185
node /kubestage200[12]\.codfw\.wmnet/ {
    role(kubernetes::staging::worker)
}

node /cloudvirt200[1-3]\-dev\.codfw\.wmnet/ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

# WMCS Graphite and StatsD hosts
node /cloudmetrics100[34]\.eqiad\.wmnet/ {
    role(wmcs::monitoring)
}

node /cloudmetrics100[1-2]\.eqiad\.wmnet/ {
    role(spare::system)
}

node /^cloudcontrol100[5-7]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::control)
}

# ceph monitor nodes
node /^cloudcephmon100[1-3]\.eqiad\.wmnet$/ {
    role(wmcs::ceph::mon)
}

# ceph storage nodes
node /^cloudcephosd10(0[1-9]|1[0-9]|2[0-6])\.eqiad\.wmnet$/ {
    role(wmcs::ceph::osd)
}

# ceph storage nodes
node /^cloudcephosd10(2[7-9]|3[0-4])\.eqiad\.wmnet$/ {
    role(insetup)
}

# New systems placed into service by cloud team via T194186 and T249062
node /^cloudelastic100[1-6]\.wikimedia\.org$/ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[3-4]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::net)
}

# new cloudnet1005 and 1006 servers T304888
node /^cloudnet100[5-6]\.eqiad\.wmnet$/ {
    role(insetup)
}

## Multi-instance wikireplica dbs
node /^clouddb10(13|14|15|16)\.eqiad\.wmnet$/ {
    role(wmcs::db::wikireplicas::web_multiinstance)
}

node /^clouddb10(17|18|19|20)\.eqiad\.wmnet$/ {
    role(wmcs::db::wikireplicas::analytics_multiinstance)
}

node 'clouddb1021.eqiad.wmnet' {
    role(wmcs::db::wikireplicas::dedicated::analytics_multiinstance)
}

node /labstore100[45]\.eqiad\.wmnet/ {
    role(wmcs::nfs::primary)
    # Do not enable yet
    # include ::profile::base::firewall
}

# The following nodes pull data periodically
# from the Analytics Hadoop cluster. Every new
# host needs a kerberos keytab generated,
# according to the details outlined in the
# role's hiera configuration.
node /labstore100[67]\.wikimedia\.org/ {
    role(dumps::distribution::server)
}

node /cloudbackup100[34]\.eqiad\.wmnet/ {
    role(wmcs::openstack::eqiad1::backy)
}

# During upgrades and transitions, this will
#  duplicate the work of labstore1003 (but on
#  a different day of the week)
node 'cloudbackup2001.codfw.wmnet' {
    role(wmcs::nfs::primary_backup::tools)
}

# During upgrades and transitions, this will
#  duplicate the work of labstore1004 (but on
#  a different day of the week)
node 'cloudbackup2002.codfw.wmnet' {
    role(wmcs::openstack::eqiad1::backups)

    # Transitional: once we've fully moved to NFS-on-cinder
    #  this role can be removed.
    include ::role::wmcs::nfs::primary_backup::misc
}

# the cinder-backup nodes for codfw1dev run in the eqiad DC and
# they are ganeti virtual machines. See T295584 for details.
node /^cloudbackup1001-dev\.eqiad\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::backups)
}

# evidence suggests that we can only have a single backup node
#  for cinder-backup. This host can probably be reclaimed
#  for general ganetti use but I'm just marking it as
#  empty for now (AGB)
node /^cloudbackup1002-dev\.eqiad\.wmnet$/ {
    role(spare::system)
    # role(wmcs::openstack::codfw1dev::backups)
}

# LDAP servers with a replica of OIT's user directory (used by mail servers)
node /^ldap-corp[1-2]001\.wikimedia\.org$/ {
    role(openldap::corp)
}

# Read-only ldap replicas in eqiad
node /^ldap-replica100[3-4]\.wikimedia\.org$/ {
    role(openldap::replica)
}

# Read-only ldap replicas in codfw
node /^ldap-replica200[5-6]\.wikimedia\.org$/ {
    role(openldap::replica)
}

# Logging data nodes (codfw)
node /^logstash20(0[123]|2[6789]|3[345])\.codfw\.wmnet$/ {
    role(logging::opensearch::data)
}

# Logging collector nodes (codfw)
node /^logstash20(2[345]|3[012])\.codfw\.wmnet$/ {
    role(logging::opensearch::collector)
}

# Logging data nodes (eqiad)
node /^logstash10(1[012]|2[6789]|3[345])\.eqiad\.wmnet$/ {
    role(logging::opensearch::data)
}

# Logging collector nodes (eqiad)
node /^logstash10(2[345]|3[012])\.eqiad\.wmnet$/ {
    role(logging::opensearch::collector)
}

# Deprecated Logstash collectors (codfw)
node /^logstash200[4-6]\.codfw\.wmnet$/ {
    role(spare::system)
}

# Deprecated Logstash collectors (eqiad)
node /^logstash100[7-9]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# new lvs servers T295804 (in prod use)
node /^lvs10(1[789]|20)\.eqiad\.wmnet$/ {
    role(lvs::balancer)
}

# old lvs servers T295804 (insetup for future experimentation!)
node /^lvs101[3456].eqiad.wmnet$/ {
    role(insetup_noferm)
}

# codfw lvs
node /lvs200[789]\.codfw\.wmnet/ {
    role(lvs::balancer)
}

node 'lvs2010.codfw.wmnet' {
    role(lvs::balancer)
}

# ESAMS lvs servers
node /^lvs300[567]\.esams\.wmnet$/ {
    role(lvs::balancer)
}

# ULSFO lvs servers
node /^lvs400[567]\.ulsfo\.wmnet$/ {
    role(lvs::balancer)
}

# EQSIN lvs servers
node /^lvs500[123]\.eqsin\.wmnet$/ {
    role(lvs::balancer)
}

# DRMRS lvs servers
node /^lvs600[123]\.drmrs\.wmnet$/ {
    role(lvs::balancer)
}

node /^maps10(0[5-8]|1[0])\.eqiad\.wmnet/ {
    role(maps::replica)
}

# testing buster master - maps2.0 migration
node 'maps1009.eqiad.wmnet' {
    role(maps::master)
}

node /^maps20(0[5-8]|10)\.codfw\.wmnet/ {
    role(maps::replica)
}

# testing buster master - maps2.0 migration
node 'maps2009.codfw.wmnet' {
    role(maps::master)
}


# Buster replacement for matomo1001 - T252740
node 'matomo1002.eqiad.wmnet' {
    role(piwik)
}

node /^mc10(3[7-9]|4[0-9]|5[0-4])\.eqiad\.wmnet/ {
    role(mediawiki::memcached)
}

node /^mc20(19|2[0-7]|29|3[0-8])\.codfw\.wmnet/ {
    role(mediawiki::memcached)
}

# New mc nodes T294962
node /^mc20(39|4[0-9]|5[0-5])\.codfw\.wmnet/ {
    role(insetup)
}

node /^mc-gp100[1-3]\.eqiad\.wmnet/ {
    role(mediawiki::memcached::gutter)
}

node /^mc-gp200[1-3]\.codfw\.wmnet/ {
    role(mediawiki::memcached::gutter)
}

# New mc-wf nodes T313966
node /^mc-wf200[1-2]\.codfw\.wmnet/ {
    role(insetup)
}

node /^ml-cache100[123]\.eqiad\.wmnet/ {
    role(ml_cache::storage)
}

node /^ml-cache200[123]\.codfw\.wmnet/ {
    role(ml_cache::storage)
}

node /^ml-etcd100[123]\.eqiad\.wmnet/ {
    role(etcd::v3::ml_etcd)
}

node /^ml-etcd200[123]\.codfw\.wmnet/ {
    role(etcd::v3::ml_etcd)
}

node /^ml-serve-ctrl100[12]\.eqiad\.wmnet/ {
    role(ml_k8s::master)
}

node /^ml-serve-ctrl200[12]\.codfw\.wmnet/ {
    role(ml_k8s::master)
}

node /^ml-serve200[1-8]\.codfw\.wmnet/ {
    role(ml_k8s::worker)
}

node /^ml-serve100[1-8]\.eqiad\.wmnet/ {
    role(ml_k8s::worker)
}

# New ml-staging etcd T302503
node /^ml-staging-etcd200[123]\.codfw.wmnet/ {
    role(etcd::v3::ml_etcd::staging)
}

# New ml-staging ctrl T302503
node /^ml-staging-ctrl200[12]\.codfw.wmnet/ {
    role(ml_k8s::master::staging)
}

# New ml-staging nodes T294946
node /^ml-staging200[12]\.codfw\.wmnet/ {
    role(ml_k8s::worker::staging)
}

# RT, replaced ununpentium
node 'moscovium.eqiad.wmnet' {
    role(requesttracker)
}

node /^moss-fe100[12]\.eqiad\.wmnet/ {
    role(insetup)
}

# New moss-be nodes T276637
node /^moss-be100[12]\.eqiad\.wmnet/ {
    role(insetup)
}

# New moss-be nodes T276642
node /^moss-be200[12]\.codfw\.wmnet/ {
    role(insetup)
}

# New moss-fe nodes T275513
node /^moss-fe200[12]\.codfw\.wmnet/ {
    role(insetup)
}

node /^ms-backup100[12]\.eqiad\.wmnet/ {
    role(mediabackup::worker)
}

node /^ms-backup200[12]\.codfw\.wmnet/ {
    role(mediabackup::worker)
}

node /^ms-fe1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe2\d\d\d\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be2\d\d\d\.codfw\.wmnet$/ {
    role(swift::storage)
}

## MEDIAWIKI APPLICATION SERVERS

## DATACENTER: EQIAD

# Debug servers, on buster like production
node /^mwdebug100[12]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# Appservers (serving normal website traffic)

# New mw servers T306121
node /^mw14(5[7-9]|6[0-9]|7[0-9]|8[0-9]|9[0-8])\.eqiad\.wmnet/ {
    role(insetup)
}

# Row A

# rack A1
node /^mw14(5[1-2])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A3
node /^mw141([4-8])\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

node /^mw14(19|20)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw14(2[1-2])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack A5
node /^mw13(8[579]|91)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A8
node /^mw14(5[3-6])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row B

# rack B3
node /^mw14(2[3-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw14(29|3[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack B3 and B5
node /^mw1(39[3579]|40[13])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row C

# rack C3
node /^mw140[57]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw14(3[4-6])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C6
node /^mw13(19|2[0-9]|3[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C8
node /^mw14(09|1[13])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row D

# rack D1
node /^mw13(49|5[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack D3
node /^mw1363\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack D3
node /^mw136[45]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack D6
node /^mw13(6[6-9]|7[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack D6
node /^mw13(7[4-9]|8[0-2])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack D8 - API servers
node /^mw(1383|144[3-4])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack D8 - canary jobrunners
node /^mw143[7-8]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack D8 - jobrunners
node /^mw14(39|40|45|46)\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack D8 - appservers
node /^mw1384\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw144([1-2])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row A

# rack A6
node 'mw1312.eqiad.wmnet' {
    role(mediawiki::appserver::api)
}

# rack A5
node /^mw13(8[68]|9[02])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row B

# rack B5
node 'mw1317.eqiad.wmnet' {
    role(mediawiki::appserver::api)
}

# rack B7
node /^mw13(1[3-6])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack B3 and B5
node /^mw1(39[468]|40[024])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row C

# rack C6
node /^mw13(39|4[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack C3
node /^mw1406\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack C8
node /^mw14(08|1[02])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row D

# rack D1
node /^mw13(5[6-9]|6[0-2])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}
# rack D8
node /^mw14(4[7-9]|50)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
}


# mediawiki maintenance server (periodic jobs)
# mwmaint1002 replaced mwmaint1001 (T201343) which replaced terbium (T192185)
# mwmaint2002 replaced mwmaint2001 (T274170, T275905)
node 'mwmaint1002.eqiad.wmnet', 'mwmaint2002.codfw.wmnet' {
    role(mediawiki::maintenance)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Row A

# rack A6
node /^mw13(0[7-9]|1[01])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row B

# rack B5
node 'mw1318.eqiad.wmnet' {
    role(mediawiki::jobrunner)
}

# Row C

# rack C6
node /^mw133[4-8]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

## DATACENTER: CODFW

# Debug servers
# mwdebug2001 is in row A, mwdebug2002 is in row B
node /^mwdebug200[12]\.codfw\.wmnet$/ {
    role(mediawiki::canary_appserver)
}


# Appservers

# Row A

# New mw server hardware 2021 (T274171)

# rack A3 (T278396)
node /^mw23(8[1-2]|9[4-5])\.codfw\.wmnet/ {
    role(mediawiki::jobrunner)
}

node /^mw2(29[1-9]|300)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw23(7[7-9]|80|8[3-9]|9[0-3])\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

node /^mw2(39[6-9]|40[0-2])\.codfw\.wmnet/ {
    role(mediawiki::appserver::api)
}

# rack A5 (T279599)
node /^mw240[3-5]\.codfw\.wmnet/ {
    role(mediawiki::appserver::api)
}

node /^mw240[6-9]\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

node /^mw241[0-1]\.codfw\.wmnet/ {
    role(mediawiki::jobrunner)
}

# rack A6
node /^mw230[13579]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row B

# rack B3
node /^mw22(6[8-9]|70)\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack B3
node /^mw23(1[0-6])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack B3
node /^mw23(1[7-9]|2[0-4])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack B6
node /^mw23(2[579]|3[13])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C6
node /^mw23(59|6[135])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C6
node /^mw23(5[1357])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

# rack C3
node /^mw23(3[5-9])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw24(1[2-5])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw24(1[6-8])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw2419\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row D

# rack D3
node /^mw2(27[12])\.codfw\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# rack D3
node /^mw2(27[3-7]|36[79]|37[135])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# API

# Row A

# rack A6
node /^mw230[2468]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row B

# rack B3
node /^mw226[1-2]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack B6
node /^mw23(2[68]|3[024])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row C

# rack C6
node /^mw23(5[02468]|6[024])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row D

# rack D3

node /^mw237[46]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
}

node /^mw23(6[68]|7[02])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack D4
node /^mw22(8[3-9]|90)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Jobrunners

# Row A

# Row B

# rack B3
node /^mw22(59|60)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack B3
node /^mw226[3-7]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

# Row D

# rack D4 - canary jobrunners
node /^mw227[8-9]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack D4 - jobrunners
node /^mw228[1-2]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host eqiad
node 'mwlog1002.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
}

# mw logging host codfw
node 'mwlog2002.codfw.wmnet' {
    role(logging::mediawiki::udp2log)
}

node 'mx1001.wikimedia.org' {
    role(mail::mx)

    interface::alias { 'wiki-mail-eqiad.wikimedia.org':
        ipv4 => '208.80.154.91',
        ipv6 => '2620:0:861:3:208:80:154:91',
    }
}

node 'mx2001.wikimedia.org' {
    role(mail::mx)

    interface::alias { 'wiki-mail-codfw.wikimedia.org':
        ipv4 => '208.80.153.46',
        ipv6 => '2620:0:860:2:208:80:153:46',
    }
}

# ncredir instances
node /^ncredir100[12]\.eqiad\.wmnet$/ {
    role(ncredir)
}

node /^ncredir200[12]\.codfw\.wmnet$/ {
    role(ncredir)
}

node /^ncredir300[12]\.esams\.wmnet$/ {
    role(ncredir)
}

node /^ncredir400[12]\.ulsfo\.wmnet$/ {
    role(ncredir)
}

node /^ncredir500[12]\.eqsin\.wmnet$/ {
    role(ncredir)
}

node /^ncredir600[12]\.drmrs\.wmnet$/ {
    role(ncredir)
}

node /^netbox[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(netbox::frontend)
}

node /^netboxdb[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(netbox::database)
}

node /^netbox-dev2002\.codfw\.wmnet$/ {
    role(netbox::standalone)
}

# network monitoring tools, stretch (T125020, T166180)
node /^netmon(1002|2001)\.wikimedia\.org$/ {
    role(netmon)
}

# New netmon node T299106
node /^netmon1003\.wikimedia\.org$/ {
    role(netmon)
}

# New netmon node T313867
node /^netmon2002\.wikimedia\.org$/ {
    role(insetup)
}

# Network insights (netflow/pmacct, etc.)
node /^netflow[1-6]00[1-9]\.(eqiad|codfw|ulsfo|esams|eqsin|drmrs)\.wmnet$/ {
    role(netinsights)
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
}

node /orespoolcounter[12]00[34]\.(codfw|eqiad)\.wmnet/ {
    role(orespoolcounter)
}

node 'otrs1001.eqiad.wmnet' {
    role(vrts)
}

# new parsoid nodes - codfw (T243112, T247441)
node /^parse20(0[1-9]|1[0-9]|20)\.codfw\.wmnet$/ {
    role(parsoid)
}

# new parsoid nodes - eqiad T299573
node /^parse10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    role(insetup)
}


# parser cache databases
# eqiad
# pc1
node 'pc1011.eqiad.wmnet' {
    role(mariadb::parsercache)
}
# pc2
node 'pc1012.eqiad.wmnet' {
    role(mariadb::parsercache)
}
# pc3
node 'pc1013.eqiad.wmnet' {
    role(mariadb::parsercache)
}
# floating spare
node 'pc1014.eqiad.wmnet' {
    role(mariadb::parsercache)
}

# codfw
# pc1
node 'pc2011.codfw.wmnet' {
    role(mariadb::parsercache)
}
# pc2
node 'pc2012.codfw.wmnet' {
    role(mariadb::parsercache)
}
# pc3
node 'pc2013.codfw.wmnet' {
    role(mariadb::parsercache)
}
# floating spare
node 'pc2014.codfw.wmnet' {
    role(mariadb::parsercache)
}


# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[123]002\.(eqiad|codfw|esams)\.wmnet$/ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(planet)
}

node /poolcounter[12]00[345]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
}

node /^prometheus200[56]\.codfw\.wmnet$/ {
    role(prometheus)
}

node /^prometheus100[56]\.eqiad\.wmnet$/ {
    role(prometheus)
}

node /^prometheus[3456]001\.(esams|ulsfo|eqsin|drmrs)\.wmnet$/ {
    role(prometheus::pop)
}

# new puppetmaster servers T291963
node 'puppetmaster1005.eqiad.wmnet' {
    role(insetup)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]00[234]\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
}

# New puppetmaster nodes T289733
node 'puppetmaster2005.codfw.wmnet' {
    role(insetup)
}

node /^puppetboard[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard)
}

node /^puppetdb[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetdb)
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
}

node /^rdb10(09|11)\.eqiad\.wmnet$/ {
    role(redis::misc::master)
}

node /^rdb101[02]\.eqiad\.wmnet$/ {
    role(redis::misc::slave)
}

node /^rdb200[79]\.codfw\.wmnet$/ {
    role(redis::misc::master)
}

node /^rdb20(08|10)\.codfw\.wmnet$/ {
    role(redis::misc::slave)
}

node /^registry[12]00[34]\.(eqiad|codfw)\.wmnet$/ {
    role(docker_registry_ha::registry)
}

# https://releases.wikimedia.org - VMs for releases files (mediawiki and other)
# https://releases-jenkins.wikimedia.org (automatic Mediawiki builds)
node /^releases[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(releases)
}

# New relforge servers T241791 (provision), T262211 (service impl.)
node /^relforge100[3-4]\.eqiad\.wmnet/ {
    role(elasticsearch::relforge)
}
# new eqiad restbase servers T294372
node /^restbase103[1-3]\.eqiad\.wmnet$/ {
    role(insetup)
}

# restbase eqiad cluster
node /^restbase10(1[6-9]|2[0-9]|30)\.eqiad\.wmnet$/ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(09|1[0-9]|2[0-7])\.codfw\.wmnet$/ {
    role(restbase::production)
}

# cassandra/restbase dev cluster
node /^restbase-dev100[4-6]\.eqiad\.wmnet$/ {
    role(restbase::dev_cluster)
}

# New restbase dev nodes T299437
node /^restbase-dev200[1-3]\.codfw\.wmnet$/ {
    role(insetup)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(rpkivalidator)
}

# https://people.wikimedia.org - self-service file hosting
# VMs on bullseye, access for all shell users (T280989)
node 'people1003.eqiad.wmnet', 'people2002.codfw.wmnet' {
    role(microsites::peopleweb)
}

# scandium is a parsoid test server. it replaced ruthenium.
# This is now just like an MW appserver plus parsoid repo.
# roundtrip and visualdiff testing moved to testreduce1001 (T257906)
node 'scandium.eqiad.wmnet' {
    role(parsoid::testing)
}

node /schema[12]00[3-4].(eqiad|codfw).wmnet/ {
    role(eventschemas::service)
}

# See T258189
node /search-loader[12]001.(eqiad|codfw).wmnet/ {
    role(search::loader)
}


# new sessionstore servers via T209393 & T209389
node /sessionstore[1-2]00[1-3].(eqiad|codfw).wmnet/ {
    role(sessionstore)
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::rw)
}

node 'mirror1001.wikimedia.org' {
    role(mirrors)
}

node 'thorium.eqiad.wmnet' {
    # replaced by an-web1001, being decommissioned:
    # https://phabricator.wikimedia.org/T292075
    role(spare::system)
}

# The hosts contain all the tools and libraries to access
# the Analytics Cluster services.
node /^stat100[4-8]\.eqiad\.wmnet/ {
    role(statistics::explorer)
}

# New stat nodes T299466 and T307399
node /^stat10(0[9]|1[0])\.eqiad\.wmnet/ {
    role(insetup)
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
# They should also be added to the dumps/scap repo in dumps_targets,
# https://gerrit.wikimedia.org/r/plugins/gitiles/operations/dumps/scap
node /^snapshot1008\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_misc_crons_only)
}
node /^snapshot1010\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_monitor)
}
node /^snapshot1009\.eqiad\.wmnet/ {
    role(dumps::generation::worker::testbed)
}
node /^snapshot101[1-2]\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper)
}
node /^snapshot1013\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper)
}

node /^snapshot101[45]\.eqiad\.wmnet/ {
    role(insetup)
}

# Servers for SRE tests which are not suitable for Cloud VPS
node /^sretest100[1-2]\.eqiad\.wmnet$/ {
    role(sretest)
}

# parsoid visual diff and roundtrip testing (T257940)
# also see scandium.eqiad.wmnet
node 'testreduce1001.eqiad.wmnet' {
    role(parsoid::testreduce)
}

# Test instances for Ganeti test cluster
node /^testvm200[1-9]\.codfw\.wmnet$/ {
    role(test)
}

# Used for various d-i tests
node 'theemin.codfw.wmnet' {
    role(test)
}

node /^thanos-be100[1234]\.eqiad\.wmnet/ {
    role(thanos::backend)
}

node /^thanos-be200[1234]\.codfw\.wmnet/ {
    role(thanos::backend)
}

node /^thanos-fe100[123]\.eqiad\.wmnet/ {
    role(thanos::frontend)
}

node /^thanos-fe200[123]\.codfw\.wmnet/ {
    role(thanos::frontend)
}

# Thumbor servers for MediaWiki image scaling
node /^thumbor100[1256]\.eqiad\.wmnet/ {
    role(thumbor::mediawiki)
}

node /^thumbor200[3456]\.codfw\.wmnet/ {
    role(thumbor::mediawiki)
}

# deployment servers
node /^deploy[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(deployment_server::kubernetes)
}

# new url-downloaders (T224551)
# https://wikitech.wikimedia.org/wiki/Url-downloader
node /^urldownloader[12]00[12]\.wikimedia\.org/ {
    role(url_downloader)
}

node 'cloudvirt1017.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# cloudvirt1018 doesn't exist.

# Cloudvirt1019 and 1020 are special hypervisors;
#  they host giant database servers using local storage.
node 'cloudvirt1019.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt)
}
node 'cloudvirt1020.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt)
}

# cloudvirts using Ceph backend storage
# https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Ceph
node /^cloudvirt102[1-7]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph_and_backy)
}

# Cloudvirt1028 is special: it hosts VMs using local storage.
#  This, along with 1019 and 1020, allows us to host etcd
#  clusters which are incredibly sensitive to iowait.
node 'cloudvirt1028.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt)
}

node 'cloudvirt1029.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

node /^cloudvirt103[0-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# new cloudvirt servers T305194 and T299574
node /^cloudvirt10(4[0-9]|5[0-3])\.eqiad\.wmnet/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# Private virt hosts for wdqs T221631
node /^cloudvirt-wdqs100[123]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
}

# New wcqs node T276644
node /^wcqs100[123]\.eqiad\.wmnet/ {
    role(wcqs::public)
}

# New wcqs node T276647
node /^wcqs200[123]\.codfw\.wmnet/ {
    role(wcqs::public)
}

# Wikidata query service
node /^wdqs100[4-7]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}

# T260083 brought wdqs101[1-3] into service with [2,3] public and [1] private
# new wdqs servers wdqs101[4-6] T307138
node /^wdqs101[2-6]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}

node /^wdqs200[12347]\.codfw\.wmnet$/ {
    role(wdqs::public)
}

# Wikidata query service internal
node /^wdqs100[38]\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs1011\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs200[568]\.codfw\.wmnet$/ {
    role(wdqs::internal)
}

# Codfw new wdqs nodes T294297
node /^(wdqs2009|wdqs2010|wdqs2011|wdqs2012)\.codfw\.wmnet$/ {
    role(insetup)
}

# Wikidata query service test
node /^wdqs10(09|10)\.eqiad\.wmnet$/ {
    role(wdqs::test)
}

node /^webperf[12]003\.(codfw|eqiad)\.wmnet/ {
    role(webperf::processors_and_site)
}

node /^webperf[12]004\.(codfw|eqiad)\.wmnet/ {
    role(webperf::profiling_tools)
}

# https://www.mediawiki.org/wiki/Parsoid - new machines are called parse*
node /^wtp10(2[5-9]|[34][0-9])\.eqiad\.wmnet$/ {
    role(parsoid)
}

node 'xhgui1001.eqiad.wmnet', 'xhgui2001.codfw.wmnet' {
    role(webperf::xhgui)
}

node default {
    if $::realm == 'production' {
        fail('No puppet role has been assigned to this node.')
    } else {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require ::role::wmcs::instance
    }
}
