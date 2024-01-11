# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

# NOTE:
#
#  Node definitions should use the regex form and be anchored with a ^ for the
#  start of the hostname. The top level domain name (.wmnet or .org) should not
#  be included, nor a trailing $ anchor, this format allows dev hosts to also
#  match the production node defs, e.g.
#
#      node /^foo1001.eqiad\./ {
#          role(baz)
#      }
#
#  Matches both foo1001.eqiad.wmnet as well as foo1001.eqiad.dev.lan

# Node definitions (alphabetic order)

# Ganeti VMs for acme-chief service
node /^acmechief1001\.eqiad\./ {
    role(acme_chief)
}

node /^acmechief1002\.eqiad\./ {
    role(acme_chief)
}

node /^acmechief2001\.codfw\./ {
    role(acme_chief)
}

node /^acmechief2002\.codfw\./ {
    role(acme_chief)
}

# Ganeti VMs for acme-chief staging environment
node /^acmechief-test1001\.eqiad\./ {
    role(acme_chief)
}

node /^acmechief-test2001\.codfw\./ {
    role(acme_chief)
}

#old namenodes - to be decommissioned
node /^an-master100[12]\.eqiad\./ {
    role(insetup::data_engineering)
}

# The Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node /^an-master1003\.eqiad\./ {
    role(analytics_cluster::hadoop::master)
}

# The Hadoop (stanby) master node:
# - primary active NameNode
# - YARN ResourceManager
node /^an-master1004\.eqiad\./ {
    role(analytics_cluster::hadoop::standby)
}

node /^an-coord100[134]\.eqiad\./ {
    role(analytics_cluster::coordinator)
}

node /^an-coord1002\.eqiad\./ {
    role(analytics_cluster::coordinator::replica)
}

node /^an-db100[1-2]\.eqiad\./ {
    role(analytics_cluster::postgresql)
}

# New an-mariadb nodes T321119
node /^an-mariadb100[1-2]\.eqiad\./ {
    role(analytics_cluster::mariadb)
}

node /^an-launcher1002\.eqiad\./ {
    role(analytics_cluster::launcher)
}

# Analytics Hadoop test cluster
node /^an-test-master1001\.eqiad\./ {
    role(analytics_test_cluster::hadoop::master)
}

node /^an-test-master1002\.eqiad\./ {
    role(analytics_test_cluster::hadoop::standby)
}

node /^an-test-worker100[1-3]\.eqiad\./ {
    role(analytics_test_cluster::hadoop::worker)
}

# new an-test-coord1001  T255518
node /^an-test-coord1001\.eqiad\./ {
    role(analytics_test_cluster::coordinator)
}

node /^an-test-client1002\.eqiad\./ {
    role(analytics_test_cluster::client)
}

node /^an-test-ui1001\.eqiad\./ {
    role(analytics_test_cluster::hadoop::ui)
}

node /^an-test-presto1001\.eqiad\./ {
    role(analytics_test_cluster::presto::server)
}

# analytics1058-analytics1077 and an-worker10XX
# are Analytics Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^analytics10(7[0-7])\.eqiad\./ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker10(7[89]|8[0-9]|9[0-9])\.eqiad\./ {
    role(analytics_cluster::hadoop::worker)
}

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker11(0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-6])\.eqiad\./ {
    role(analytics_cluster::hadoop::worker)
}

# T349936
node /^an-worker11(5[7-9]|6[0-9]|7[0-5])\.eqiad\./ {
    role(insetup::data_engineering)
}

# Staging environment of Superset and Turnilo
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo
node /^an-tool1005\.eqiad\./ {
    role(analytics_cluster::ui::superset::staging)
}

# turnilo.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot
node /^an-tool1007\.eqiad\./ {
    role(analytics_cluster::turnilo)
}

# yarn.wikimedia.org
node /^an-tool1008\.eqiad\./ {
    role(analytics_cluster::hadoop::yarn)
}

# hue.wikimedia.org
node /^an-tool1009\.eqiad\./ {
    role(analytics_cluster::hadoop::ui)
}

node /^an-tool1010\.eqiad\./ {
    role(analytics_cluster::ui::superset)
}

node /^an-tool1011\.eqiad\./ {
    role(analytics_cluster::turnilo::staging)
}

# analytics-research instance of Apache Airflow
node /^an-airflow1002\.eqiad\./ {
    role(analytics_cluster::airflow::research)
}

# analytics-platform-eng instance of Apache Airflow
node /^an-airflow1004\.eqiad\./ {
    role(analytics_cluster::airflow::platform_eng)
}

node /^an-airflow1005\.eqiad\./ {
    role(analytics_cluster::airflow::search)
}

# product-analytics instance of Apache Airflow
node /^an-airflow1006\.eqiad\./ {
    role(analytics_cluster::airflow::analytics_product)
    }

# WMDE instance of Apache Airflow
node /^an-airflow1007\.eqiad\./ {
    role(analytics_cluster::airflow::wmde)
    }

# Analytics Zookeeper cluster
node /^an-conf100[1-3]\.eqiad\./ {
    role(analytics_cluster::zookeeper)
}

# Analytics Presto nodes. 1001 - 1015
node /^an-presto10(0[1-9]|1[0-5])\.eqiad\./ {
    role(analytics_cluster::presto::server)
}

# Analytics Web Node.
node /^an-web1001\.eqiad\./ {
    role(analytics_cluster::webserver)
}

# API Feature Usage log pipeline procesors
node /^apifeatureusage[12]001\.(eqiad|codfw)\./ {
    role(apifeatureusage::logstash)
}

# notification server for Phabricator (T257617 and T322369)
node /^aphlict(100[12]|2001)\.(eqiad|codfw)\./ {
    role(aphlict)
}

node /^apt[12]001\.wikimedia\./ {
    role(apt_repo)
}

node /^apt1002\.wikimedia\./ {
    role(apt_repo)
}

node /^apt2002\.wikimedia\./ {
    role(insetup::infrastructure_foundations)
}

# apt-staging host
node /^apt-staging2001\.codfw\./ {
    role(apt_staging)
}

# Analytics Query Service
node /^aqs10(1[0-9]|2[0-1])\.eqiad\./ {
    role(aqs)
}

node /^aqs200[1-9]|aqs201[0-2]\.codfw\./ {
    role(aqs)
}

# New Archiva host on Buster
# T254890
node /^archiva1002\.wikimedia\./ {
    role(archiva)
}

# etcd cluster for aux kubernetes cluster
node /^aux-k8s-etcd100[1-3]\.eqiad\./ {
    role(etcd::v3::aux_k8s_etcd)
}

# control-plane servers for aux kubernetes cluster
node /^aux-k8s-ctrl100[1-2]\.eqiad\./ {
    role(aux_k8s::master)
}

# worker nodes for aux kubernetes cluster
node /^aux-k8s-worker100[1-2]\.eqiad\./ {
    role(aux_k8s::worker)
}

# Primary bacula director and storage daemon
node /^backup1001\.eqiad\./ {
    role(backup)
}
# eqiad backup generation for External Storage databases
node /^backup1002\.eqiad\./ {
    role(dbbackups::content)
}

# eqiad bacula storage for External Storage databases
node /^backup1003\.eqiad\./ {
    role(backup::es)
}

# eqiad media backup storage
node /^backup100[4567]\.eqiad\./ {
    role(mediabackup::storage)
}
# temporary-ish expansion
node /^backup1011\.eqiad\./ {
    role(mediabackup::storage)
}

# new backup storage eqiad T294974
node /^backup1008\.eqiad\./ {
    role(backup::databases)
}

# new backup storage eqiad T307048
node /^backup1009\.eqiad\./ {
    role(backup::production)
}

# new backup node T326684
node /^backup1010\.eqiad\./ {
    role(insetup::data_persistence)
}

# codfw storage daemon
node /^backup2001\.codfw\./ {
    role(backup::offsite)
}
# codfw backup generation for External Storage databases
node /^backup2002\.codfw\./ {
    role(dbbackups::content)
}

# codfw bacula for External Storage DBs
node /^backup2003\.codfw\./ {
    role(backup::es)
}

# codfw media backup storage
node /^backup200[4567]\.codfw\./ {
    role(mediabackup::storage)
}
# temporary-ish expansion
node /^backup2011\.codfw\./ {
    role(mediabackup::storage)
}

