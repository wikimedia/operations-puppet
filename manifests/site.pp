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

# New an-coord  nodes T321119
node /^an-coord100[3-4]\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
}

node /^an-db100[1-2]\.eqiad\.wmnet$/ {
    role(analytics_cluster::postgresql)
}

# New an-mariadb nodes T321119
node /^an-mariadb100[1-2]\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
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

node 'an-test-client1001.eqiad.wmnet' {
    role(analytics_test_cluster::client)
}

node 'an-test-client1002.eqiad.wmnet' {
    role(analytics_test_cluster::client)
}

node 'an-test-ui1001.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::ui)
}

node 'an-test-presto1001.eqiad.wmnet' {
    role(analytics_test_cluster::presto::server)
}

# analytics1058-analytics1077 and an-worker10XX
# are Analytics Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^analytics10(5[89]|6[0-9]|7[0-7]).eqiad.wmnet$/ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker10(7[89]|8[0-9]|9[0-9]).eqiad.wmnet$/ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker11(0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-8])\.eqiad\.wmnet$/ {
    role(analytics_cluster::hadoop::worker)
}

# New an-worker nodes T327295
node /^an-worker11(4[9]|5[0-6])\.eqiad\.wmnet$/ {
    role(insetup::core_platform)
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

node 'an-airflow1005.eqiad.wmnet' {
    role(analytics_cluster::airflow::search)
}

# product-analytics instance of Apache Airflow
node 'an-airflow1006.eqiad.wmnet' {
    role(analytics_cluster::airflow::analytics_product)
    }

# Analytics Zookepeer cluster
node /^an-conf100[1-3]\.eqiad\.wmnet$/ {
    role(analytics_cluster::zookeeper)
}

# Analytics Presto nodes. 1001 - 1015
node /^an-presto10(0[1-9]|1[0-5])\.eqiad\.wmnet$/ {
    role(analytics_cluster::presto::server)
}

# Analytics Web Node.
node 'an-web1001.eqiad.wmnet' {
    role(analytics_cluster::webserver)
}

# API Feature Usage log pipeline procesors
node /^apifeatureusage[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(apifeatureusage::logstash)
}

# notification server for Phabricator (T257617 and T322369)
node /^aphlict(100[12]|2001)\.(eqiad|codfw)\.wmnet$/ {
    role(aphlict)
}

# new APT repositories (NOT DHCP/TFTP)
node /^apt[12]001\.wikimedia\.org$/ {
    role(apt_repo)
}

# Analytics Query Service
node /^aqs10(1[0-9]|2[0-1])\.eqiad\.wmnet$/ {
    role(aqs)
}

node /^aqs200[1-9]|aqs201[0-2]\.codfw\.wmnet$/ {
    role(aqs)
}

# New Archiva host on Buster
# T254890
node 'archiva1002.wikimedia.org' {
    role(archiva)
}

# Deprecated, preserved for posterity: T330670
#node /^authdns[12]001\.wikimedia\.org$/ {
#    role(dns::auth)
#}

# etcd cluster for aux kubernetes cluster
node /^aux-k8s-etcd100[1-3]\.eqiad\.wmnet$/ {
    role(etcd::v3::aux_k8s_etcd)
}

# control-plane servers for aux kubernetes cluster
node /^aux-k8s-ctrl100[1-2]\.eqiad\.wmnet$/ {
    role(aux_k8s::master)
}

# worker nodes for aux kubernetes cluster
node /^aux-k8s-worker100[1-2]\.eqiad\.wmnet$/ {
    role(aux_k8s::worker)
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
    role(backup::databases)
}

# new backup storage eqiad T307048
node 'backup1009.eqiad.wmnet' {
    role(backup::production)
}

# new backup node T326684
node /^backup101[0-1]\.eqiad\.wmnet$/ {
    role(insetup::data_persistence)
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
    role(backup::databases)
}

# New backup node for codfw T307049
node 'backup2009.codfw.wmnet' {
    role(backup::production)
}

# New backup node for codfw T326965
node /^backup201[0-1]\.codfw\.wmnet$/ {
    role(insetup::data_persistence)
}

node 'backupmon1001.eqiad.wmnet' {
    role(dbbackups::monitoring)
}

node 'bast1003.wikimedia.org' {
    role(bastionhost)
}

node 'bast2003.wikimedia.org' {
    role(bastionhost)
}

node 'bast3006.wikimedia.org' {
    role(bastionhost)
}

node 'bast4004.wikimedia.org' {
    role(bastionhost)
}

node 'bast5003.wikimedia.org' {
    role(bastionhost)
}

node 'bast6002.wikimedia.org' {
    role(bastionhost)
}

# Debian package/docker images building host in production
node 'build2001.codfw.wmnet' {
    role(builder)
}

node /^centrallog[0-9]{4}\.(eqiad|codfw)\.wmnet$/ {
    role(syslog::centralserver)
}

node /^chartmuseum[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(chartmuseum)
}

node /^cloudgw100[12]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::cloudgw)
}

node /^cloudgw200[23]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::cloudgw)
}

node /^cloudlb200[123]-dev\.codfw\.wmnet$/ {
    role(wmcs::cloudlb)
}

node /^cloudcephosd200[123]-dev\.codfw\.wmnet$/ {
    role(wmcs::ceph::osd)
}

