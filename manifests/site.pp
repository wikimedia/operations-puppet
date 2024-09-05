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

node /^an-coord100[34]\.eqiad\./ {
    role(analytics_cluster::coordinator)
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
node /^an-worker11(0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-9]|6[0-9]|7[0-5])\.eqiad\./ {
    role(analytics_cluster::hadoop::worker)
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

# Refreshed hardware for Analytics Zookeeper cluster - See #T364429
node /^an-conf100[4-6]\.eqiad\./ {
    role(insetup::data_engineering)
}

# New analytics presto nodes T370543
node /^an-presto10(1[6-9]|20)\.eqiad\./ {
    role(insetup::data_engineering)
}

# Analytics Presto nodes
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

node /^apt[12]002\.wikimedia\./ {
    role(apt_repo)
}

# apt-staging host
node /^apt-staging2001\.codfw\./ {
    role(apt_staging)
}

# Analytics Query Service
node /^aqs10(1[0-9]|2[0-2])\.eqiad\./ {
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

# new backup node T326684 and T371416
node /^backup10(10|12)\.eqiad\./ {
    role(insetup::data_persistence)
}

# new node T355571
node /^an-redacteddb1001\.eqiad\./ {
    role(wmcs::db::wikireplicas::dedicated::analytics_multiinstance)
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
# New backup node for codfw T371984
node /^backup2012\.codfw\./ {
    # role(mediabackup::storage)
    role(insetup::data_persistence)
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

node /^bast7001\.wikimedia\./ {
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

# Bitu instance for labtestwikitech
node /^cloudidm2001-dev\.codfw\./ {
    role(idmcloud)
}

# All gerrit servers (swap master status in hiera)
node /^gerrit(1003|2002)\.wikimedia\./ {
    role(gerrit)
}

# new hardware (codfw) - T369670
node /^gerrit2003\.wikimedia\./ {
    role(insetup::collaboration_services::gerrit)
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

#
# cp magru nodes
#

node /^cp700[1-8]\.magru\./ {
    role(cache::text)
}

node /^cp70(09|1[0-6])\.magru\./ {
    role(cache::upload)
}

node /^crm2001\.codfw\./ {
    role(crm)
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
node /^db1(163|169|184|186|195|206|207|218|219|232|234|235)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1196\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
node /^db2(116|130|145|146|153|170|174|176|188|203|212|216)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2173\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on eqiad
# See also db1146 below
node /^db1(162|182|188|197|222|229|233|246)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1156\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
node /^db2(125|138|148|175|189|204|207)\.codfw\./ {
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
node /^db2(127|149|177|190|194|205|209)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2156\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s4 (commons) core production dbs on eqiad
# See also db1144 and db1146 below
node /^db1(160|190|199|238|241|242|243|244|247|248|249)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1221\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# Testing cluster
node /^db1125\.eqiad\./ {
    role(mariadb::core_test)
}

# Testing host - will need to be wiped after the DC switch tests
node /^db2230\.codfw\./ {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
node /^db2(136|137|140|147|172|179|206|210|219)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2155\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on eqiad
# See also db1213 and db1144 below
node /^db1(183|185|200|210|213|230)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1161\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
node /^db2(123|157|171|178|192|211|213)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2128\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s6 (frwiki, jawiki, ruwiki) core production dbs on eqiad
node /^db1(168|173|180|187|201|231)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1165\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s6 core production dbs on codfw
node /^db2(124|129|151|169|180|193|214|217)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2158\.codfw\./ {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
node /^db1(069|170|174|178|181|191|194|202|227|236)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1158\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
node /^db2(121|122|150|168|182|218|208|220|221|222)\.codfw\./ {
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
node /^db2(152|154|161|162|163|165|166|167|181|195)\.codfw\./ {
    role(mariadb::core)
}

# codfw sanitarium master
node /^db2164\.codfw\./ {
    role(mariadb::sanitarium_master)
}

## x1 shard
# eqiad
node /^db1(179|220|224|237)\.eqiad\./ {
    role(mariadb::core)
}

# codfw
node /^db2(115|131|191|196|215)\.codfw\./ {
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

# master
node /^db1228\.eqiad\./ {
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
## s3 & s4, bullseye
node /^db1150\.eqiad\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bullseye
node /^db1171\.eqiad\./ {
    role(mariadb::backup_source)
}
## s5, s8 & x1, bullseye
node /^db1216\.eqiad\./ {
    role(mariadb::backup_source)
}
## s2, s6 & x1, bullseye
node /^db1225\.eqiad\./ {
    role(mariadb::backup_source)
}
## s1 & s2, bullseye
node /^db1239\.eqiad\./ {
    role(mariadb::backup_source)
}
## s1 & s3, bullseye
node /^db1240\.eqiad\./ {
    role(mariadb::backup_source)
}
## s4 & s5, bullseye
node /^db1245\.eqiad\./ {
    role(mariadb::backup_source)
}

# codfw backup sources
## s3 & s4, bullseye
node /^db2139\.codfw\./ {
    role(mariadb::backup_source)
}
## s1, bullseye
node /^db2141\.codfw\./ {
    role(mariadb::backup_source)
}
## s2, s6 & x1, bookworm
node /^db2197\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bookworm
node /^db2198\.codfw\./ {
    role(mariadb::backup_source)
}
## s4, bookworm
node /^db2199\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & s8, bookworm
node /^db2200\.codfw\./ {
    role(mariadb::backup_source)
}
## s2, s5, & x1, bookworm
node /^db2201\.codfw\./ {
    role(mariadb::backup_source)
}

# test-s1, bookworm
node /^db2202\.codfw\./ {
    role(mariadb::core_test)
}

# Analytics production replicas
node /^dbstore100[789]\.eqiad\./ {
    role(mariadb::analytics_replica)
}

# database-provisioning and short-term/postprocessing backups servers

node /^dbprov1001\.eqiad\./ {
    role(insetup::data_persistence)
}
node /^dbprov1002\.eqiad\./ {
    role(insetup::data_persistence)
}
node /^dbprov1003\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1004\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1005\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1006\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov2001\.codfw\./ {
    role(insetup::data_persistence)
}
node /^dbprov2002\.codfw\./ {
    role(insetup::data_persistence)
}
node /^dbprov2003\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2004\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2005\.codfw\./ {
    role(dbbackups::metadata)
}
node /^dbprov2006\.codfw\./ {
    role(dbbackups::metadata)
}

# Active eqiad proxies for misc databases
node /^dbproxy10(12|13|14|15|16|20|21|22|23|24|25|26|27|28|29)\.eqiad\./ {
    role(mariadb::proxy::master)
}

# New databases T373579
node /^db22(23|24|25|26|27|28|29|31|32|33|34|35|36|37|38|39|40)\.codfw\./ {
    role(insetup::data_persistence)
}

# New parsercache T368920
node /^pc1017\.eqiad\./ {
    role(insetup::data_persistence)
}

# New parsercache T368919
node /^pc2017\.codfw\./ {
    role(insetup::data_persistence)
}

# New proxies T361352
node /^dbproxy200(5|6|7|8)\.codfw\./ {
    role(insetup::data_persistence)
}

# Passive codfw proxies for misc databases
node /^dbproxy20(01|02|03|04)\.codfw\./ {
    role(mariadb::proxy::master)
}

node /^debmonitor[12]003\.(codfw|eqiad)\./ {
    role(debmonitor::server)
}

node /^dns[1-9][0-9]{3}\.wikimedia\./ {
    role(dnsbox)
}

node /^doc(1003|2002)\.(codfw|eqiad)\./ {
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
node /^dse-k8s-worker100[1-9]\.eqiad\./ {
    role(dse_k8s::worker)
}

# to be decommed
node /^dumpsdata100[12]\.eqiad\./ {
    role(insetup::data_engineering)
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

# spare dumpsdata servers T283290
node /^dumpsdata100[45]\.eqiad\./ {
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

node /^elastic110[3-7]\.eqiad\./ {
    role(elasticsearch::cirrus)
}

node /^elastic(205[5-9]|20[6-9][0-9])\.codfw\./ {
    role(elasticsearch::cirrus)
}
node /^elastic210[0-9]\.codfw\./ {
    role(elasticsearch::cirrus)
}
# External Storage, Shard 1 (es1) databases
# RO section
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

# External Storage, Shard 2 (es2) databases
# RO section
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
# RO section
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
# RO section
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
node /^es2020\.codfw\./ {
    role(mariadb::core)
}

node /^es2021\.codfw\./ {
    role(mariadb::core)
}

node /^es2022\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 5 (es5) databases
# RO section
## eqiad servers
node /^es1023\.eqiad\./ {
    role(mariadb::core)
}

node /^es1024\.eqiad\./ {
    role(mariadb::core)
}

node /^es1025\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
node /^es2023\.codfw\./ {
    role(mariadb::core)
}

node /^es2024\.codfw\./ {
    role(mariadb::core)
}

node /^es2025\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 6 (es6) databases
# RW section
## eqiad servers
node /^es1036\.eqiad\./ {
    role(mariadb::core)
}

node /^es1037\.eqiad\./ {
    role(mariadb::core)
}

node /^es1038\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers

node /^es2035\.codfw\./ {
    role(mariadb::core)
}

node /^es2036\.codfw\./ {
    role(mariadb::core)
}

node /^es2037\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 7 (es7) databases
# RW section
## eqiad servers
node /^es1035\.eqiad\./ {
    role(mariadb::core)
}

node /^es1039\.eqiad\./ {
    role(mariadb::core)
}

node /^es1040\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
node /^es2038\.codfw\./ {
    role(mariadb::core)
}

node /^es2039\.codfw\./ {
    role(mariadb::core)
}

node /^es2040\.codfw\./ {
    role(mariadb::core)
}

node /^failoid[12]002\.(eqiad|codfw)\./ {
    role(failoid)
}

# kubernetes masters for staging clusters
node /^kubestagemaster[12]00[345]\.(eqiad|codfw)\./ {
    role(kubernetes::staging::master_stacked)
}

node /^wikikube-ctrl[12]00[1-3]\.(eqiad|codfw)\./ {
    role(kubernetes::master_stacked)
}

# Etherpad on bookworm (virtual machine) (T357159, T316421)
node /^etherpad[12]00[24]\.(eqiad|codfw)\./ {
    role(etherpad)
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node /^eventlog1003\.eqiad\./ {
    role(eventlogging::analytics)
}

node /^lists1004\.wikimedia\./ {
    role(lists)
}

node /^lists2001\.wikimedia\./ {
    role(lists)
}

node /^ganeti10(09|1[0-9]|2[0-9]|3[0-8])\.eqiad\./ {
    role(ganeti)
}

node /^ganeti20(09|1[0-9]|2[0-9]|3[0-2])\.codfw\./ {
    role(ganeti)
}

# Routed Ganeti nodes
node /^ganeti203[3-4]\.codfw\./ {
    role(ganeti_routed)
}

# New Codfw  Ganeti nodes
node /^ganeti20(3[5-9]|4[0-4])\.codfw\./ {
    role(insetup::infrastructure_foundations)
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

node /^ganeti700[1234]\.magru\./ {
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

node /^cloudcontrol200[456]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::control)
}

# New cloudcontrol node in codfw T342456
node /^cloudcontrol200[789]-dev\.codfw\./ {
    role(insetup::wmcs)
}

# New cloudnet node used for OVS experiments
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

# graphite - primary host defined in hieradata/common.yaml
node /^graphite[12]00[4-5]\.(eqiad|codfw)\./ {
    role(graphite::production)
}

node /^idm[12]001\.wikimedia\./ {
    role(idm)
}

node /^idm-test[12]001\.wikimedia\./ {
    role(idm_test)
}

# CAS 7.0 hosts
node /^idp[12]004\.wikimedia\./ {
    role(idp)
}

# CAS 7.0 hosts
node /^idp-test[12]00[45]\.wikimedia\./ {
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

node /^install7001\.wikimedia\./ {
    role(installserver)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T255072, T255070)
node /^alert[12]001\.wikimedia\./ {
    role(alerting_host)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T370111, T370112)
node /^alert[12]002\.wikimedia\./ {
    role(alerting_host)
}

# Phabricator eqiad (T280540, T279176) (production)
node /^phab1004\.eqiad\./ {
    role(phabricator)
}

# new hardware (eqiad) - T369671
node /^phab1005\.eqiad\./ {
    role(insetup::collaboration_services)
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

node /^kafka-main10(0[6-9]|10)\.eqiad\./ {
    role(insetup::serviceops)
}

node /^kafka-main200[2-6]\.codfw\./ {
    role(kafka::main)
}

node /^kafka-main20(0[7-9]|10)\.codfw\./ {
    role(insetup::serviceops)
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

# virtual machines for misc. applications and static sites
# replaced miscweb1001/2001 in T247648 and bromine/vega in T247650
#
# profile::microsites::static_rt       # https://static-rt.wikimedia.org
# profile::microsites::query_service   # parts of https://query.wikidata.org (T266702)
# profile::microsites::os_reports      # https://os-reports.wikimedia.org
node /^miscweb[12]003\.(eqiad|codfw)\./ {
    role(miscweb)
}

node /^krb1001\.eqiad\./ {
    role(kerberos::kdc)
}

node /^krb1002\.eqiad\./ {
    role(insetup::infrastructure_foundations)
}

node /^krb2002\.codfw\./ {
    role(kerberos::kdc)
}

node /^kubernetes10(0[5-9]|[1-5][0-9]|6[0-2]|)\.eqiad\./ {
    role(kubernetes::worker)
}

node /^kubernetes20(0[5-6]|1[1-7]|2[0-4]|3[1-46-9]|4[0-9]|5[0-3689]|60)\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker10(0[1-47-9]|1[0-47-9]|2[0-9]|3[0-3])\.eqiad\./ {
    role(kubernetes::worker)
}

# T368933, T369743 NOTE: We use those hostnames because we are going to be
# renaming parse*, mw*, kubernetes* and those add up to 1231. Leeway included
node /^wikikube-worker1(2[4-9][0-9]|30[0-4])\.eqiad\./ {
    role(insetup::serviceops)
}

node /^wikikube-worker20(0[1-47-9]|[1-8][0-9]|90)\.codfw\./ {
    role(kubernetes::worker)
}

# START Kubernetes workers that used to be mw app/api/jobrunner/parsoid servers
node /^mw135([2-7])\.eqiad\./ {
  role(kubernetes::worker)
}

node /^mw136[0-37-9]\.eqiad\./ {
  role(kubernetes::worker)
}

node /^mw137[014-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw138[0-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw139[0-79]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw140[589]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw141[4-69]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw142[1-5]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw143[0-59]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw144[0-28-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw145[1-57-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw146[0-9]\.eqiad\./ {
  role(kubernetes::worker)
}
node /^mw147[0-9]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw148[0-8]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw149[1-6]\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw1453\.eqiad\./ {
    role(kubernetes::worker)
}
node /^mw2282\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw230[1-5]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw231[01345]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw232[0-2]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw233[2-8]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw235[0-79]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw236[6-9]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw237[0-6]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw239[04-9]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw241[2-9]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw242[014-9]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw243[016-7]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw244[02-9]\.codfw\./ {
  role(kubernetes::worker)
}
node /^mw245[01]\.codfw\./ {
  role(kubernetes::worker)
}
node /^parse10(0[1-9]|1[0-9]|2[01234])\.eqiad\./ {
  role(kubernetes::worker)
}
node /^parse20(0[1-9]|1[0-9]|20)\.codfw\./ {
  role(kubernetes::worker)
}
# END Kubernetes workers that used to be mw app/api/jobrunner/parsoid servers

node /^kubestage100[34]\.eqiad\./ {
    role(kubernetes::staging::worker)
}

# codfw new kubernetes staging nodes T252185
node /^kubestage200[12]\.codfw\./ {
    role(kubernetes::staging::worker)
}

node /^cloudcontrol100[567]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::control)
}

# New cloudcontrol nodes T342455
node /^cloudcontrol10(0[8-9]|1[0])\-dev\.eqiad\./ {
    role(insetup::wmcs)
}

# Data Platform - Ceph osd servers T322760
node /^cephosd100[12345]\.eqiad\./ {
    role(ceph::server)
}

# cloudceph monitor nodes
node /^cloudcephmon100[1-3,5]\.eqiad\./ {
    role(wmcs::ceph::mon)
}

# new cloudceph  nodes
node /^cloudcephmon100[4-6]\.eqiad\./ {
    role(insetup::wmcs)
}

# new cloudceph storage nodes T361366
node /^cloudcephosd10(39|4[0-1])\.eqiad\./ {
    role(insetup::wmcs)
}

# cloudceph storage nodes
node /^cloudcephosd10(0[1-9]|1[0-9]|2[0-9]|3[0-8])\.eqiad\./ {
    role(wmcs::ceph::osd)
}

node /^cloudelastic100[5-9]\.eqiad\./ {
    role(elasticsearch::cloudelastic)
}

node /^cloudelastic1010\.eqiad\./ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[56]\.eqiad\./ {
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

node /^cloudbackup100[34]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::instance_backups)
}

node /^cloudbackup200[34]\.codfw\./ {
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
    role(wmcs::openstack::codfw1dev::cinder_backups)
}

# Read-only ldap replicas in eqiad
node /^ldap-replica100[3-4]\.wikimedia\./ {
    role(openldap::replica)
}

node /^ldap-maint[12]001\.(eqiad|codfw)\./ {
    role(openldap::maintenance)
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

# Logging data nodes, hdd class (codfw)
node /^logging-hd200[1-3]\.codfw\./ {
    role(logging::opensearch::data)
}

node /^logging-hd200[4-5]\.codfw\./ {
    role(insetup::observability)
}

# Logging data nodes, ssd class (codfw)
node /^logstash20(2[6789]|3[34567])\.codfw\./ {
    role(logging::opensearch::data)
}

node /^logging-sd200[1-4]\.codfw\./ {
    role(insetup::observability)
}

# Logging collector nodes (codfw)
node /^logstash20(2[345]|3[012])\.codfw\./ {
    role(logging::opensearch::collector)
}

# Logging data nodes, hdd class (eqiad)
node /^logging-hd100[1-3]\.eqiad\./ {
    role(logging::opensearch::data)
}

node /^logging-hd100[4-5]\.eqiad\./ {
    role(insetup::observability)
}

# Logging data nodes, ssd class (eqiad)
node /^logstash10(2[6789]|3[34567])\.eqiad\./ {
    role(logging::opensearch::data)
}

node /^logging-sd100[1-4]\.eqiad\./ {
    role(insetup::observability)
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

# MAGRU lvs servers
node /^lvs700[123]\.magru\./ {
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

# To be decommissioned
node /^matomo1002\.eqiad\./ {
    role(insetup::data_engineering)
}

# Bookworm replacement for matomo1002 - T349397
node /^matomo1003\.eqiad\./ {
    role(matomo)
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

node /^ml-serve20(0[1-9]|1[01])\.codfw\./ {
    role(ml_k8s::worker)
}

node /^ml-serve10(0[1-9]|1[01])\.eqiad\./ {
    role(ml_k8s::worker)
}

node /^ml-staging-etcd200[123]\.codfw\./ {
    role(etcd::v3::ml_etcd::staging)
}

node /^ml-staging-ctrl200[12]\.codfw\./ {
    role(ml_k8s::staging::master)
}

node /^ml-staging200[123]\.codfw\./ {
    role(ml_k8s::staging::worker)
}

node /^ml-lab100[12]\.eqiad\./ {
    role(insetup::data_engineering)
}

node /^moscovium\.eqiad\./ {
    role(requesttracker)
}

node /^moss-fe100[12]\.eqiad\./ {
    role(cephadm::rgw)
}

# Controller for the eqiad apus cephadm cluster
node /^moss-be1001\.eqiad\./ {
    role(cephadm::controller)
}

node /^moss-be100[23]\.eqiad\./ {
    role(cephadm::storage)
}

# Controller for the codfw apus cephadm cluster
node /^moss-be2001\.codfw\./ {
    role(cephadm::controller)
}

node /^moss-be200[23]\.codfw\./ {
    role(cephadm::storage)
}

node /^moss-fe200[12]\.codfw\./ {
    role(cephadm::rgw)
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

# Jobrunners

node /^mw13(49|50|51)\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack A3 jobrunner and scap::proxy
node /^mw1420\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# Row C

# rack C3
node /^mw1407\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack D8 - canary jobrunners
node /^mw143[7-8]\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# rack D8 - videoscaler jobrunners
node /^mw14(45|46)\.eqiad\./ {
    role(mediawiki::jobrunner)
}

# mediawiki maintenance server (periodic jobs)
# mwmaint1002 replaced mwmaint1001 (T201343) which replaced terbium (T192185)
# mwmaint2002 replaced mwmaint2001 (T274170, T275905)
node /^mwmaint[12]002\.(eqiad|codfw)\./ {
    role(mediawiki::maintenance)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

## DATACENTER: CODFW

# Debug servers
# mwdebug2001 is in row A, mwdebug2002 is in row B
node /^mwdebug200[12]\.codfw\./ {
    role(mediawiki::canary_appserver)
}

# Jobrunners

# Row A
node /^mw241[01]\.codfw\./ {
    role(mediawiki::jobrunner)
}

# Row B

# rack B3
node /^mw2259\.codfw\./ {
    role(mediawiki::jobrunner)
}

# rack B3
node /^mw226[3-6]\.codfw\./ {
    role(mediawiki::jobrunner)
}

# Row D

# rack D4 - canary jobrunners
node /^mw227[8-9]\.codfw\./ {
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

node /^mx-out[1-9][0-9]{3}\.wikimedia\./ {
    role(postfix::mx_out)
}

node /^mx-in[1-9][0-9]{3}\.wikimedia\./ {
    role(postfix::mx_in)
}

node /^ncmonitor[1-9][0-9]{3}\./ {
    role(ncmonitor)
}

node /^ncredir[1-9][0-9]{3}\./ {
    role(ncredir)
}

node /^netbox[12]00[0-9]\.(eqiad|codfw)\./ {
    role(netbox::frontend)
}

node /^netboxdb[12]00[0-9]\.(eqiad|codfw)\./ {
    role(netbox::database)
}

node /^netbox-dev[12]00[0-9]\.(eqiad|codfw)\./ {
    role(netbox::standalone)
}

node /^netmon[0-9]{4}\.wikimedia\./ {
    role(netmon)
}

# Network insights (netflow/pmacct, etc.)
node /^netflow[1-7]00[1-9]\.(eqiad|codfw|ulsfo|esams|eqsin|drmrs|magru)\./ {
    role(netinsights)
}

node /^vrts1001\.eqiad\./ {
    role(vrts)
}

node /^vrts1003\.eqiad\./ {
    role(insetup::collaboration_services)
}

# T323515: WIP
node /^vrts2001\.codfw\./ {
    role(vrts)
}

node /^vrts2002\.codfw\./ {
    role(insetup::collaboration_services)
}

# T363399 - replaces scandium and or testreduce*
node /^parsoidtest[1-2]00([1-9])\.(eqiad|codfw)\./ {
    role(insetup::serviceops)
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
node /^ping[12]004\.(eqiad|codfw)\./ {
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

node /^prometheus200[78]\.codfw\./ {
    role(insetup::observability)
}

node /^prometheus100[78]\.eqiad\./ {
    role(insetup::observability)
}

node /^prometheus[34567]00[1-9]\.(esams|ulsfo|eqsin|drmrs|magru)\./ {
    role(prometheus::pop)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\./ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]003\.(codfw|eqiad)\./ {
    role(puppetmaster::backend)
}

node /^puppetmaster2002\.codfw\./ {
    role(puppetmaster::backend)
}

node /^puppetboard[12]003\.(codfw|eqiad)\./ {
    role(puppetboard)
}

node /^puppetdb[12]003\.(codfw|eqiad)\./ {
    role(puppetdb)
}

node /^puppetserver[12]00[123]\.(codfw|eqiad)\./ {
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
node /^restbase10(2[8-9]|3[0-9]|4[0-2])\.eqiad\./ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(2[1-9]|3[0-5])\.codfw\./ {
    role(restbase::production)
}

# New cassandra dev nodes T324113
node /^cassandra-dev200[1-3]\.codfw\./ {
    role(cassandra_dev)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]00[1-9]\.(eqiad|codfw)\./ {
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
node /^sessionstore100[4-6]\.eqiad\./ {
    role(sessionstore)
}

node /^sessionstore200[4-6]\.codfw\./ {
    role(sessionstore)
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
node /^stat10(0[8-9]|1[0-1])\.eqiad\./ {
    role(statistics::explorer)
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
# They should also be added to the dumps/scap repo in dumps_targets,
# https://gerrit.wikimedia.org/r/plugins/gitiles/operations/dumps/scap
node /^snapshot1010\.eqiad\./ {
    role(dumps::generation::worker::dumper_monitor)
}
node /^snapshot101[123]\.eqiad\./ {
    role(dumps::generation::worker::dumper)
}
node /^snapshot101[456]\.eqiad\./ {
    role(dumps::generation::worker::testbed)
}
node /^snapshot1017\.eqiad\./ {
    role(dumps::generation::worker::dumper_misc_crons_only)
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

node /^testvm200[1-9]\.wikimedia\./ {
    role(test)
}

# Newly provisioned thanos-be hosts are safe to add to thanos::backend at
# any time, like ms-be/swift::storage nodes
node /^thanos-be1\d\d\d\.eqiad\./ {
    role(thanos::backend)
}

node /^thanos-be2\d\d\d\.codfw\./ {
    role(thanos::backend)
}

node /^thanos-fe100[1234]\.eqiad\./ {
    role(thanos::frontend)
}

node /^thanos-fe200[1234]\.codfw\./ {
    role(thanos::frontend)
}

# deployment servers
node /^deploy(1003|2002)\.(eqiad|codfw)\./ {
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

node /^wcqs100[123]\.eqiad\./ {
    role(wcqs::public)
}

node /^wcqs200[123]\.codfw\./ {
    role(wcqs::public)
}

node /^wdqs101[167]\.eqiad\./ {
    role(wdqs::internal)
}

node /^wdqs101([2-5]|[89])\.eqiad\./ {
    role(wdqs::public)
}

node /^wdqs1020\.eqiad\./ {
    role(wdqs::public)
}

node /^wdqs(2008|201[45])\.codfw\./ {
    role(wdqs::internal)
}

node /^wdqs(200[79]|201[0-3]|201[6-9]|2020)\.codfw\./ {
    role(wdqs::public)
}

node /^wdqs102[1-2].eqiad\./ {
    role(wdqs::main)
}

node /^wdqs102[3-4].eqiad\./ {
    role(wdqs::scholarly)
}

node /^wdqs202[1-2].codfw\./ {
    role(wdqs::main)
}

node /^wdqs202[3-4].codfw\./ {
    role(wdqs::scholarly)
}

node /^wdqs2025.codfw\./ {
    role(wdqs::test)
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