# New backup node for codfw T294973
node /^backup2008\.codfw\./ {
    role(backup::databases)
}

# New backup node for codfw T307049
node /^backup2009\.codfw\./ {
    role(backup::production)
}

# New backup node for codfw T326965
node /^backup2010\.codfw\./ {
    role(insetup::data_persistence)
}

node /^backupmon1001\.eqiad\./ {
    role(dbbackups::monitoring)
}

node /^bast1003\.wikimedia\./ {
    role(bastionhost)
}

node /^bast2003\.wikimedia\./ {
    role(bastionhost)
}

node /^bast3007\.wikimedia\./ {
    role(bastionhost)
}

node /^bast4005\.wikimedia\./ {
    role(bastionhost)
}

node /^bast5004\.wikimedia\./ {
    role(bastionhost)
}

node /^bast6003\.wikimedia\./ {
    role(bastionhost)
}

# Debian package/docker images building host in production
node /^build2001\.codfw\./ {
    role(builder)
}

node /^centrallog[0-9]{4}\.(eqiad|codfw)\./ {
    role(syslog::centralserver)
}

node /^chartmuseum[12]001\.(eqiad|codfw)\./ {
    role(chartmuseum)
}

node /^cloudgw100[12]\.eqiad\./ {
    role(wmcs::cloudgw)
}

node /^cloudgw200[23]-dev\.codfw\./ {
    role(wmcs::cloudgw)
}

node /^cloudlb200[123]-dev\.codfw\./ {
    role(wmcs::cloudlb)
}

node /^cloudcephosd200[123]-dev\.codfw\./ {
    role(wmcs::ceph::osd)
}

# New ceph node codfw T349934
node /^cephosd200[1-3]\.codfw\./ {
    role(insetup::data_engineering)
}

node /^cloudcephmon200[4-6]-dev\.codfw\./ {
    role(wmcs::ceph::mon)
}

# The following nodes pull data periodically
# from the Analytics Hadoop cluster. Every new
# host needs a kerberos keytab generated,
# according to the details outlined in the
# role's hiera configuration.
node /^clouddumps100[12]\.wikimedia\./ {
    role(dumps::distribution::server)
}

# All gerrit servers (swap master status in hiera)
node /^gerrit(1003|2002)\.wikimedia\./ {
    role(gerrit)
}

# Zookeeper and Etcd discovery service nodes
node /^conf200[456]\.codfw\./ {
    role(configcluster)
}

node /^conf100[789]\.eqiad\./ {
    role(configcluster)
}

node /^config-master[12]001\.(eqiad|codfw)\./ {
    role(config_master)
}

# Test zookeeper in eqiad
node /^zookeeper-test1002\.eqiad\./ {
    role(zookeeper::test)
}

# Test kafka cluster
node /^kafka-test10(10|0[6-9])\.eqiad\./ {
    role(kafka::test::broker)
}

node /^(contint1002|contint2002)\.wikimedia\./ {
    role(ci)
}

node /^cp11(0[02468]|1[024])\.eqiad\./ {
    role(cache::text)
}

node /^cp11(0[13579]|1[135])\.eqiad\./ {
    role(cache::upload)
}

node /^cp20(2[79]|3[13579]|41)\.codfw\./ {
    role(cache::text)
}

node /^cp20(28|3[02468]|4[02])\.codfw\./ {
    role(cache::upload)
}

#
# esams caches
#

node /^cp30(6[6789]|7[0123])\.esams\./ {
    role(cache::text)
}

node /^cp30(7[456789]|8[01])\.esams\./ {
    role(cache::upload)
}

#
# ulsfo caches
#

node /^cp40(4[56789]|5[012])\.ulsfo\./ {
    role(cache::upload)
}

node /^cp40(3[789]|4[01234])\.ulsfo\./ {
    role(cache::text)
}

#
# eqsin caches
#

# Temp setup, will go away once wiped
node /^cp50(1[3456])\.eqsin\./ {
    role(insetup::traffic)
}

node /^cp50(2[56789]|3[012])\.eqsin\./ {
    role(cache::upload)
}

node /^cp50(1[789]|2[01234])\.eqsin\./ {
    role(cache::text)
}

#
# cp drmrs nodes
#

node /^cp600[1-8]\.drmrs\./ {
    role(cache::upload)
}

node /^cp60(09|1[0-6])\.drmrs\./ {
    role(cache::text)
}

node /^crm2001\.codfw\./ {
    role(crm)
}

node /^cumin1001\.eqiad\./ {
    role(cluster::management)
}

node /^cumin1002\.eqiad\./ {
    role(cluster::management)
}

node /^cumin2002\.codfw\./ {
    role(cluster::management)
}

node /^cuminunpriv1001\.eqiad\./ {
    role(cluster::unprivmanagement)
}

node /^datahubsearch100[1-3]\.eqiad\./ {
    role(analytics_cluster::datahub::opensearch)
}

## Analytics Backup Multi-instance
node /^db1208\.eqiad\./ {
    role(mariadb::misc::analytics::backup)
}

# s1 (enwiki) core production dbs on eqiad
node /^db1(106|135|163|169|184|186|206|207|218|219|228|232|234)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1196\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
# See also db2167 and db2170 below
node /^db2(103|112|116|130|145|146|153|174|176|188)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2173\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on eqiad
# See also db1146, db1170 below
node /^db1(162|182|188|197|222|229|233)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1156\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
# See also db2170 and db2138 below
node /^db2(104|107|125|148|175|189)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2126\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on eqiad
node /^db1(157|166|175|189|198|223)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1212\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on codfw
node /^db2(105|109|127|149|177|190)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2156\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s4 (commons) core production dbs on eqiad
# See also db1144 and db1146 below
node /^db1(149|160|190|199|238|241|242|243|247|248|249)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1221\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# Testing cluster
# Testing master
node /^db1124\.eqiad\./ {
    role(mariadb::core_test)
}