node /^cloudcephmon200[4-6]-dev\.codfw\.wmnet$/ {
    role(wmcs::ceph::mon)
}

# The following nodes pull data periodically
# from the Analytics Hadoop cluster. Every new
# host needs a kerberos keytab generated,
# according to the details outlined in the
# role's hiera configuration.
node /^clouddumps100[12]\.wikimedia\.org$/ {
    role(dumps::distribution::server)
}

# All gerrit servers (swap master status in hiera)
node 'gerrit1003.wikimedia.org', 'gerrit2002.wikimedia.org' {
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
node /^kafka-test10(10|0[6-9])\.eqiad\.wmnet$/ {
    role(kafka::test::broker)
}

node /^(contint1002|contint2001|contint2002)\.wikimedia\.org$/ {
    role(ci)
}

node /^cp10(7[579]|8[13579])\.eqiad\.wmnet$/ {
    role(cache::text)
}

node /^cp10(7[68]|8[02468]|90)\.eqiad\.wmnet$/ {
    role(cache::upload)
}

node /^cp20(2[79]|3[13579]|41)\.codfw\.wmnet$/ {
    role(cache::text)
}

node /^cp20(28|3[02468]|4[02])\.codfw\.wmnet$/ {
    role(cache::upload)
}

#
# esams caches
#

node /^cp30(5[02468]|6[024])\.esams\.wmnet$/ {
    role(cache::text)
}

node /^cp30(5[13579]|6[135])\.esams\.wmnet$/ {
    role(cache::upload)
}

#
# ulsfo caches
#

node /^cp40(4[56789]|5[012])\.ulsfo\.wmnet$/ {
    role(cache::upload)
}

node /^cp40(3[789]|4[01234])\.ulsfo.wmnet$/ {
    role(cache::text)
}

#
# eqsin caches
#

# Temp setup, will go away once wiped
node /^cp50(1[3456])\.eqsin\.wmnet$/ {
    role(insetup::traffic)
}

node /^cp50(2[56789]|3[012])\.eqsin\.wmnet$/ {
    role(cache::upload)
}

node /^cp50(1[789]|2[01234])\.eqsin\.wmnet$/ {
    role(cache::text)
}

#
# cp drmrs nodes
#

node /^cp600[1-8]\.drmrs\.wmnet$/ {
    role(cache::upload)
}

node /^cp60(09|1[0-6])\.drmrs\.wmnet$/ {
    role(cache::text)
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

# Hosts to be set up T325209
node /^db1(208)\.eqiad\.wmnet$/ {
    role(insetup::data_persistence)
}

# s1 (enwiki) core production dbs on eqiad
node /^db1(106|119|128|132|134|135|163|169|184|186|206|207|218|219)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1196.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
# See also db2167 and db2170 below
node /^db2(103|112|116|130|145|146|153|174|176)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2173.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on eqiad
# See also db1146, db1170 below
node /^db1(129|162|182|188|197|222)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1156.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
# See also db2170 and db2138 below
node /^db2(104|107|125|148|175)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2126.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on eqiad
node /^db1(157|166|175|189|198|223)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1212.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on codfw
node /^db2(105|109|127|149|177)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2156.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s4 (commons) core production dbs on eqiad
# See also db1144 and db1146 below
node /^db1(138|141|142|143|147|148|149|160|190|199)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1221.eqiad.wmnet' {
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
node /^db2(106|110|119|136|140|147|172|179)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2155.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on eqiad
# See also db1213 and db1144 below
node /^db1(130|183|185|200|210)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1161.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
# See also db2171 and db2137 below
node /^db2(111|113|123|157|178)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2128.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s6 (frwiki, jawiki, ruwiki) core production dbs on eqiad
# See also db1213 below
node /^db1(131|168|173|180|187|201|224)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1165.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s6 core production dbs on codfw
# See also db2169 and db2171 below
node /^db2(114|117|124|129|151|180)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2158.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# See also db1170 below
node /^db1(069|127|136|174|178|181|191|194|202)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1158.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# See also db2168 and db2169 below
node /^db2(108|118|120|121|122|150|182)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2159.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on eqiad
node /^db1(126|172|177|192|193|203|209|211|214)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# eqiad sanitarium master
node 'db1167.eqiad.wmnet' {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on codfw
# See also db2167 db2168 below
node /^db2(152|154|161|162|163|165|166|181)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# codfw sanitarium master
node 'db2164.codfw.wmnet' {
    role(mariadb::sanitarium_master)
}

# multi-instance hosts with multiple shards
node /^db1(144|146|170|213)\.eqiad\.wmnet$/ {
    role(mariadb::core_multiinstance)
}
node /^db2(137|138|167|168|169|170|171)\.codfw\.wmnet$/ {
    role(mariadb::core_multiinstance)
}

## x1 shard
# eqiad
node /^db1(137|179|220)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# codfw
node /^db2(096|115|131)\.codfw\.wmnet$/ {
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
# See also multiinstance misc hosts db1217, db2160 below

# m1 master
node 'db1164.eqiad.wmnet' {
    role(mariadb::misc)
}

# m1 codfw master
node 'db2132.codfw.wmnet' {
    role(mariadb::misc)
}

## m2 shard
# See also multiinstance misc hosts db1217, db2160 below

# m2 master
node 'db1195.eqiad.wmnet' {
    role(mariadb::misc)
}

# m2 codfw master
node 'db2133.codfw.wmnet' {
    role(mariadb::misc)
}

## m3 shard
# See also multiinstance misc hosts db1217, db2160 below

# m3 master
node 'db1159.eqiad.wmnet' {
    role(mariadb::misc::phabricator)
}

# Temporary testing host for T335080
node 'db1118.eqiad.wmnet' {
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
# See also multiinstance misc hosts db1217, db2160 below

# m5 master
node 'db1176.eqiad.wmnet' {
    role(mariadb::misc)
}

# m5 codfw master
node 'db2135.codfw.wmnet' {
    role(mariadb::misc)
}

# misc multiinstance
node 'db1217.eqiad.wmnet' {
    role(mariadb::misc::multiinstance)
}

node 'db2160.codfw.wmnet' {
    role(mariadb::misc::multiinstance)
}

# sanitarium hosts
node /^db1(154|155)\.eqiad\.wmnet$/ {
    role(mariadb::sanitarium_multiinstance)
}

node /^db2(186|187)\.codfw\.wmnet$/ {
    role(mariadb::sanitarium_multiinstance)
}

# zarcillo master
node 'db1215.eqiad.wmnet' {
    role(mariadb::misc::db_inventory)
}

# zarcillo slave
node 'db2185.codfw.wmnet' {
    role(mariadb::misc::db_inventory)
}

# Orchestrator central node (VM on ganeti)
node 'dborch1001.wikimedia.org' {
    role(orchestrator)
}

# backup1-eqiad section (datacenter-specific backup metadata hosts)
node /^(db1204|db1205)\.eqiad\.wmnet$/ {
    role(mariadb::misc)
}
# backup1-codfw section (datacenter-specific backup metadata hosts)
node /^db2183|db2184\.codfw\.wmnet$/ {
    role(mariadb::misc)
}

# eqiad backup sources
## s1 & s2, bullseye
node 'db1139.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s1 & s6, bullseye
node 'db1140.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s4 & s5, bullseye
node 'db1145.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s3 & s4, bullseye
node 'db1150.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node 'db1171.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s2, s3 & x1, bullseye
node 'db1225.eqiad.wmnet' {
    role(mariadb::backup_source)
}
## s5, s8 & x1, bullseye
node 'db1216.eqiad.wmnet' {
    role(mariadb::backup_source)
}

# codfw backup sources
## s1, bullseye
node 'db2097.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node 'db2098.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s4, bullseye
node 'db2099.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node 'db2100.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s2, s5, & x1, bullseye
node 'db2101.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s3 & s4, bullseye
node 'db2139.codfw.wmnet' {
    role(mariadb::backup_source)
}
## s1 & s6, bullseye
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
node 'dbprov1004.eqiad.wmnet' {
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
node 'dbprov2004.codfw.wmnet' {
    role(dbbackups::metadata)
}

# Active eqiad proxies for misc databases
node /^dbproxy10(12|13|14|15|16|17|20|21|22|23|24|25|26|27)\.eqiad\.wmnet$/ {
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

node /^debmonitor[1]003\.(codfw|eqiad)\.wmnet$/ {
    role(insetup::infrastructure_foundations)
}

node /^debmonitor[2]003\.(codfw|eqiad)\.wmnet$/ {
    role(debmonitor::server)
}

# Dispatch hosts
node 'dispatch-be1001.eqiad.wmnet' {
    role(dispatch::backend)
}

node 'dispatch-be2001.codfw.wmnet' {
    role(dispatch::backend)
}

node /^dns[123456]00[123456]\.wikimedia\.org$/ {
    role(dnsbox)
}

node /^doc[12]00[123]\.(codfw|eqiad)\.wmnet$/ {
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

node /^druid10(09|10|11)\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
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

# to be decommed eventually
node /^dumpsdata1001\.eqiad\.wmnet$/ {
    role(dumps::generation::server::spare)
}
# nfs server for xml dumps generation, also rsyncs xml dumps
# data to fallback nfs server(s)
node /^dumpsdata1006\.eqiad\.wmnet$/ {
    role(dumps::generation::server::xmldumps)
}

# nfs server for misc dumps generation, also rsyncs misc dumps
node /^dumpsdata1002\.eqiad\.wmnet$/ {
    role(dumps::generation::server::misccrons)
}

# fallback nfs server for dumps generation, also
# will rsync data to web servers
node /^dumpsdata1004\.eqiad\.wmnet$/ {
    role(dumps::generation::server::xmlfallback)
}

# new dumpsdata servers T283290
node /^dumpsdata100[357]\.eqiad\.wmnet$/ {
    role(dumps::generation::server::spare)
}

node /^elastic104[8-9]\.eqiad\.wmnet$/ {
    role(elasticsearch::cirrus)
}

node /^elastic105[0-9]\.eqiad\.wmnet$/ {
    role(elasticsearch::cirrus)
}

node /^elastic106[0-7]\.eqiad\.wmnet$/ {
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

node /^elastic203[7-9]\.codfw\.wmnet$/ {
    role(elasticsearch::cirrus)
}

node /^elastic204[0-8]\.codfw\.wmnet$/ {
    role(elasticsearch::cirrus)
}

node /^elastic205[0-9]\.codfw\.wmnet$/ {
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
    role(elasticsearch::cirrus)
}

# new eqiad row e-f elastic servers T299609
node /^(elastic1089|elastic109[0-9]|elastic110[0-2])\.eqiad\.wmnet$/ {
    role(insetup::search_platform)
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
node /^es202[012]\.codfw\.wmnet$/ {
    role(mariadb::core)
}

# External Storage, Shard 5 (es5) databases
## eqiad servers
node /^es102[345]\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

## codfw servers

node /^es202[345]\.codfw\.wmnet$/ {
    role(mariadb::core)
}

node /^failoid[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(failoid)
}

# Backup system, see T176505.
# This is a reserved system. Ask Otto or Faidon.
node 'flerovium.eqiad.wmnet' {
    role(analytics_cluster::hadoop::client)
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
node /^kubestagemaster[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
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

# New lists server T331706
node 'lists1003.wikimedia.org' {
    role(lists)
}

node /^ganeti10(09|1[0-9]|2[0-9]|3[0-4])\.eqiad\.wmnet$/ {
    role(ganeti)
}

node /^ganeti20(09|1[0-9]|2[0-9]|3[0-2])\.codfw\.wmnet$/ {
    role(ganeti)
}

node /^ganeti-test200[123]\.codfw\.wmnet$/ {
    role(ganeti_test)
}

node /^ganeti300[123]\.esams\.wmnet$/ {
    role(ganeti)
}

node /^ganeti400[5678]\.ulsfo\.wmnet$/ {
    role(ganeti)
}

node /^ganeti500[4567]\.eqsin\.wmnet$/ {
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
    role(insetup::serviceops_collab)
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

node 'irc1001.wikimedia.org' {
    role(mw_rc_irc)
}

node 'irc2001.wikimedia.org' {
    role(mw_rc_irc)
}

node /^irc[12]002\.wikimedia\.org$/ {
    role(mw_rc_irc)
}

# Cloud cumin hosts
node 'cloudcumin1001.eqiad.wmnet' {
    role(cluster::cloud_management)
}

node 'cloudcumin2001.codfw.wmnet' {
    role(cluster::cloud_management)
}

# cloudservices1004/1005 hosts openstack-designate
# and the powerdns auth and recursive services for instances in eqiad1.
node /^cloudservices100[45]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::services)
}

# New cloud node T289882
node /^cloudswift100[12]\.eqiad\.wmnet$/ {
    role(insetup::wmcs)
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

# New clouddb node T306854
node 'clouddb2002-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::db)
}

node /^cloudcontrol200[145]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::control)
}

# cloudrabbit servers T304888
node /^cloudrabbit100[123]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::rabbitmq)
}

node /^cloudservices200[45]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::services)
}

# Primary graphite host
node 'graphite1005.eqiad.wmnet' {
    role(graphite::production)
    include role::graphite::alerts # lint:ignore:wmf_styleguide
    include role::elasticsearch::alerts # lint:ignore:wmf_styleguide
}

# Standby graphite host
node 'graphite2004.codfw.wmnet' {
    role(graphite::production)
}

node /^idm[12]001\.wikimedia\.org$/ {
    role(idm)
}

node /^idm-test[12]001\.wikimedia\.org$/ {
    role(idm_test)
}

node /^idp[12]002\.wikimedia\.org$/ {
    role(idp)
}

node /^idp-test[12]002\.wikimedia\.org$/ {
    role(idp_test)
}

node /^install[12]004\.wikimedia\.org$/ {
    role(installserver)
}

node /^install[3456]002\.wikimedia\.org$/ {
    role(installserver)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T255072, T255070)
node /^alert[12]001\.wikimedia\.org$/ {
    role(alerting_host)
}

# Phabricator eqiad (T280540, T279176) (production)
node 'phab1004.eqiad.wmnet' {
    role(phabricator)
}

# Phabricator codfw (T280544, T279177) (failover)
node 'phab2002.codfw.wmnet' {
    role(phabricator)
}

# temp test VM for T335080
node 'phab-test1001.eqiad.wmnet' {
    role(insetup::serviceops_collab)
}

# PKI server
node 'pki1001.eqiad.wmnet' {
    role(pki::multirootca)
}

# PKI server
# make sure this is stricter enough to exclude rpki
node 'pki2002.codfw.wmnet' {
    role(pki::multirootca)
}

# pki-root server T276625
node 'pki-root1001.eqiad.wmnet' {
    role(pki::root)
}

# pki-root server T334401
node 'pki-root1002.eqiad.wmnet' {
    role(insetup::infrastructure_foundations)
}

node /^kafka-logging100[1-5]\.eqiad\.wmnet$/ {
    role(kafka::logging)
}

node /^kafka-logging200[1-5]\.codfw\.wmnet$/ {
    role(kafka::logging)
}

node /^kafka-main100[1-5]\.eqiad\.wmnet$/ {
    role(kafka::main)
}

node /^kafka-main200[1-5]\.codfw\.wmnet$/ {
    role(kafka::main)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo100[1-9]\.eqiad\.wmnet$/ {
    role(kafka::jumbo::broker)
}

node /^kafka-jumbo101[0-5]\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
}

# Kafkamon bullseye hosts
node /^kafkamon[12]003\.(codfw|eqiad)\.wmnet$/ {
    role(kafka::monitoring_bullseye)
}

# New Kafka nodes T314156
node /^kafka-stretch100[12]\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
}

# New Kafka nodes T314160
node /^kafka-stretch200[12]\.codfw\.wmnet$/ {
    role(insetup::data_engineering)
}

# Karapace VM in support of DataHub
node /^karapace1001\.eqiad\.wmnet$/ {
    role(karapace)
}

# virtual machines for misc. applications and static sites
# replaced miscweb1001/2001 in T247648 and bromine/vega in T247650
#
# profile::microsites::static_rt       # https://static-rt.wikimedia.org
# profile::microsites::research        # https://research.wikimedia.org (T183916)
# profile::microsites::design          # https://design.wikimedia.org (T185282)
# profile::microsites::wikiworkshop    # https://wikiworkshop.org (T242374)
# profile::microsites::static_codereview # https://static-codereview.wikimedia.org (T243056)
# profile::microsites::static_tendril  # https://tendril.wikimedia.org and https://dbtree.wikimedia.org (T297605)
node 'miscweb1003.eqiad.wmnet', 'miscweb2003.codfw.wmnet' {
    role(miscweb)
}

node 'krb1001.eqiad.wmnet' {
    role(kerberos::kdc)
}

node 'krb2002.codfw.wmnet' {
    role(kerberos::kdc)
}

node /^kubernetes[12]0(0[5-9]|1[0-9]|2[0-4])\.(codfw|eqiad)\.wmnet$/ {
    role(kubernetes::worker)
}

node /^kubestage100[34]\.eqiad\.wmnet$/ {
    role(kubernetes::staging::worker)
}

# codfw new kubernetes staging nodes T252185
node /^kubestage200[12]\.codfw\.wmnet$/ {
    role(kubernetes::staging::worker)
}

node /^cloudvirt200[1-3]\-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

# WMCS Graphite and StatsD hosts
node /^cloudmetrics100[34]\.eqiad\.wmnet$/ {
    role(wmcs::monitoring)
}

node /^cloudcontrol100[5-7]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::control)
}

#new cephosd servers T322760
node /^cephosd100[12345]\.eqiad\.wmnet$/ {
    role(ceph::server)
}

# cloudceph monitor nodes
node /^cloudcephmon100[1-3]\.eqiad\.wmnet$/ {
    role(wmcs::ceph::mon)
}

# new cloudceph storage nodes T324998
node /^cloudcephosd10(3[5-9]|4[0])\.eqiad\.wmnet$/ {
    role(insetup::wmcs)
}

# cloudceph storage nodes
node /^cloudcephosd10(0[1-9]|1[0-9]|2[0-9]|3[0-4])\.eqiad\.wmnet$/ {
    role(wmcs::ceph::osd)
}

# New systems placed into service by cloud team via T194186 and T249062
node /^cloudelastic100[1-6]\.wikimedia\.org$/ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[5-6]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::net)
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

node /^cloudbackup100[34]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::backy)
}