# Testing replica
node /^db1125\.eqiad\./ {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
# See also db2137 and db2138 below
node /^db2(106|110|119|136|140|147|172|179)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2155\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on eqiad
# See also db1213 and db1144 below
node /^db1(183|185|200|210|230)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1161\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
# See also db2171 and db2137 below
node /^db2(111|113|123|157|178|192)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2128\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s6 (frwiki, jawiki, ruwiki) core production dbs on eqiad
# See also db1213 below
node /^db1(168|173|180|187|201|224|231)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1165\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s6 core production dbs on codfw
# See also db2169 and db2171 below
node /^db2(114|117|124|129|151|180|193)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2158\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# See also db1170 below
node /^db1(069|174|178|181|191|194|202|227|236)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1158\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# See also db2168 and db2169 below
node /^db2(108|118|120|121|122|150|182)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2159\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on eqiad
node /^db1(172|177|192|193|203|209|211|214|226)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1167\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on codfw
# See also db2167 db2168 below
node /^db2(152|154|161|162|163|165|166|181|195)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2164\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# multi-instance hosts with multiple shards
node /^db1(144|146|170|213)\.eqiad\./ {
    role(mariadb::core_multiinstance)
}
node /^db2(137|138|167|168|169|170|171|194)\.codfw\./ {
    role(mariadb::core_multiinstance)
}

## x1 shard
# eqiad
node /^db1(179|220|237)\.eqiad\./ {
    role(mariadb::core)
}

# codfw
node /^db2(096|115|131|191)\.codfw\./ {
    role(mariadb::core)
}

# x2 shard
# eqiad
node /^db11(51|52|53)\.eqiad\./ {
    role(mariadb::objectstash)
}

# codfw
node /^db21(42|43|44)\.codfw\./ {
    role(mariadb::objectstash)
}

# New db hosts to be setup T342166
node /^db12(39|35|39|40|44|45|46)\.eqiad\./ {
    role(insetup::data_persistence)
}
## m1 shard
# See also multiinstance misc hosts db1217, db2160 below

# m1 master
node /^db1164\.eqiad\./ {
    role(mariadb::misc)
}

# m1 codfw master
node /^db2132\.codfw\./ {
    role(mariadb::misc)
}

## m2 shard
# See also multiinstance misc hosts db1217, db2160 below

# old master
node /^db1195\.eqiad\./ {
    role(mariadb::misc)
}

# Temporary testing for T341489
node /^db1118\.eqiad\./ {
    role(mariadb::misc)
}

# m2 codfw master
node /^db2133\.codfw\./ {
    role(mariadb::misc)
}

## m3 shard
# See also multiinstance misc hosts db1217, db2160 below

# m3 master
node /^db1159\.eqiad\./ {
    role(mariadb::misc::phabricator)
}

# m3 codfw master
node /^db2134\.codfw\./ {
    role(mariadb::misc::phabricator)
}

## m5 shard
# See also multiinstance misc hosts db1217, db2160 below

# m5 master
node /^db1176\.eqiad\./ {
    role(mariadb::misc)
}

# m5 codfw master
node /^db2135\.codfw\./ {
    role(mariadb::misc)
}

# misc multiinstance
node /^db1217\.eqiad\./ {
    role(mariadb::misc::multiinstance)
}

node /^db2160\.codfw\./ {
    role(mariadb::misc::multiinstance)
}

# sanitarium hosts
node /^db1(154|155)\.eqiad\./ {
    role(mariadb::sanitarium_multiinstance)
}

node /^db2(186|187)\.codfw\./ {
    role(mariadb::sanitarium_multiinstance)
}

# zarcillo master
node /^db1215\.eqiad\./ {
    role(mariadb::misc::db_inventory)
}

# zarcillo slave
node /^db2185\.codfw\./ {
    role(mariadb::misc::db_inventory)
}

# Orchestrator central node (VM on ganeti)
node /^dborch1001\.wikimedia\./ {
    role(orchestrator)
}

# backup1-eqiad section (datacenter-specific backup metadata hosts)
node /^(db1204|db1205)\.eqiad\./ {
    role(mariadb::misc)
}
# backup1-codfw section (datacenter-specific backup metadata hosts)
node /^db2183|db2184\.codfw\./ {
    role(mariadb::misc)
}

# eqiad backup sources
## s1 & s2, bullseye
node /^db1139\.eqiad\./ {
    role(mariadb::backup_source)
}
## s1 & s3, bullseye
node /^db1140\.eqiad\./ {
    role(mariadb::backup_source)
}
## s4 & s5, bullseye
node /^db1145\.eqiad\./ {
    role(mariadb::backup_source)
}
## s3 & s4, bullseye
node /^db1150\.eqiad\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node /^db1171\.eqiad\./ {
    role(mariadb::backup_source)
}
## s2, s6 & x1, 10.6, bullseye
node /^db1225\.eqiad\./ {
    role(mariadb::backup_source)
}
## s5, s8 & x1, bullseye
node /^db1216\.eqiad\./ {
    role(mariadb::backup_source)
}

# codfw backup sources
## s2, s6 & x1, 10.6, bullseye
node /^db2097\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node /^db2098\.codfw\./ {
    role(mariadb::backup_source)
}
## s4, bullseye
node /^db2099\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node /^db2100\.codfw\./ {
    role(mariadb::backup_source)
}
## s2, s5, & x1, bullseye
node /^db2101\.codfw\./ {
    role(mariadb::backup_source)
}
## s3 & s4, bullseye
node /^db2139\.codfw\./ {
    role(mariadb::backup_source)
}
## s1, bullseye
node /^db2141\.codfw\./ {
    role(mariadb::backup_source)
}

# backup testing hosts
node /^db1133\.eqiad\./ {
    role(mariadb::core_test)
}

node /^db2102\.codfw\./ {
    role(mariadb::core_test)
}

# Analytics production replicas
node /^dbstore100[789]\.eqiad\./ {
    role(mariadb::analytics_replica)
}

# database-provisioning and short-term/postprocessing backups servers

node /^dbprov1001\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1002\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1003\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1004\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov2001\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2002\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2003\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2004\.codfw\./ {
    role(dbbackups::metadata)
}

# Active eqiad proxies for misc databases
node /^dbproxy10(12|13|14|15|16|20|21|22|23|24|25|26|27)\.eqiad\./ {
    role(mariadb::proxy::master)
}

# Passive codfw proxies for misc databases
node /^dbproxy20(01|02|03|04)\.codfw\./ {
    role(mariadb::proxy::master)
}

node /^debmonitor[12]002\.(codfw|eqiad)\./ {
    role(debmonitor::server)
}

node /^debmonitor[12]003\.(codfw|eqiad)\./ {
    role(debmonitor::server)
}

node /^dns[1-9][0-9]{3}\.wikimedia\./ {
    role(dnsbox)
}

node /^doc[12]00[123]\.(codfw|eqiad)\./ {
  role(doc)
}

# Wikidough (T252132)
node /^(doh[1-9][0-9]{3})\.wikimedia\./ {
    role(wikidough)
}

# durum for Wikidough (T289536)
node /^durum[1-9][0-9]{3}\./ {
    role(durum)
}

# Dragonfly Supernode (T286054)
node /^dragonfly-supernode[12]001\.(codfw|eqiad)\./ {
    role(dragonfly::supernode)
}

# Druid analytics-eqiad (non public) servers.
# These power internal backends and queries.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^an-druid100[1-5]\.eqiad\./ {
    role(druid::analytics::worker)
}

node /^an-test-druid1001\.eqiad\./ {
    role(druid::test_analytics::worker)
}

# Druid public-eqiad servers.
# These power AQS and wikistats 2.0 and contain non sensitive datasets.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid10(0[7-9]|1[0-1])\.eqiad\./ {
    role(druid::public::worker)
}

# new dse-k8s-crtl control plane servers T310171
node /^dse-k8s-ctrl100[12]\.eqiad\./ {
    role(dse_k8s::master)
}

# new dse-k8s-etcd etcd cluster servers T310170
node /^dse-k8s-etcd100[1-3]\.eqiad\./ {
    role(etcd::v3::dse_k8s_etcd)
}

# new dse-k8s-workers T29157 and T3074009
node /^dse-k8s-worker100[1-8]\.eqiad\./ {
    role(dse_k8s::worker)
}

# to be decommed eventually
node /^dumpsdata1001\.eqiad\./ {
    role(dumps::generation::server::spare)
}
# nfs server for xml dumps generation, also rsyncs xml dumps
# data to fallback nfs server(s)
node /^dumpsdata1006\.eqiad\./ {
    role(dumps::generation::server::xmldumps)
}

# nfs server for misc dumps generation, also rsyncs misc dumps
node /^dumpsdata1003\.eqiad\./ {
    role(dumps::generation::server::misccrons)
}

# fallback nfs server for dumps generation, also
# will rsync data to web servers
node /^dumpsdata1007\.eqiad\./ {
    role(dumps::generation::server::xmlfallback)
}

# new dumpsdata servers T283290
node /^dumpsdata100[245]\.eqiad\./ {
    role(dumps::generation::server::spare)
}

node /^elastic105[3-9]\.eqiad\./ {
    role(elasticsearch::cirrus)
}

node /^(elastic106[0-9]|elastic107[0-9]|elastic108[0-9])\.eqiad\./ {
    role(elasticsearch::cirrus)
}

node /^(elastic109[0-9]|elastic110[0-2])\.eqiad\./ {
    role(elasticsearch::cirrus)
}

# new elastic servers T349777
node /^elastic110[3-7]\.eqiad\./ {
    role(insetup::search_platform)
}

node /^elastic203[7-9]\.codfw\./ {
    role(elasticsearch::cirrus)
}

node /^elastic204[0-8]\.codfw\./ {
    role(elasticsearch::cirrus)
}

node /^elastic205[0-9]\.codfw\./ {
    role(elasticsearch::cirrus)
}

node /^elastic2060\.codfw\./ {
    role(elasticsearch::cirrus)
}

# new codfw refresh servers T300943
node /^(elastic206[1-9]|elastic207[0-2])\.codfw\./ {
    role(elasticsearch::cirrus)
}

# new codfw elastic servers T300943
node /^(elastic207[3-9]|elastic208[0-6])\.codfw\./ {
    role(elasticsearch::cirrus)
}

# new codfw elastic servers T353878
node /^(elastic208[8-9]|elastic209[0-1])\.codfw\./ {
    role(insetup::search_platform)
}

# new codfw elastic servers T353878
node /^(elastic209[2-9]|elastic210[0-9])\.codfw\./ {
    role(insetup::search_platform)
}

# new codfw elastic servers T353878
node /^(elastic2087)\.codfw\./ {
    role(elasticsearch::cirrus)
}

# External Storage, Shard 1 (es1) databases

## eqiad servers
node /^es1027\.eqiad\./ {
    role(mariadb::core)
}

node /^es1029\.eqiad\./ {
    role(mariadb::core)
}

node /^es1032\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
# es2028
node /^es2028\.codfw\./ {
    role(mariadb::core)
}

# es2030
node /^es2030\.codfw\./ {
    role(mariadb::core)
}

# es2032
node /^es2032\.codfw\./ {
    role(mariadb::core)
}

# New external store hosts T354674
node /^es20(35|36|37|38|39|40)\.codfw\./ {
    role(insetup::data_persistence)
}

# New external store hosts T355269
node /^es10(35|36|37|38|39|40)\.eqiad\./ {
    role(insetup::data_persistence)
}

# New db hosts T354210
node /^db2(196|197|198|199|200|201|202|203|204|205|206|207|208|209|210|211|212|213|214|215|216|217|218|219|220)\.codfw\./ {
    role(insetup::data_persistence)
}

# External Storage, Shard 2 (es2) databases

## eqiad servers
node /^es1026\.eqiad\./ {
    role(mariadb::core)
}

node /^es1030\.eqiad\./ {
    role(mariadb::core)
}

node /^es1033\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
node /^es2026\.codfw\./ {
    role(mariadb::core)
}

## es2031
node /^es2031\.codfw\./ {
    role(mariadb::core)
}

## es2033
node /^es2033\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 3 (es3) databases

## eqiad servers
node /^es1028\.eqiad\./ {
    role(mariadb::core)
}

node /^es1031\.eqiad\./ {
    role(mariadb::core)
}

node /^es1034\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
# es2027
node /^es2027\.codfw\./ {
    role(mariadb::core)
}

# es2029
node /^es2029\.codfw\./ {
    role(mariadb::core)
}

# es2034
node /^es2034\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 4 (es4) databases
## eqiad servers
node /^es1020\.eqiad\./ {
    role(mariadb::core)
}

node /^es1021\.eqiad\./ {
    role(mariadb::core)
}

node /^es1022\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
node /^es202[012]\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 5 (es5) databases
## eqiad servers
node /^es102[345]\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers

node /^es202[345]\.codfw\./ {
    role(mariadb::core)
}

node /^failoid[12]002\.(eqiad|codfw)\./ {
    role(failoid)
}

# Etcd clusters for kubernetes, v3
node /^kubetcd[12]00[456]\.(eqiad|codfw)\./ {
    role(etcd::v3::kubernetes)
}

# Etcd cluster for kubernetes staging, v3
node /^kubestagetcd100[456]\.eqiad\./ {
    role(etcd::v3::kubernetes::staging)
}

# etc cluster for kubernetes staging, v3, codfw
node /^kubestagetcd200[123]\.codfw\./ {
    role(etcd::v3::kubernetes::staging)
}

# kubernetes master for staging
node /^kubestagemaster[12]00[12]\.(eqiad|codfw)\./ {
    role(kubernetes::staging::master)
}

# kubernetes masters
node /^kubemaster[12]00[12]\.(eqiad|codfw)\./ {
    role(kubernetes::master)
}

# Etherpad on bullseye (virtual machine) (T300568)
node /^etherpad1003\.eqiad\./ {
    role(etherpad)
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node /^eventlog1003\.eqiad\./ {
    role(eventlogging::analytics)
}

# virtual machine for mailman list server
node /^lists1001\.wikimedia\./ {
    role(lists)
}

#add new list server T342374
node /^lists1004\.eqiad\./ {
    role(insetup::unowned)
}
node /^ganeti10(09|1[0-9]|2[0-9]|3[0-8])\.eqiad\./ {
    role(ganeti)
}

node /^ganeti20(09|1[0-9]|2[0-9]|3[0-2])\.codfw\./ {
    role(ganeti)
}

# Routed Ganeti nodes
node /^ganeti203[3-4]\.codfw\./ {
    role(ganeti)
}

node /^ganeti-test200[123]\.codfw\./ {
    role(ganeti_test)
}

node /^ganeti300[123]\.esams\./ {
    role(ganeti)
}

# esams01 / BY27 Ganeti cluster
node /^ganeti300[57]\.esams\./ {
    role(ganeti)
}

# esams02 / BW27 Ganeti cluster
node /^ganeti300[68]\.esams\./ {
    role(ganeti)
}

node /^ganeti400[5678]\.ulsfo\./ {
    role(ganeti)
}

node /^ganeti500[4567]\.eqsin\./ {
    role(ganeti)
}

node /^ganeti600[1234]\.drmrs\./ {
    role(ganeti)
}

# gitlab servers - eqiad (T274459, T301177)
node /^gitlab1003\.wikimedia\./ {
    role(gitlab)
}

node /^gitlab1004\.wikimedia\./ {
    role(gitlab)
}

# gitlab runners - eqiad (T301177)
node /^gitlab-runner100[234]\.eqiad\./ {
    role(gitlab_runner)
}

# gitlab servers - codfw (T301183, T285867)
node /^gitlab2002\.wikimedia\./ {
    role(gitlab)
}

node /^gitlab2003\.wikimedia\./ {
    role(insetup::collaboration_services)
}

# gitlab runners - codfw (T3011183)
node /^gitlab-runner200[234]\.codfw\./ {
    role(gitlab_runner)
}

# Virtual machines for Grafana 6.x (T220838, T244357)
node /^grafana1002\.eqiad\./ {
    role(grafana)
}

node /^grafana2001\.codfw\./ {
    role(grafana)
}

# Serves dumps of revision content from restbase, in HTML format
# T245567 - replaced francium.eqiad.wmnet
node /^htmldumper1001\.eqiad\./ {
    role(dumps::web::htmldumps)
}

node /^irc1001\.wikimedia\./ {
    role(mw_rc_irc)
}

node /^irc2001\.wikimedia\./ {
    role(mw_rc_irc)
}

node /^irc[12]002\.wikimedia\./ {
    role(mw_rc_irc)
}

# Cloud cumin hosts
node /^cloudcumin1001\.eqiad\./ {
    role(cluster::cloud_management)
}

node /^cloudcumin2001\.codfw\./ {
    role(cluster::cloud_management)
}

node /^cloudservices100[56]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::services)
}

node /^cloudlb100[12]\.eqiad\./ {
    role(wmcs::cloudlb)
}

#new cloudweb hosts T305414
node /^cloudweb100[34]\.wikimedia\./ {
    role(wmcs::openstack::eqiad1::cloudweb)
}

node /^cloudweb2002-dev\.wikimedia\./ {
    role(wmcs::openstack::codfw1dev::cloudweb)
}

node /^cloudnet200[5-6]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::net)
}

# New clouddb node T306854
node /^clouddb2002-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::db)
}

node /^cloudcontrol200[145]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::control)
}

# New cloudcontrol node in codfw T342456
node /^cloudcontrol200[678]-dev\.codfw\./ {
    role(insetup::wmcs)
}

# New cloudnet node in codfw T342456
node /^cloudnet200[78]-dev\.codfw\./ {
    role(insetup::wmcs)
}

node /^cloudvirt200[456]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

# cloudrabbit servers T304888
node /^cloudrabbit100[123]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::rabbitmq)
}

node /^cloudservices200[45]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::services)
}

# Primary graphite host
node /^graphite1005\.eqiad\./ {
    role(graphite::production)
    include role::graphite::alerts # lint:ignore:wmf_styleguide
    include role::elasticsearch::alerts # lint:ignore:wmf_styleguide
}

# Standby graphite host
node /^graphite2004\.codfw\./ {
    role(graphite::production)
}

node /^idm[12]001\.wikimedia\./ {
    role(idm)
}

node /^idm-test[12]001\.wikimedia\./ {
    role(idm_test)
}

node /^idp[12]002\.wikimedia\./ {
    role(idp)
}

node /^idp-test[12]002\.wikimedia\./ {
    role(idp_test)
}

node /^install[12]004\.wikimedia\./ {
    role(installserver)
}

node /^install3003\.wikimedia\./ {
    role(installserver)
}

node /^install[456]002\.wikimedia\./ {
    role(installserver)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T255072, T255070)
node /^alert[12]001\.wikimedia\./ {
    role(alerting_host)
}