# Generates and stores cinder backups
node /^cloudbackup200[12]\.codfw\.wmnet$/ {
    role(wmcs::openstack::eqiad1::backups)
}

# the cinder-backup nodes for codfw1dev run in the eqiad DC and
# they are ganeti virtual machines. See T295584 for details.
node /^cloudbackup100[12]-dev\.eqiad\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::backups)
}

# Read-only ldap replicas in eqiad
node /^ldap-replica100[3-4]\.wikimedia\.org$/ {
    role(openldap::replica)
}

node 'ldap-rw1001.wikimedia.org' {
    role(insetup::infrastructure_foundations)
}

node 'ldap-rw2001.wikimedia.org' {
    role(insetup::infrastructure_foundations)
}

# Read-only ldap replicas in codfw
node /^ldap-replica200[5-6]\.wikimedia\.org$/ {
    role(openldap::replica)
}

# Logging data nodes (codfw)
node /^logstash20(0[123]|2[6789]|3[34567])\.codfw\.wmnet$/ {
    role(logging::opensearch::data)
}

# Logging collector nodes (codfw)
node /^logstash20(2[345]|3[012])\.codfw\.wmnet$/ {
    role(logging::opensearch::collector)
}

# Logging data nodes (eqiad)
node /^logstash10(1[012]|2[6789]|3[34567])\.eqiad\.wmnet$/ {
    role(logging::opensearch::data)
}

# Logging collector nodes (eqiad)
node /^logstash10(2[345]|3[012])\.eqiad\.wmnet$/ {
    role(logging::opensearch::collector)
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
node /^lvs20(1[1234])\.codfw\.wmnet$/ {
    role(lvs::balancer)
}

# ESAMS lvs servers
node /^lvs300[567]\.esams\.wmnet$/ {
    role(lvs::balancer)
}

# ULSFO lvs servers
node /^lvs40(0[89]|1[0])\.ulsfo\.wmnet$/ {
    role(lvs::balancer)
}

# EQSIN lvs servers
node /^lvs500[456]\.eqsin\.wmnet$/ {
    role(lvs::balancer)
}

# DRMRS lvs servers
node /^lvs600[123]\.drmrs\.wmnet$/ {
    role(lvs::balancer)
}

node /^maps10(0[5-8]|1[0])\.eqiad\.wmnet$/ {
    role(maps::replica)
}

# testing buster master - maps2.0 migration
node 'maps1009.eqiad.wmnet' {
    role(maps::master)
}

node /^maps20(0[5-8]|10)\.codfw\.wmnet$/ {
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

node /^mc10(3[7-9]|4[0-9]|5[0-4])\.eqiad\.wmnet$/ {
    role(mediawiki::memcached)
}

node /^mc20(3[8-9]|4[0-9]|5[0-5])\.codfw\.wmnet$/ {
    role(mediawiki::memcached)
}

node /^mc-gp100[1-3]\.eqiad\.wmnet$/ {
    role(mediawiki::memcached::gutter)
}

node /^mc-gp200[1-3]\.codfw\.wmnet$/ {
    role(mediawiki::memcached::gutter)
}

# new mc-wf nodes T313963
node /^mc-wf100[12]\.eqiad\.wmnet$/ {
    role(memcached)
}

# New mc-wf nodes T313966
node /^mc-wf200[1-2]\.codfw\.wmnet$/ {
    role(memcached)
}

node /^ml-cache100[123]\.eqiad\.wmnet$/ {
    role(ml_cache::storage)
}

node /^ml-cache200[123]\.codfw\.wmnet$/ {
    role(ml_cache::storage)
}

node /^ml-etcd100[123]\.eqiad\.wmnet$/ {
    role(etcd::v3::ml_etcd)
}

node /^ml-etcd200[123]\.codfw\.wmnet$/ {
    role(etcd::v3::ml_etcd)
}

node /^ml-serve-ctrl100[12]\.eqiad\.wmnet$/ {
    role(ml_k8s::master)
}

node /^ml-serve-ctrl200[12]\.codfw\.wmnet$/ {
    role(ml_k8s::master)
}

node /^ml-serve200[1-8]\.codfw\.wmnet$/ {
    role(ml_k8s::worker)
}

node /^ml-serve100[1-8]\.eqiad\.wmnet$/ {
    role(ml_k8s::worker)
}

# New ml-staging etcd T302503
node /^ml-staging-etcd200[123]\.codfw.wmnet$/ {
    role(etcd::v3::ml_etcd::staging)
}

# New ml-staging ctrl T302503
node /^ml-staging-ctrl200[12]\.codfw.wmnet$/ {
    role(ml_k8s::staging::master)
}

# New ml-staging nodes T294946
node /^ml-staging200[12]\.codfw\.wmnet$/ {
    role(ml_k8s::staging::worker)
}

node 'moscovium.eqiad.wmnet' {
    role(requesttracker)
}

node /^moss-fe1002\.eqiad\.wmnet$/ {
    role(insetup::data_persistence)
}

node /^moss-fe1001\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include lvs::realserver # lint:ignore:wmf_styleguide
}

# New moss-be nodes T276637
node /^moss-be100[12]\.eqiad\.wmnet$/ {
    role(insetup::data_persistence)
}

# New moss-be nodes T276642
node /^moss-be200[12]\.codfw\.wmnet$/ {
    role(insetup::data_persistence)
}

# New moss-fe nodes T275513
node /^moss-fe2001\.codfw\.wmnet$/ {
    role(swift::proxy)
    include lvs::realserver # lint:ignore:wmf_styleguide
}

node /^moss-fe2002\.codfw\.wmnet$/ {
    role(insetup::data_persistence)
}

node /^ms-backup100[12]\.eqiad\.wmnet$/ {
    role(mediabackup::worker)
}

node /^ms-backup200[12]\.codfw\.wmnet$/ {
    role(mediabackup::worker)
}

node /^ms-fe1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include lvs::realserver  # lint:ignore:wmf_styleguide
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe2\d\d\d\.codfw\.wmnet$/ {
    role(swift::proxy)
    include lvs::realserver  # lint:ignore:wmf_styleguide
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

# rack B6
node /^mw14(7[2-9]|8[01])\.eqiad\.wmnet$/ {
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

# rack C8
node /^mw14(09|1[13])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row D

# rack D1
node /^mw13(49|5[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack D1
node /^mw148[78]\.eqiad\.wmnet$/ {
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

# Row F
node /^mw149[6-8]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

## Api servers

# Row A

# rack A5
node /^mw13(8[68]|9[02])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack A8
node /^mw146[2-5]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row B

# rack B3 and B5
node /^mw1(39[468]|40[024])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack B6
node /^mw147[01]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row C

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

# Row E
node /^mw14(89|9[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mediawiki maintenance server (periodic jobs)
# mwmaint1002 replaced mwmaint1001 (T201343) which replaced terbium (T192185)
# mwmaint2002 replaced mwmaint2001 (T274170, T275905)
node 'mwmaint1002.eqiad.wmnet', 'mwmaint2002.codfw.wmnet' {
    role(mediawiki::maintenance)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Due to T329366, we are moving some parsoid servers to the jobrunner
# cluser in both datacenters.

# Row A

# rack A8
node /^mw14(5[7-9]|6[01])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row B

# rack B6
node /^mw146[6-9]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

node /^parse101[3-6]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack C5
node /^mw148[2-6]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row F
node /^mw149[45]\.eqiad\.wmnet$/ {
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
node /^mw23(8[1-2]|9[4-5])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

node /^mw2(29[1-9]|300)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw23(7[7-9]|80|8[3-9]|9[0-3])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw2(39[6-9]|40[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack A5 (T279599)
node /^mw240[3-5]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw240[6-9]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw241[01]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack A5 (T331609)
node /^mw242[23]\.codfw\.wmnet/ {
    role(mediawiki::appserver::api)
}

node /^mw242[01]\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

# rack A6
node /^mw230[13579]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A6 (T331609)
node /^mw2424\.codfw\.wmnet/ {
    role(mediawiki::appserver::api)
}

node /^mw2425\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

node /^mw242[67]\.codfw\.wmnet/ {
    role(mediawiki::jobrunner)
}
# Row B

# rack B3
node /^mw22(6[89]|70)\.codfw\.wmnet$/ {
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

# rack B6 (T331609)

node /^mw24(2[89]|30)\.codfw\.wmnet/ {
    role(mediawiki::jobrunner)
}

node /^mw2431\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

# rack B8 (T331609)
node /^mw243[23]\.codfw\.wmnet/ {
    role(mediawiki::appserver)
}

node /^mw243[45]\.codfw\.wmnet/ {
    role(mediawiki::appserver::api)
}

# Row C

# rack C6
node /^mw23(59|6[135])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C6
node /^mw23(5[1357])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

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

# rack C1 (T331609)
node /^mw243[67]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw243[89]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack C5 (T331609)
node /^mw244(0|[23])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

node /^mw2441\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
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

# rack D5 (T331609)
node /^mw244[4-6]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

node /^mw2447\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack D6 (T331609)
node /^mw244[89]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

node /^mw245[01]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
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

    interface::alias { 'wiki-mail-eqiad.wikimedia.org':  # lint:ignore:wmf_styleguide
        ipv4 => '208.80.154.91',
        ipv6 => '2620:0:861:3:208:80:154:91',
    }
}

node 'mx2001.wikimedia.org' {
    role(mail::mx)

    interface::alias { 'wiki-mail-codfw.wikimedia.org':  # lint:ignore:wmf_styleguide
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

node /^netmon[0-9]{4}\.wikimedia\.org$/ {
    role(netmon)
}

# Network insights (netflow/pmacct, etc.)
node /^netflow[1-6]00[1-9]\.(eqiad|codfw|ulsfo|esams|eqsin|drmrs)\.wmnet$/ {
    role(netinsights)
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
}

node /^orespoolcounter[12]00[34]\.(codfw|eqiad)\.wmnet$/ {
    role(orespoolcounter)
}

node 'vrts1001.eqiad.wmnet' {
    role(vrts)
}

# T323515: WIP
node 'vrts2001.codfw.wmnet' {
    role(vrts)
}

# new parsoid nodes - codfw (T243112, T247441) - eqiad (T299573)
node /^parse20(0[1-9]|1[0-9]|20)\.codfw\.wmnet$/ {
    role(parsoid)
}

node /^parse10(0[1-9]|1[012789]|2[0-4])\.eqiad\.wmnet$/ {
    role(parsoid)
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
node /^ping[123]003\.(eqiad|codfw|esams)\.wmnet$/ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(planet)
}

node /^poolcounter[12]00[345]\.(codfw|eqiad)\.wmnet$/ {
    role(poolcounter::server)
}

node /^prometheus200[56]\.codfw\.wmnet$/ {
    role(prometheus)
}

node /^prometheus100[56]\.eqiad\.wmnet$/ {
    role(prometheus)
}

node /^prometheus[3456]00[12]\.(esams|ulsfo|eqsin|drmrs)\.wmnet$/ {
    role(prometheus::pop)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]00[234]\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
}

# New Puppetmaster node T334479
node 'puppetmaster1006.eqiad.wmnet' {
    role(insetup::infrastructure_foundations)
}

node /^puppetboard[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard)
}

node /^puppetboard[12]003\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard::bookworm)
}

node /^puppetdb[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetdb)
}

# Leave this on the old infrastructure for now
node /^puppetdb2003\.codfw\.wmnet$/ {
    role(puppetdb)
}

node /^puppetdb1003\.eqiad\.wmnet$/ {
    role(puppetdb::bookworm)
}

node /^puppetserver[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetserver)
}

# pybal-test2003 VM is used for pybal testing/development
node /^pybal-test2003\.codfw\.wmnet$/ {
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
node /^releases[12]00[23]\.(codfw|eqiad)\.wmnet$/ {
    role(releases)
}

# New relforge servers T241791 (provision), T262211 (service impl.)
node /^relforge100[3-4]\.eqiad\.wmnet$/ {
    role(elasticsearch::relforge)
}

# restbase eqiad cluster
node /^restbase10(1[6-9]|2[0-9]|3[0-3])\.eqiad\.wmnet$/ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(09|1[0-9]|2[0-7])\.codfw\.wmnet$/ {
    role(restbase::production)
}

# New cassandra dev nodes T324113
node /^cassandra-dev200[1-3]\.codfw\.wmnet$/ {
    role(cassandra_dev)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(rpkivalidator)
}

# https://people.wikimedia.org - self-service file hosting
# VMs on bookworm, access for all shell users (T280989, T338827)
node 'people1004.eqiad.wmnet', 'people2003.codfw.wmnet' {
    role(microsites::peopleweb)
}

# scandium is a parsoid test server. it replaced ruthenium.
# This is now just like an MW appserver plus parsoid repo.
# roundtrip and visualdiff testing moved to testreduce1001 (T257906)
node 'scandium.eqiad.wmnet' {
    role(parsoid::testing)
}

node /^schema[12]00[3-4].(eqiad|codfw).wmnet$/ {
    role(eventschemas::service)
}

# See T258189
node /^search-loader[12]001.(eqiad|codfw).wmnet$/ {
    role(search::loader)
}

# new sessionstore servers via T209393 & T209389
node /^sessionstore[1-2]00[1-3].(eqiad|codfw).wmnet$/ {
    role(sessionstore)
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::rw)
}

node 'mirror1001.wikimedia.org' {
    role(mirrors)
}

# The hosts contain all the tools and libraries to access
# the Analytics Cluster services.
node /^stat100[4-9]\.eqiad\.wmnet$/ {
    role(statistics::explorer)
}

# New stat nodes T299466 and T307399
node /^stat101[0]\.eqiad\.wmnet$/ {
    role(insetup::data_engineering)
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
# They should also be added to the dumps/scap repo in dumps_targets,
# https://gerrit.wikimedia.org/r/plugins/gitiles/operations/dumps/scap
node /^snapshot1008\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::dumper_misc_crons_only)
}
node /^snapshot1010\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::dumper_monitor)
}
node /^snapshot1009\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::testbed)
}
node /^snapshot101[1-2]\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::dumper)
}
node /^snapshot1013\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::dumper)
}