# Phabricator eqiad (T280540, T279176) (production)
node /^phab1004\.eqiad\./ {
    role(phabricator)
}

# Phabricator codfw (T280544, T279177) (failover)
node /^phab2002\.codfw\./ {
    role(phabricator)
}

# PKI server
node /^pki1001\.eqiad\./ {
    role(pki::multirootca)
}

# PKI server T342892
node /^pki1002\.eqiad\./ {
    role(insetup::infrastructure_foundations)
}

# PKI server
# make sure this is stricter enough to exclude rpki
node /^pki2002\.codfw\./ {
    role(pki::multirootca)
}

# pki-root server T276625
node /^pki-root1001\.eqiad\./ {
    role(pki::root)
}

# pki-root server T334401
node /^pki-root1002\.eqiad\./ {
    role(insetup::infrastructure_foundations)
}

node /^kafka-logging100[1-5]\.eqiad\./ {
    role(kafka::logging)
}

node /^kafka-logging200[1-5]\.codfw\./ {
    role(kafka::logging)
}

node /^kafka-main100[1-5]\.eqiad\./ {
    role(kafka::main)
}

node /^kafka-main200[1-5]\.codfw\./ {
    role(kafka::main)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo10(0[7-9]|1[0-5])\.eqiad\./ {
    role(kafka::jumbo::broker)
}

# Kafkamon bullseye hosts
node /^kafkamon[12]003\.(codfw|eqiad)\./ {
    role(kafka::monitoring_bullseye)
}

# New Kafka nodes T314156
node /^kafka-stretch100[12]\.eqiad\./ {
    role(insetup::data_engineering)
}

# New Kafka nodes T314160
node /^kafka-stretch200[12]\.codfw\./ {
    role(insetup::data_engineering)
}

# Two karapace VMs in support of DataHub
node /^karapace100[12]\.eqiad\./ {
    role(karapace)
}

# virtual machines for misc. applications and static sites
# replaced miscweb1001/2001 in T247648 and bromine/vega in T247650
#
# profile::microsites::static_rt       # https://static-rt.wikimedia.org
# profile::microsites::security        # https://security.wikimedia.org (T257830)
# profile::microsites::query_service   # parts of https://query.wikidata.org (T266702)
# profile::microsites::os_reports      # https://os-reports.wikimedia.org
node /^miscweb[12]003\.(eqiad|codfw)\./ {
    role(miscweb)
}

node /^krb1001\.eqiad\./ {
    role(kerberos::kdc)
}

node /^krb2002\.codfw\./ {
    role(kerberos::kdc)
}

node /^kubernetes10(0[5-9]|[1-5][0-9]|6[0-2]|)\.eqiad\./ {
    role(kubernetes::worker)
}

node /^kubernetes20(0[5-9]|[1-4][0-9]|5[0-9]|60)\.codfw\./ {
    role(kubernetes::worker)
}

# START Kubernetes workers that used to be mw app/api/jobrunner servers
node /^mw136[0-3]\.eqiad\./ {
  role(kubernetes::worker)
}

node /^mw137[4-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw138[0-3]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw1439\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw1440\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw146[0-69]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw147[0-5]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw145[79]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw148[26]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw1495\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw226[07]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw2282\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw229[1-7]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw235[57]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw2381\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw236[68]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw2370\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw2395\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw242[0-579]\.codfw\./ {
    role(kubernetes::worker)
}
node /^mw243[014-7]\.codfw\./ {
    role(kubernetes::worker)
}
node /^mw244[02356]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw245[01]\.codfw\./ {
  role(kubernetes::worker)
}
# END Kubernetes workers that used to be mw app/api/jobrunner servers

node /^kubestage100[34]\.eqiad\./ {
    role(kubernetes::staging::worker)
}

# codfw new kubernetes staging nodes T252185
node /^kubestage200[12]\.codfw\./ {
    role(kubernetes::staging::worker)
}

# Soon to be decom'd
node /^cloudvirt200[1-3]\-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

node /^cloudcontrol100[567]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::control)
}

# New cloudcontrol nodes T342455
node /^cloudcontrol10(0[8-9]|1[0])\-dev\.eqiad\./ {
    role(insetup::wmcs)
}

#new cephosd servers T322760
node /^cephosd100[12345]\.eqiad\./ {
    role(ceph::server)
}

# cloudceph monitor nodes
node /^cloudcephmon100[1-3]\.eqiad\./ {
    role(wmcs::ceph::mon)
}

# new cloudceph storage nodes T324998
node /^cloudcephosd10(3[5-9]|4[0])\.eqiad\./ {
    role(insetup::wmcs)
}

# cloudceph storage nodes
node /^cloudcephosd10(0[1-9]|1[0-9]|2[0-9]|3[0-4])\.eqiad\./ {
    role(wmcs::ceph::osd)
}

# New systems placed into service by cloud team via T194186 and T249062
node /^cloudelastic100[1-6]\.wikimedia\./ {
    role(elasticsearch::cloudelastic)
}

node /^cloudelastic100[7-9]\.wikimedia\./ {
    role(elasticsearch::cloudelastic)
}

#private IP migration canary, see T355617
node /^cloudelastic1010\.eqiad\./ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[5-6]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::net)
}

# New cloudnet nodes T342455
node /^cloudnet100[7-8]\-dev\.eqiad\./ {
    role(insetup::wmcs)
}

## Multi-instance wikireplica dbs
node /^clouddb10(13|14|15|16)\.eqiad\./ {
    role(wmcs::db::wikireplicas::web_multiinstance)
}

node /^clouddb10(17|18|19|20)\.eqiad\./ {
    role(wmcs::db::wikireplicas::analytics_multiinstance)
}

node /^clouddb1021\.eqiad\./ {
    role(wmcs::db::wikireplicas::dedicated::analytics_multiinstance)
}

node /^cloudbackup100[34]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::instance_backups)
}

# Generates and stores cinder backups
node /^cloudbackup200[12]\.codfw\./ {
    role(wmcs::openstack::eqiad1::cinder_backups)
}

# Flink team-specific zookeeper clusters T341705
node /^flink-zk100[123]\.eqiad\./ {
    role(zookeeper::flink)
}

node /^flink-zk200[123]\.codfw\./ {
    role(zookeeper::flink)
}

# the cinder-backup nodes for codfw1dev run in the eqiad DC and
# they are ganeti virtual machines. See T295584 for details.
node /^cloudbackup100[12]-dev\.eqiad\./ {
    role(wmcs::openstack::codfw1dev::backups)
}

# Read-only ldap replicas in eqiad
node /^ldap-replica100[3-4]\.wikimedia\./ {
    role(openldap::replica)
}

# Read-only ldap replicas in eqiad (bookworm)
node /^ldap-replica100[5-6]\.wikimedia\./ {
    role(insetup::infrastructure_foundations)
}

node /^ldap-rw1001\.wikimedia\./ {
    role(openldap::rw)
}

node /^ldap-rw2001\.wikimedia\./ {
    role(openldap::rw)
}

# Read-only ldap replicas in codfw
node /^ldap-replica200[5-6]\.wikimedia\./ {
    role(openldap::replica)
}

# Read-only ldap replicas in codfw (bookworm)
node /^ldap-replica200[7-8]\.wikimedia\./ {
    role(insetup::infrastructure_foundations)
}

node /^lists2001\.codfw\./ {
    role(insetup::unowned)
}

# New codfw logging nodes T349834
node /^logging-hd200[1-3]\.codfw\./ {
    role(insetup::observability)
}

# Logging data nodes (codfw)
node /^logstash20(0[123]|2[6789]|3[34567])\.codfw\./ {
    role(logging::opensearch::data)
}

# Logging collector nodes (codfw)
node /^logstash20(2[345]|3[012])\.codfw\./ {
    role(logging::opensearch::collector)
}

# New eqiad logging nodes T354226
node /^logging-hd100[1-3]\.eqiad\./ {
    role(insetup::observability)
}

# Logging data nodes (eqiad)
node /^logstash10(1[012]|2[6789]|3[34567])\.eqiad\./ {
    role(logging::opensearch::data)
}

# Logging collector nodes (eqiad)
node /^logstash10(2[345]|3[012])\.eqiad\./ {
    role(logging::opensearch::collector)
}

# new lvs servers T295804 (in prod use)
node /^lvs10(1[789]|20)\.eqiad\./ {
    role(lvs::balancer)
}

# old lvs servers T295804 (insetup for future experimentation!)
node /^lvs101[3456]\.eqiad\./ {
    role(insetup_noferm)
}

# codfw lvs
node /^lvs20(1[1234])\.codfw\./ {
    role(lvs::balancer)
}

# ESAMS lvs servers
node /^lvs30(0[89]|10)\.esams\./ {
    role(lvs::balancer)
}

# ULSFO lvs servers
node /^lvs40(0[89]|1[0])\.ulsfo\./ {
    role(lvs::balancer)
}

# EQSIN lvs servers
node /^lvs500[456]\.eqsin\./ {
    role(lvs::balancer)
}

# DRMRS lvs servers
node /^lvs600[123]\.drmrs\./ {
    role(lvs::balancer)
}

node /^maps10(0[5-8]|1[0])\.eqiad\./ {
    role(maps::replica)
}

# testing buster master - maps2.0 migration
node /^maps1009\.eqiad\./ {
    role(maps::master)
}

node /^maps20(0[5-8]|10)\.codfw\./ {
    role(maps::replica)
}

# testing buster master - maps2.0 migration
node /^maps2009\.codfw\./ {
    role(maps::master)
}

# Buster replacement for matomo1001 - T252740
node /^matomo1002\.eqiad\./ {
    role(piwik)
}

node /^mc10(3[7-9]|4[0-9]|5[0-4])\.eqiad\./ {
    role(mediawiki::memcached)
}

node /^mc20(3[8-9]|4[0-9]|5[0-5])\.codfw\./ {
    role(mediawiki::memcached)
}

node /^mc-gp100[1-3]\.eqiad\./ {
    role(mediawiki::memcached::gutter)
}

node /^mc-gp200[1-3]\.codfw\./ {
    role(mediawiki::memcached::gutter)
}

# new mc-wf nodes T313963
node /^mc-wf100[12]\.eqiad\./ {
    role(memcached)
}

# New mc-wf nodes T313966
node /^mc-wf200[1-2]\.codfw\./ {
    role(memcached)
}

node /^ml-cache100[123]\.eqiad\./ {
    role(ml_cache::storage)
}

node /^ml-cache200[123]\.codfw\./ {
    role(ml_cache::storage)
}

node /^ml-etcd100[123]\.eqiad\./ {
    role(etcd::v3::ml_etcd)
}

node /^ml-etcd200[123]\.codfw\./ {
    role(etcd::v3::ml_etcd)
}

node /^ml-serve-ctrl100[12]\.eqiad\./ {
    role(ml_k8s::master)
}

node /^ml-serve-ctrl200[12]\.codfw\./ {
    role(ml_k8s::master)
}

node /^ml-serve200[1-8]\.codfw\./ {
    role(ml_k8s::worker)
}

node /^ml-serve100[1-8]\.eqiad\./ {
    role(ml_k8s::worker)
}

# New ml-staging etcd T302503
node /^ml-staging-etcd200[123]\.codfw\./ {
    role(etcd::v3::ml_etcd::staging)
}

# New ml-staging ctrl T302503
node /^ml-staging-ctrl200[12]\.codfw\./ {
    role(ml_k8s::staging::master)
}

# New ml-staging nodes T294946
node /^ml-staging200[12]\.codfw\./ {
    role(ml_k8s::staging::worker)
}

node /^moscovium\.eqiad\./ {
    role(requesttracker)
}

node /^moss-fe1002\.eqiad\./ {
    role(insetup::data_persistence)
}

node /^moss-fe1001\.eqiad\./ {
    role(swift::proxy)
    include lvs::realserver # lint:ignore:wmf_styleguide
}

# New moss-be nodes T276637
node /^moss-be100[12]\.eqiad\./ {
    role(insetup::buster)
}
# New moss-be nodes T342675
node /^moss-be1003\.eqiad\./ {
    role(insetup::buster)
}

# New moss-be nodes T276642 and T342674
node /^moss-be200[123]\.codfw\./ {
    role(insetup::buster)
}

# New moss-fe nodes T275513
node /^moss-fe2001\.codfw\./ {
    role(swift::proxy)
    include lvs::realserver # lint:ignore:wmf_styleguide
}

node /^moss-fe2002\.codfw\./ {
    role(insetup::data_persistence)
}

node /^ms-backup100[12]\.eqiad\./ {
    role(mediabackup::worker)
}

node /^ms-backup200[12]\.codfw\./ {
    role(mediabackup::worker)
}