node /^snapshot101[4567]\.eqiad\.wmnet$/ {
    role(dumps::generation::worker::testbed)
}

# Servers for SRE tests which are not suitable for Cloud VPS
node /^sretest100[1-3]\.eqiad\.wmnet$/ {
    role(sretest)
}

# Servers for SRE tests in codfw
node /^sretest200[1-2]\.codfw\.wmnet$/ {
    role(insetup::infrastructure_foundations)
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

node /^thanos-be100[1234]\.eqiad\.wmnet$/ {
    role(thanos::backend)
}

node /^thanos-be200[1234]\.codfw\.wmnet$/ {
    role(thanos::backend)
}

node /^thanos-fe100[1234]\.eqiad\.wmnet$/ {
    role(thanos::frontend)
}

node /^thanos-fe200[1234]\.codfw\.wmnet$/ {
    role(thanos::frontend)
}

# Thumbor servers for MediaWiki image scaling
node /^thumbor100[1256]\.eqiad\.wmnet$/ {
    role(thumbor::mediawiki)
}

node /^thumbor200[3456]\.codfw\.wmnet$/ {
    role(thumbor::mediawiki)
}

# deployment servers
node /^deploy[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(deployment_server::kubernetes)
}

node /^urldownloader[12]00[12]\.wikimedia\.org$/ {
    role(insetup::infrastructure_foundations)
}

# https://wikitech.wikimedia.org/wiki/Url-downloader
node /^urldownloader[12]00[34]\.wikimedia\.org$/ {
    role(url_downloader)
}

# These are hypervisors that use local storage for their VMs
#  rather than ceph. This is necessary for low-latency workloads
#  like etcd.
node /^cloudvirtlocal100[1-3]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
}


# cloudvirts using Ceph backend storage
# https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Ceph
node /^cloudvirt102[5-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# new cloudvirt servers T305194 and T299574
node /^cloudvirt10(3[0-9]|4[0-9]|5[0-9]|6[0-1])\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# Private virt hosts for wdqs T221631
node /^cloudvirt-wdqs100[123]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
}

node /^wcqs100[123]\.eqiad\.wmnet$/ {
    role(wcqs::public)
}

node /^wcqs200[123]\.codfw\.wmnet$/ {
    role(wcqs::public)
}

node /^wdqs10(09|10)\.eqiad\.wmnet$/ {
    role(wdqs::test)
}

node /^wdqs100[38]\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs1011\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs100[4-7]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}

node /^wdqs101[2-6]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}
# wdqs200[56] soon to be decommed T326689
node /^wdqs200[56]\.codfw\.wmnet$/ {
    role(wdqs::internal)
}

node /^(wdqs2008|wdqs201[45])\.codfw\.wmnet$/ {
    role(wdqs::internal)
}
# wdqs2004 soon to be decommed T326689
node /^wdqs2004\.codfw\.wmnet$/ {
    role(wdqs::public)
}

node /^(wdqs200[7,9]|wdqs201[1-3]|wdqs201[6-9]|wdqs202[0-2])\.codfw\.wmnet$/ {
    role(wdqs::public)
}

node /^webperf[12]003\.(codfw|eqiad)\.wmnet$/ {
    role(webperf::processors_and_site)
}

node 'arclamp2001.codfw.wmnet' {
    role(webperf::profiling_tools)
}

node 'arclamp1001.eqiad.wmnet' {
    role(webperf::profiling_tools)
}

node 'xhgui1001.eqiad.wmnet', 'xhgui2001.codfw.wmnet' {
    role(webperf::xhgui)
}

node 'xhgui1002.eqiad.wmnet', 'xhgui2002.codfw.wmnet' {
  role(insetup::observability)
}

node default {
    if $::realm == 'production' and !$::_role {
        fail('No puppet role has been assigned to this node.')
    } elsif $::realm == 'labs' {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require role::wmcs::instance  # lint:ignore:wmf_styleguide
    }
}