node /^ms-fe1\d\d\d\.eqiad\./ {
    role(swift::proxy)
    include lvs::realserver  # lint:ignore:wmf_styleguide
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be1\d\d\d\.eqiad\./ {
    role(swift::storage)
}

node /^ms-fe2\d\d\d\.codfw\./ {
    role(swift::proxy)
    include lvs::realserver  # lint:ignore:wmf_styleguide
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be2\d\d\d\.codfw\./ {
    role(swift::storage)
}

## MEDIAWIKI APPLICATION SERVERS

## DATACENTER: EQIAD

# Debug servers, on buster like production
node /^mwdebug100[12]\.eqiad\./ {
    role(mediawiki::canary_appserver)
}

# Appservers (serving normal website traffic)

# Row A

# rack A1
node /^mw14(5[1-2])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack A3
node /^mw141([4-8])\.eqiad\./ {
    role(mediawiki::canary_appserver)
}

node /^mw14(19|20)\.eqiad\./ {
    role(mediawiki::appserver)
}

node /^mw14(2[1-2])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# rack A5
node /^mw13(8[579]|91)\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack A8
node /^mw14(5[3-6])\.eqiad\./ {
    role(mediawiki::appserver)
}

# Row B

# rack B3
node /^mw14(2[3-8])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

node /^mw14(29|3[0-3])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack B3 and B5
node /^mw1(39[3579]|40[13])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack B6
node /^mw14(7[6-9]|8[01])\.eqiad\./ {
    role(mediawiki::appserver)
}

# Row C

# rack C3
node /^mw140[57]\.eqiad\./ {
    role(mediawiki::appserver)
}

node /^mw14(3[4-6])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack C8
node /^mw14(09|1[13])\.eqiad\./ {
    role(mediawiki::appserver)
}

# Row D

# rack D1
node /^mw13(49|5[0-5])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack D1
node /^mw148[78]\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack D3
node /^mw136[45]\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack D6
node /^mw13(6[6-9]|7[0-3])\.eqiad\./ {
    role(mediawiki::appserver)
}

# rack D8 - API servers
node /^mw144[3-4]\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# rack D8 - canary jobrunners
node /^mw143[7-8]\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack D8 - jobrunners
node /^mw14(45|46)\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack D8 - appservers
node /^mw1384\.eqiad\./ {
    role(mediawiki::appserver)
}

node /^mw144([1-2])\.eqiad\./ {
    role(mediawiki::appserver)
}

# Row F
node /^mw1496\.eqiad\./ {
    role(mediawiki::appserver)
}

## Api servers

# Row A

# rack A5
node /^mw13(8[68]|9[02])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# Row B

# rack B3 and B5
node /^mw1(39[468]|40[024])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# Row C

# rack C3
node /^mw1406\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# rack C8
node /^mw14(08|1[02])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# Row D

# rack D1
node /^mw135[8-9]\.eqiad\./ {
    role(mediawiki::appserver::api)
}
# rack D8
node /^mw14(4[7-9]|50)\.eqiad\./ {
    role(mediawiki::appserver::canary_api)
}

# Row E
node /^mw14(89|9[0-3])\.eqiad\./ {
    role(mediawiki::appserver::api)
}

# mediawiki maintenance server (periodic jobs)
# mwmaint1002 replaced mwmaint1001 (T201343) which replaced terbium (T192185)
# mwmaint2002 replaced mwmaint2001 (T274170, T275905)
node /^mwmaint[12]002\.(eqiad|codfw)\./ {
    role(mediawiki::maintenance)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Due to T329366, we are moving some parsoid servers to the jobrunner
# cluser in both datacenters.

# Row A

# rack A8
node /^mw1458\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# Row B

# rack B6
node /^mw146[78]\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# Row C

node /^parse101[3-6]\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack C5
node /^mw148[3-5]\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# Row F
node /^mw1494\.eqiad\./ {
    role(mediawiki::jobrunner)
}

## DATACENTER: CODFW

# Debug servers
# mwdebug2001 is in row A, mwdebug2002 is in row B
node /^mwdebug200[12]\.codfw\./ {
    role(mediawiki::canary_appserver)
}

# Appservers

# Row A

# New mw server hardware 2021 (T274171)

# rack A3 (T278396)
node /^mw23(82|94)\.codfw\./ {
    role(mediawiki::jobrunner)
}

node /^mw2(29[8-9]|300)\.codfw\./ {
    role(mediawiki::appserver::api)
}

node /^mw23(7[7-9]|80|8[3-9]|9[0-3])\.codfw\./ {
    role(mediawiki::appserver)
}

node /^mw2(39[6-9]|40[0-2])\.codfw\./ {
    role(mediawiki::appserver::api)
}

# rack A5 (T279599)
node /^mw240[3-5]\.codfw\./ {
    role(mediawiki::appserver::api)
}

node /^mw240[6-9]\.codfw\./ {
    role(mediawiki::appserver)
}

node /^mw241[01]\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack A6
node /^mw230[13579]\.codfw\./ {
    role(mediawiki::appserver)
}

# rack A6 (T331609)

node /^mw2426\.codfw\./ {
    role(mediawiki::jobrunner)
}
# Row B

# rack B3
node /^mw22(6[89]|70)\.codfw\./ {
    role(mediawiki::appserver)
}

# rack B3
node /^mw23(1[0-6])\.codfw\./ {
    role(mediawiki::appserver)
}

# rack B3
node /^mw23(1[7-9]|2[0-4])\.codfw\./ {
    role(mediawiki::appserver::api)
}

# rack B6
node /^mw23(2[579]|3[13])\.codfw\./ {
    role(mediawiki::appserver)
}

# rack B6 (T331609)

node /^mw2428\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack B8 (T331609)
node /^mw243[23]\.codfw\./ {
    role(mediawiki::appserver)
}

# Row C

# rack C6
node /^mw23(59|6[135])\.codfw\./ {
    role(mediawiki::appserver)
}

# rack C6
node /^mw23(5[13])\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack C3
node /^mw23(3[5-9])\.codfw\./ {
    role(mediawiki::appserver)
}

node /^mw24(1[2-5])\.codfw\./ {
    role(mediawiki::appserver)
}

node /^mw24(1[6-8])\.codfw\./ {
    role(mediawiki::appserver::api)
}

node /^mw2419\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack C1 (T331609)
node /^mw243[89]\.codfw\./ {
    role(mediawiki::appserver)
}

# rack C5 (T331609)
node /^mw2441\.codfw\./ {
    role(mediawiki::appserver)
}

# Row D

# rack D3
node /^mw2(27[12])\.codfw\./ {
    role(mediawiki::canary_appserver)
}

# rack D3
node /^mw2(27[3-7]|36[79]|37[135])\.codfw\./ {
    role(mediawiki::appserver)
}

# rack D5 (T331609)
node /^mw2444\.codfw\./ {
    role(mediawiki::jobrunner)
}

node /^mw2447\.codfw\./ {
    role(mediawiki::appserver)
}

# rack D6 (T331609)
node /^mw244[89]\.codfw\./ {
    role(mediawiki::appserver)
}

# API

# Row A

# rack A6
node /^mw230[2468]\.codfw\./ {
    role(mediawiki::appserver::api)
}

# Row B

# rack B3
node /^mw226[1-2]\.codfw\./ {
    role(mediawiki::appserver::api)
}

# rack B6
node /^mw23(2[68]|3[024])\.codfw\./ {
    role(mediawiki::appserver::api)
}

# Row C

# rack C6
node /^mw23(5[02468]|6[024])\.codfw\./ {
    role(mediawiki::appserver::api)
}

# Row D

# rack D3

node /^mw237[46]\.codfw\./ {
    role(mediawiki::appserver::canary_api)
}

node /^mw2372\.codfw\./ {
    role(mediawiki::appserver::api)
}

# rack D4
node /^mw22(8[3-9]|90)\.codfw\./ {
    role(mediawiki::appserver::api)
}

# Jobrunners

# Row A

# Row B

# rack B3
node /^mw2259\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack B3
node /^mw226[3-6]\.codfw\./ {
    role(mediawiki::jobrunner)
}

# Row C

# Row D

# rack D4 - canary jobrunners
node /^mw227[8-9]\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack D4 - jobrunners
node /^mw2281\.codfw\./ {
    role(mediawiki::jobrunner)
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host eqiad
node /^mwlog1002\.eqiad\./ {
    role(logging::mediawiki::udp2log)
}

# mw logging host codfw
node /^mwlog2002\.codfw\./ {
    role(logging::mediawiki::udp2log)
}

node /^mx1001\.wikimedia\./ {
    role(mail::mx)

    interface::alias { 'wiki-mail-eqiad.wikimedia.org':  # lint:ignore:wmf_styleguide
        ipv4 => '208.80.154.91',
        ipv6 => '2620:0:861:3:208:80:154:91',
    }
}

node /^mx2001\.wikimedia\./ {
    role(mail::mx)

    interface::alias { 'wiki-mail-codfw.wikimedia.org':  # lint:ignore:wmf_styleguide
        ipv4 => '208.80.153.46',
        ipv6 => '2620:0:860:2:208:80:153:46',
    }
}

node /^ncredir[1-9][0-9]{3}\./ {
    role(ncredir)
}

node /^netbox[12]002\.(eqiad|codfw)\./ {
    role(netbox::frontend)
}

node /^netboxdb[12]002\.(eqiad|codfw)\./ {
    role(netbox::database)
}

node /^netbox-dev2002\.codfw\./ {
    role(netbox::standalone)
}

node /^netmon[0-9]{4}\.wikimedia\./ {
    role(netmon)
}

# Network insights (netflow/pmacct, etc.)
node /^netflow[1-6]00[1-9]\.(eqiad|codfw|ulsfo|esams|eqsin|drmrs)\./ {
    role(netinsights)
}

node /^vrts1001\.eqiad\./ {
    role(vrts)
}

node /^vrts1002\.eqiad\./ {
    role(vrts)
}

# T323515: WIP
node /^vrts2001\.codfw\./ {
    role(vrts)
}

# new parsoid nodes - codfw (T243112, T247441) - eqiad (T299573)
node /^parse20(0[1-9]|1[0-9]|20)\.codfw\./ {
    role(parsoid)
}

node /^parse10(0[1-9]|1[012789]|2[0-4])\.eqiad\./ {
    role(parsoid)
}

# Temp parsoid eqiad capacity - T342085
node /^mw135[67]\.eqiad\./ {
    role(parsoid)
}

# parser cache databases
# eqiad
# pc1
node /^pc1011\.eqiad\./ {
    role(mariadb::parsercache)
}
# pc2
node /^pc1012\.eqiad\./ {
    role(mariadb::parsercache)
}
# pc3
node /^pc1013\.eqiad\./ {
    role(mariadb::parsercache)
}
# floating spares
node /^pc1014\.eqiad\./ {
    role(mariadb::parsercache)
}

node /^pc1015\.eqiad\./ {
    role(mariadb::parsercache)
}
# pc 4
node /^pc1016\.eqiad\./ {
    role(mariadb::parsercache)
}
# codfw
# pc1
node /^pc2011\.codfw\./ {
    role(mariadb::parsercache)
}
# pc2
node /^pc2012\.codfw\./ {
    role(mariadb::parsercache)
}
# pc3
node /^pc2013\.codfw\./ {
    role(mariadb::parsercache)
}
# floating spares
node /^pc2014\.codfw\./ {
    role(mariadb::parsercache)
}

node /^pc2015\.codfw\./ {
    role(mariadb::parsercache)
}

# pc4
node /^pc2016\.codfw\./ {
    role(mariadb::parsercache)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[12]003\.(eqiad|codfw)\./ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]003\.(eqiad|codfw)\./ {
    role(planet)
}

node /^poolcounter[12]00[345]\.(codfw|eqiad)\./ {
    role(poolcounter::server)
}

node /^prometheus200[56]\.codfw\./ {
    role(prometheus)
}

node /^prometheus100[56]\.eqiad\./ {
    role(prometheus)
}

node /^prometheus[3456]00[1-9]\.(esams|ulsfo|eqsin|drmrs)\./ {
    role(prometheus::pop)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\./ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]00[23]\.(codfw|eqiad)\./ {
    role(puppetmaster::backend)
}

node /^puppetboard[12]002\.(codfw|eqiad)\./ {
    role(insetup::infrastructure_foundations)
}

node /^puppetboard[12]003\.(codfw|eqiad)\./ {
    role(puppetboard)
}

node /^puppetdb[12]003\.(codfw|eqiad)\./ {
    role(puppetdb)
}

node /^puppetserver[12]00[12]\.(codfw|eqiad)\./ {
    role(puppetserver)
}

node /^puppetserver1003\.eqiad\./ {
    role(puppetserver)
}

# pybal-test2003 VM is used for pybal testing/development
node /^pybal-test2003\.codfw\./ {
    role(pybaltest)
}

node /^rdb101[13]\.eqiad\./ {
    role(redis::misc::master)
}

node /^rdb101[24]\.eqiad\./ {
    role(redis::misc::slave)
}

node /^rdb200[79]\.codfw\./ {
    role(redis::misc::master)
}

node /^rdb20(08|10)\.codfw\./ {
    role(redis::misc::slave)
}

node /^registry[12]00[34]\.(eqiad|codfw)\./ {
    role(docker_registry_ha::registry)
}

# https://releases.wikimedia.org - VMs for releases files (mediawiki and other)
# https://releases-jenkins.wikimedia.org (automatic MediaWiki builds)
node /^releases[12]003\.(codfw|eqiad)\./ {
    role(releases)
}

# New relforge servers T241791 (provision), T262211 (service impl.)
node /^relforge100[3-4]\.eqiad\./ {
    role(elasticsearch::relforge)
}

# restbase eqiad cluster
node /^restbase10(19|2[0-9]|3[0-3])\.eqiad\./ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(1[3-9]|2[0-9]|3[0-5])\.codfw\./ {
    role(restbase::production)
}

# New restbase (eqiad) hosts T354227
node /^restbase10(3[4-9]|4[0-2])\.eqiad\./ {
    role(insetup::data_persistence)
}

# New cassandra dev nodes T324113
node /^cassandra-dev200[1-3]\.codfw\./ {
    role(cassandra_dev)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]00[12]\.(eqiad|codfw)\./ {
    role(rpkivalidator)
}

# https://people.wikimedia.org - self-service file hosting
# VMs on bookworm, access for all shell users (T280989, T338827)
node /^people(1004|2003)\.(eqiad|codfw)\./ {
    role(microsites::peopleweb)
}

# scandium is a parsoid test server. it replaced ruthenium.
# This is now just like an MW appserver plus parsoid repo.
# roundtrip and visualdiff testing moved to testreduce* (T257906)
node /^scandium\.eqiad\./ {
    role(parsoid::testing)
}

node /^schema[12]00[3-4]\.(eqiad|codfw)\./ {
    role(eventschemas::service)
}
# See T346039
node /^search-loader[12]002\.(eqiad|codfw)\./ {
    role(search::loader)
}

# sessionstore servers
node /^sessionstore[1-2]00[1-3]\.(eqiad|codfw)\./ {
    role(sessionstore)
}

# New sessionstore servers T349875
node /^sessionstore100[4-6]\.eqiad\./ {
    role(sessionstore)
}

# New sessionstore servers T349876
node /^sessionstore200[4-6]\.codfw\./ {
    role(insetup::data_persistence)
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\./ {
    role(openldap::rw)
}

node /^mirror1001\.wikimedia\./ {
    role(mirrors)
}

# The hosts contain all the tools and libraries to access
# the Analytics Cluster services.
node /^stat100[4-9]\.eqiad\./ {
    role(statistics::explorer)
}

# New stat nodes T299466 and T307399
node /^stat101[0]\.eqiad\./ {
    role(insetup::data_engineering)
}

# New stat nodes T342454
node /^stat1011\.eqiad\./ {
    role(insetup::data_engineering)
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
# They should also be added to the dumps/scap repo in dumps_targets,
# https://gerrit.wikimedia.org/r/plugins/gitiles/operations/dumps/scap
node /^snapshot1008\.eqiad\./ {
    role(dumps::generation::worker::dumper_misc_crons_only)
}
node /^snapshot1010\.eqiad\./ {
    role(dumps::generation::worker::dumper_monitor)
}
node /^snapshot1009\.eqiad\./ {
    role(dumps::generation::worker::testbed)
}
node /^snapshot101[1-2]\.eqiad\./ {
    role(dumps::generation::worker::dumper)
}
node /^snapshot1013\.eqiad\./ {
    role(dumps::generation::worker::dumper)
}

node /^snapshot101[4567]\.eqiad\./ {
    role(dumps::generation::worker::testbed)
}

# Servers for SRE tests which are not suitable for Cloud VPS
node /^sretest100[1-4]\.eqiad\./ {
    role(sretest)
}

# Servers for SRE tests in codfw
node /^sretest200[1-5]\.codfw\./ {
    role(sretest)
}

node /^testhost2001\.codfw\./ {
    role(insetup::wmcs)
}

# House of Thanos components
node /^titan200[1-2]\.codfw\./ {
    role(titan)
}

node /^titan100[1-2]\.eqiad\./ {
    role(titan)
}

# special VMs for wiki stewards - T344164
node /^stewards[12]001.(eqiad|codfw)\./ {
    role(stewards)
}

# parsoid visual diff and roundtrip testing (T257940)
# also see scandium.eqiad.wmnet
node /^testreduce1002\.eqiad\./ {
    role(parsoid::testreduce)
}

# Test instances for Ganeti test cluster
node /^testvm200[1-9]\.codfw\./ {
    role(test)
}

node /^thanos-be100[1234]\.eqiad\./ {
    role(thanos::backend)
}

node /^thanos-be200[1234]\.codfw\./ {
    role(thanos::backend)
}

node /^thanos-fe100[1234]\.eqiad\./ {
    role(thanos::frontend)
}

node /^thanos-fe200[1234]\.codfw\./ {
    role(thanos::frontend)
}

# deployment servers
node /^deploy[12]002\.(eqiad|codfw)\./ {
    role(deployment_server::kubernetes)
}

node /^urldownloader[12]00[12]\.wikimedia\./ {
    role(insetup::infrastructure_foundations)
}

# https://wikitech.wikimedia.org/wiki/Url-downloader
node /^urldownloader[12]00[34]\.wikimedia\./ {
    role(url_downloader)
}

# These are hypervisors that use local storage for their VMs
#  rather than ceph. This is necessary for low-latency workloads
#  like etcd.
node /^cloudvirtlocal100[1-3]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt)
}

# cloudvirt servers T305194, T299574, T342537
node /^cloudvirt10(3[1-9]|4[0-9]|5[0-9]|6[0-7])\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# Private virt hosts for wdqs T221631
node /^cloudvirt-wdqs100[123]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt)
}

node /^wcqs100[123]\.eqiad\./ {
    role(wcqs::public)
}

node /^wcqs200[123]\.codfw\./ {
    role(wcqs::public)
}

node /^wdqs101[167]\.eqiad\./ {
    role(wdqs::internal)
}

node /^wdqs101[2-5]\.eqiad\./ {
    role(wdqs::public)
}

node /^wdqs10(1[89]|2[01])\.eqiad\./ {
    role(wdqs::public)
}

# new  node T342660
node /^wdqs10([1][7-9]|[2][0-1])\.eqiad\./ {
    role(::insetup::search_platform)
}

node /^wdqs10([2][2-4])\.eqiad\./ {
    role(wdqs::test)
}

node /^(wdqs2008|wdqs201[45])\.codfw\./ {
    role(wdqs::internal)
}

node /^(wdqs200[7,9]|wdqs201[0-3]|wdqs201[6-9]|wdqs202[0-5])\.codfw\./ {
    role(wdqs::public)
}

node /^webperf1003.eqiad\./ {
    role(webperf)
}

node /^webperf2003\.codfw\./ {
    role(webperf)
}

node /^arclamp1001\.eqiad\./ {
    role(arclamp)
}

node /^arclamp2001\.codfw\./ {
    role(arclamp)
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
