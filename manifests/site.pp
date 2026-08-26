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

node /^acmechief1002\.eqiad\./ {
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

node /^an-mariadb100[1-2]\.eqiad\./ {
    role(analytics_cluster::mariadb)
}

node /^an-launcher1003\.eqiad\./ {
    role(analytics_cluster::launcher)
}

# Analytics Hadoop test cluster

node /^an-test-master1003\.eqiad\./ {
    role(analytics_test_cluster::hadoop::master)
}

node /^an-test-master1004\.eqiad\./ {
    role(analytics_test_cluster::hadoop::standby)
}

node /^an-test-worker100[1-3]\.eqiad\./ {
    role(analytics_test_cluster::hadoop::worker)
}

node /^an-test-coord1002\.eqiad\./ {
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

# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /^an-worker1(14[2-9]|15[0-9]|16[0-9]|17[0-9]|18[0-9]|19[0-9]|20[0-9]|21[0-9]|22[0-9]|23[0-6])\.eqiad\./ {
    role(analytics_cluster::hadoop::worker)
}

# yarn.wikimedia.org
node /^an-tool1008\.eqiad\./ {
    role(analytics_cluster::hadoop::yarn)
}

# Analytics Zookeeper cluster
node /^an-conf100[4-6]\.eqiad\./ {
    role(analytics_cluster::zookeeper)
}

# Analytics Presto nodes
node /^an-presto10(0[1-9]|1[0-9]|20)\.eqiad\./ {
    role(analytics_cluster::presto::server)
}

# A multi-instance dedicated sanitized wiki replica host T355571
# See https://wikitech.wikimedia.org/wiki/MariaDB#Data_Platform
node /^an-redacteddb1001\.eqiad\./ {
    role(wmcs::db::wikireplicas::dedicated::analytics_multiinstance)
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
node /^aqs10(1[6-9]|2[0-7])\.eqiad\./ {
    role(aqs)
}

node /^aqs200[1-9]|aqs201[0-2]\.codfw\./ {
    role(aqs)
}

node /^archiva1002\.wikimedia\./ {
    role(archiva)
}

# etcd cluster for aux kubernetes cluster
node /^aux-k8s-etcd100[3-5]\.eqiad\./ {
    role(etcd::v3::aux_k8s_etcd)
}

node /^aux-k8s-etcd200[3-5]\.codfw\./ {
    role(etcd::v3::aux_k8s_etcd)
}

# control-plane servers for aux kubernetes cluster
node /^aux-k8s-ctrl[12]00[23]\.(eqiad|codfw)\./ {
    role(aux_k8s::master)
}

# worker nodes for aux kubernetes cluster
node /^aux-k8s-worker[12]00[2-9]\.(eqiad|codfw)\./ {
    role(aux_k8s::worker)
}

# old minio hosts, full, in read only but still in production
node /^backup101[01]\.eqiad\./ {
    role(mediabackup::storage)
}

# new eqiad media backup storage hosts (read-write)
node /^backup101[56789]\.eqiad\./ {
    role(mediabackup::new_storage)
}
node /^backup1020\.eqiad\./ {
    role(mediabackup::new_storage)
}

# eqiad backup storage for databases
node /^backup1008\.eqiad\./ {
    role(backup::databases)
}

# eqiad primary backup storage (NOT the director!)
node /^backup1009\.eqiad\./ {
    role(backup::main)
}

# eqiad backup storage for gerrit/gitlab
node /^backup1012\.eqiad\./ {
    role(backup::repos)
}

# eqiad backup generation for External Storage databases
node /^backup1013\.eqiad\./ {
    role(dbbackups::content)
}

# new backup director
node /^backup1014\.eqiad\./ {
    role(backup)
}

# old minio hosts, full, in read only but still in production
node /^backup201[01]\.codfw\./ {
    role(mediabackup::storage)
}

# new codfw media backup storage hosts (read-write)
node /^backup201[56789]\.codfw\./ {
    role(mediabackup::new_storage)
}
node /^backup2020\.codfw\./ {
    role(mediabackup::new_storage)
}


# New backup node for codfw T294973
node /^backup2008\.codfw\./ {
    role(backup::databases)
}

# New backup node for codfw T307049
node /^backup2009\.codfw\./ {
    role(backup::main)
}

# codfw backup storage for gerrit/gitlab
node /^backup2012\.codfw\./ {
    role(backup::repos)
}

# codfw backup generation for External Storage databases
node /^backup2013\.codfw\./ {
    role(dbbackups::content)
}

# to be setup
node /^backup2014\.codfw\./ {
    role(backup::es)
}

node /^backupmon1001\.eqiad\./ {
    role(dbbackups::monitoring)
}

node /^bast1004\.wikimedia\./ {
    role(bastionhost)
}

node /^bast2003\.wikimedia\./ {
    role(bastionhost)
}

node /^bast3007\.wikimedia\./ {
    role(bastionhost)
}

node /^bast4006\.wikimedia\./ {
    role(bastionhost)
}

node /^bast5005\.wikimedia\./ {
    role(bastionhost)
}

node /^bast6003\.wikimedia\./ {
    role(bastionhost)
}

node /^bast7002\.wikimedia\./ {
    role(bastionhost)
}

# Debian package/docker images building host in production
node /^build200[1-3]\.codfw\./ {
    role(builder)
}

node /^build2004\.codfw\./ {
    role(builder)
}

node /^centrallog[0-9]{4}\.(eqiad|codfw)\./ {
    role(syslog::centralserver)
}

node /^chartmuseum[12]001\.(eqiad|codfw)\./ {
    role(chartmuseum)
}

node /^cloudgw100[34]\.eqiad\./ {
    role(wmcs::cloudgw)
}

node /^cloudgw200[34]-dev\.codfw\./ {
    role(wmcs::cloudgw)
}

node /^cloudlb200[234]-dev\.codfw\./ {
    role(wmcs::cloudlb)
}

node /^cloudcephosd200[4-7]-dev\.codfw\./ {
    role(wmcs::ceph::osd)
}

node /^cloudcephmon200[5-7]-dev\.codfw\./ {
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
node /^gerrit(1003|2002|2003)\.wikimedia\./ {
    role(gerrit)
}

# Zookeeper and Etcd discovery service nodes
node /^conf200[456]\.codfw\./ {
    role(configcluster)
}

# T418914: New etcd and zookeeper cluster nodes
node /^conf200[789]\.codfw\./ {
    role(insetup::serviceops_ferm)
}

node /^conf100[789]\.eqiad\./ {
    role(configcluster)
}

# T435426: New etcd and zookeeper cluster nodes
node /^conf101[0-2]\.eqiad\./ {
    role(insetup::serviceops_ferm)
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

# zuul-legacy - T418109
node /^(contint1002|contint2002)\.wikimedia\./ {
    role(ci)
}

# T418521 - jenkins on Java 21 and trixie
node /^(contint1003|contint2003)\.wikimedia\./ {
    role(jenkins)
}

node /^cp11(0[02468]|1[024])\.eqiad\./ {
    role(cache::text)
}

node /^cp11(0[13579]|1[135])\.eqiad\./ {
    role(cache::upload)
}

node /^cp20(4[3579]|5[1357])\.codfw\./ {
    role(cache::text)
}

node /^cp20(4[468]|5[02468])\.codfw\./ {
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

node /^cumin1003\.eqiad\./ {
    role(cluster::management)
}

node /^cumin2002\.codfw\./ {
    role(insetup::infrastructure_foundations_nftables)
}

node /^cumin2003\.codfw\./ {
    role(cluster::management)
}

node /^cuminunpriv1001\.eqiad\./ {
    role(cluster::unprivmanagement)
}

node /^db190[1-3]\.eqiad\./ {
    role(mariadb::core_test)
}

node /^db290[1-3]\.codfw\./ {
    role(mariadb::core_test)
}

node /^db1300\.eqiad\./ {
    role(mariadb::research)
}

## Analytics Backup Multi-instance
node /^db1208\.eqiad\./ {
    role(mariadb::misc::analytics::backup)
}

# s1 (enwiki) core production dbs on eqiad
node /^db1(163|169|184|186|195|206|218|219|232|234|235|251|277|283)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1196\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
node /^db2(153|170|173|174|176|188|203|212|216)\.codfw\./ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
node /^db1(162|182|188|197|222|229|233|246|254|259|276)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1156\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

node /^db1271\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
node /^db2(175|189|204|207|225|226|238)\.codfw\./ {
    role(mariadb::core)
}

# s3 core production dbs on eqiad
node /^db1(157|166|175|189|198|223|272|280|289)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1212\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s3 core production dbs on codfw
node /^db2(156|177|190|194|205|209|227)\.codfw\./ {
    role(mariadb::core)
}

# s4 (commons) core production dbs on eqiad
node /^db1(160|190|199|238|241|242|244|247|248|249|252)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1221\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# x4 split from commons T404715
node /^db1(260|261|262|263)\.eqiad\./ {
    role(mariadb::core)
}

# Testing cluster
node /^db1176\.eqiad\./ {
    role(mariadb::core_test)
}

# Testing host
node /^db2230\.codfw\./ {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
node /^db2(155|172|179|206|210|219|236|237|240)\.codfw\./ {
    role(mariadb::core)
}

# x4 split from commons T404715
node /^db2(248|247|246|245)\.codfw\./ {
    role(mariadb::core)
}

# s5 (default, dewiki and others) core production dbs on eqiad
node /^db1(159|185|200|207|210|230|274)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1161\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# future eqiad sanitarium master
node /^db1275\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
node /^db2(157|171|178|192|211|213|223|228)\.codfw\./ {
    role(mariadb::core)
}

# s6 (frwiki, jawiki, ruwiki labswiki) core production dbs on eqiad
node /^db1(168|173|180|187|201|282|287)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1165\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# future eqiad sanitarium master
node /^db1279\.eqiad\./ {
    role(mariadb::sanitarium_master)
}
# s6 (frwiki, jawiki, ruwiki labswiki) core production dbs on codfw
node /^db2(158|169|180|193|214|217|224|229)\.codfw\./ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
node /^db1(069|170|174|181|191|194|202|227|231|236|253|284|288)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1158\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# future sanitarium master for s7
node /^db1273\.eqiad\./ {
    role(mariadb::sanitarium_master)
}
# s7 (centralauth, meta et al.) core production dbs on codfw
node /^db2(159|168|182|218|208|220|221|222)\.codfw\./ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on eqiad
node /^db1(172|192|193|209|214|226|286)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1167\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

node /^db1281\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# x3 (split from s8) core production dbs
# the database name is called wikidatawiki
# wbt_* tables
node /^db1(255|256|257|258)\.eqiad\./ {
    role(mariadb::core)
}

node /^db1211\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on codfw
node /^db2(154|161|162|163|164|165|166|167|181|195)\.codfw\./ {
    role(mariadb::core)
}

# x3 (split from s8) core production dbs
# the database name is called wikidatawiki
# wbt_* tables
node /^db2(187|241|242|243|244)\.codfw\./ {
    role(mariadb::core)
}

## x1 shard
# eqiad
node /^db1(179|203|220|237|264|278)\.eqiad\./ {
    role(mariadb::core)
}

# codfw
node /^db2(186|191|196|215|231|249)\.codfw\./ {
    role(mariadb::core)
}

# Refresh hosts T418909
node /^db12(70)\.eqiad\./ {
    role(insetup::data_persistence_ferm)
}

# ms1 ms2 and ms3 shards
# They use the parsercache role in puppet so masters are RW all the time.
# eqiad
node /^db12(67)\.eqiad\./ {
    role(mariadb::parsercache)
}
# codfw
node /^db22(51)\.codfw\./ {
    role(mariadb::parsercache)
}
# ms2 shard
# eqiad
node /^db12(66)\.eqiad\./ {
    role(mariadb::parsercache)
}

# codfw
node /^db22(53)\.codfw\./ {
    role(mariadb::parsercache)
}

# ms3 shard
# eqiad
node /^db12(68)\.eqiad\./ {
    role(mariadb::parsercache)
}

node /^db22(52)\.codfw\./ {
    role(mariadb::parsercache)
}
## m1 shard
# See also multiinstance misc hosts db1217, db2160 below
# m1 master
node /^db1213\.eqiad\./ {
    role(mariadb::misc)
}

# old m1 master
node /^db1164\.eqiad\./ {
    role(mariadb::misc)
}
# m1 codfw master
node /^db2232\.codfw\./ {
    role(mariadb::misc)
}
## m2 shard
# See also multiinstance misc hosts db1217, db2160 below

# m2 master
node /^db1290\.eqiad\./ {
    role(mariadb::misc)
}

# m2 master
node /^db2233\.codfw\./ {
    role(mariadb::misc)
}
## m3 shard
# See also multiinstance misc hosts db1217, db2160 below
# m3 master
node /^db1250\.eqiad\./ {
    role(mariadb::misc::phabricator)
}

# m3 master
node /^db2234\.codfw\./ {
    role(mariadb::misc::phabricator)
}
## m5 shard
# See also multiinstance misc hosts db1217, db2160 below

# old m5 master
node /^db1228\.eqiad\./ {
    role(mariadb::misc)
}

# m5 master
node /^db1243\.eqiad\./ {
    role(mariadb::misc)
}

# m5 codfw master
node /^db2235\.codfw\./ {
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
node /^db1(154|155|269)\.eqiad\./ {
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
node /^dborch1002\.wikimedia\./ {
    role(orchestrator)
}
node /^dborch1003\.eqiad\./ {
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
## s5, x1 & x3
node /^db1216\.eqiad\./ {
    role(mariadb::backup_source)
}
## s2, s6 & x1
node /^db1225\.eqiad\./ {
    role(mariadb::backup_source)
}
## s1 & s2
node /^db1239\.eqiad\./ {
    role(mariadb::backup_source)
}
## s1 & s3
node /^db1240\.eqiad\./ {
    role(mariadb::backup_source)
}
## s4 & s5
node /^db1245\.eqiad\./ {
    role(mariadb::backup_source)
}
## s3 & s4
node /^db1265\.eqiad\./ {
    role(mariadb::backup_source)
}
## s7 & s8
node /^db1285\.eqiad\./ {
    role(mariadb::backup_source)
}

# codfw backup sources
## s3 & s4
node /^db2239\.codfw\./ {
    role(mariadb::backup_source)
}
## s1 & s5
node /^db2250\.codfw\./ {
    role(mariadb::backup_source)
}
## s2, s6 & x1
node /^db2197\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & s8
node /^db2198\.codfw\./ {
    role(mariadb::backup_source)
}
## s4
node /^db2199\.codfw\./ {
    role(mariadb::backup_source)
}
## s7 & x3
node /^db2200\.codfw\./ {
    role(mariadb::backup_source)
}
## s5 & x1
node /^db2201\.codfw\./ {
    role(mariadb::backup_source)
}

# test-s1
node /^db2202\.codfw\./ {
    role(mariadb::core_test)
}

# Analytics production replicas
node /^dbstore100[789]\.eqiad\./ {
    role(mariadb::analytics_replica)
}
# New dbstore server to replace dbstore1007
node /^dbstore1010\.eqiad\./ {
    role(insetup::data_platform_ferm)
}

# database-provisioning and short-term/postprocessing backups servers
node /^dbprov1004\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1005\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1006\.eqiad\./ {
    role(dbbackups::metadata)
}
node /^dbprov1007\.eqiad\./ {
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
node /^dbprov2007\.codfw\./ {
    role(dbbackups::metadata)
}

# Active eqiad proxies for misc databases
node /^dbproxy10(12|13|14|15|16|22|23|24|25|26|27|28|29)\.eqiad\./ {
    role(mariadb::proxy::master)
}

# Passive codfw proxies for misc databases
node /^dbproxy200(5|6|7|8)\.codfw\./ {
    role(mariadb::proxy::master)
}

node /^debmonitor[12]003\.(codfw|eqiad)\./ {
    role(debmonitor::server)
}

node /^debmonitor-dev2001\.codfw\./ {
    role(debmonitor::server_dev)
}

node /^dns[1-9][0-9]{3}\.wikimedia\./ {
    role(dnsbox)
}

node /^doc(1004|2003)\.(codfw|eqiad)\./ {
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
node /^an-druid100[3-7]\.eqiad\./ {
    role(druid::analytics::worker)
}


node /^an-test-druid1001\.eqiad\./ {
    role(druid::test_analytics::worker)
}

# Druid public-eqiad servers.
# These power AQS and wikistats 2.0 and contain non sensitive datasets.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid10(09|1[0-3])\.eqiad\./ {
    role(druid::public::worker)
}

# New druid-internal cluster - See #T417430
node /^druid-internal100[1-6]\.eqiad\./ {
    role(insetup::data_platform_ferm)
}

# dse-k8s-ctrl control plane servers in eqiad
node /^dse-k8s-ctrl100[12]\.eqiad\./ {
    role(dse_k8s::master)
}

# dse-k8s-ctrl control plane servers in codfw
node /^dse-k8s-ctrl200[12]\.codfw\./ {
    role(dse_k8s::master)
}

# dse-k8s-etcd etcd cluster servers in eqiad
node /^dse-k8s-etcd100[1-3]\.eqiad\./ {
    role(etcd::v3::dse_k8s_etcd)
}

# dse-k8s-etcd etcd cluster servers in codfw
node /^dse-k8s-etcd200[1-3]\.codfw\./ {
    role(etcd::v3::dse_k8s_etcd)
}

# dse-k8s-workers T29157, T3074009, T394647, T395557, T398438, T405209, T421465
node /^dse-k8s-worker10(0[1-9]|1[0123489]|2[0-8])\.eqiad\./ {
    role(dse_k8s::worker)
}

# Temporarily remove dse-k8s-worker101[567] from service. See #T429773
node /^dse-k8s-worker101[567]\.eqiad\./ {
    role(insetup::data_platform_ferm)
}

# dse-k8s-workers in codfw - See #T353789, T399778
node /^dse-k8s-worker200[1-3]\.codfw\./ {
    role(dse_k8s::worker)
}

# New dse-k8s-workers in codfw - See T405406
node /^dse-k8s-worker200[4-5]\.codfw\./ {
    role(insetup::data_platform_ferm)
}

# Dedicated dse-k8s worker for testing WDQS in codfw - See #T425653
node /^dse-k8s-wdqs-test2001\.codfw\./ {
    role(dse_k8s::worker::wdqs)
}

# Dedicated dse-k8s worker for testing WDQS in eqiad - See #T425653
node /^dse-k8s-wdqs-test1001\.eqiad\./ {
    role(dse_k8s::worker::wdqs)
}

# Dedicated dse-k8s workers for production WDQS in codfw - See #T425653
node /^dse-k8s-wdqs200[1-4]\.codfw\./ {
    role(dse_k8s::worker::wdqs)
}

# Dedicated dse-k8s workers for production WDQS in eqiad - See #T425653
node /^dse-k8s-wdqs100[1-3]\.eqiad\./ {
    role(dse_k8s::worker::wdqs)
}

# Row A
node /^cirrussearch10(68|69|70|71|72|73|84)\.eqiad\./ {
    role(cirrus::opensearch)
}
# Row B
node /^cirrussearch10(74|75|76|77|78|79|85|86)\.eqiad\./ {
    role(cirrus::opensearch)
}
# Row C
node /^cirrussearch10(80|81|82|83|87|88)\.eqiad\./ {
    role(cirrus::opensearch)
}
# Row D
node /^cirrussearch1103\.eqiad\./ {
    role(cirrus::opensearch)
}
# Row E
node /^cirrussearch1(089|090|091|092|093|094|095|108|109)\.eqiad\./ {
    role(cirrus::opensearch)
}
# Row F
node /^cirrussearch1(096|097|098|099|100|101|102|107|110)\.eqiad\./ {
    role(cirrus::opensearch)
}
# T384966 refresh hosts (post-rename)
node /^cirrussearch11(1[1-9]|2[0-5])\.eqiad\./ {
    role(cirrus::opensearch)
}

# ROW A
node /^cirrussearch2(061|062|069|073|074|075|076|087|088|089|090|091|111)\.codfw\./ {
    role(cirrus::opensearch)
}

# ROW B
node  /^cirrussearch20(63|64|70|77|78|79|80|92|93|94|95|96|97)\.codfw\./ {
    role(cirrus::opensearch)
}

node /^cirrussearch2110\.codfw\./ {
    role(cirrus::opensearch)
}

# ROW C
node /^cirrussearch2(065|066|071|081|082|083|098|099|100|101|102|103|112|113)\.codfw\./ {
    role(cirrus::opensearch)
}
# ROW D
node /^cirrussearch2(067|068|072|084|085|086|104|105|106|107|108|109|114|115)\.codfw\./ {
    role(cirrus::opensearch)
}


# External Storage, Shard 1 (es1) databases
# RO section
## eqiad servers
node /^es1050\.eqiad\./ {
    role(mariadb::core)
}

node /^es1052\.eqiad\./ {
    role(mariadb::core)
}

node /^es1055\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
# es2051 (es1)
node /^es2051\.codfw\./ {
    role(mariadb::core)
}

# es2053 (es1)
node /^es2053\.codfw\./ {
    role(mariadb::core)
}

# es2055 (es1)
node /^es2055\.codfw\./ {
    role(mariadb::core)
}


# External Storage, Shard 2 (es2) databases
# RO section
## eqiad servers
node /^es1049\.eqiad\./ {
    role(mariadb::core)
}

node /^es1053\.eqiad\./ {
    role(mariadb::core)
}

node /^es1056\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
# es2049 (es2)
node /^es2049\.codfw\./ {
    role(mariadb::core)
}

# es2054 (es2)
node /^es2054\.codfw\./ {
    role(mariadb::core)
}

# es2056 (es2)
node /^es2056\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 3 (es3) databases
# RO section
## eqiad servers
node /^es1051\.eqiad\./ {
    role(mariadb::core)
}

node /^es1054\.eqiad\./ {
    role(mariadb::core)
}

node /^es1057\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
# es2050 (es3)
node /^es2050\.codfw\./ {
    role(mariadb::core)
}

# es2052 (es3)
node /^es2052\.codfw\./ {
    role(mariadb::core)
}

# es2057 (es3)
node /^es2057\.codfw\./ {
    role(mariadb::core)
}

# External Storage, Shard 4 (es4) databases
# RO section
## eqiad servers
node /^es1041\.eqiad\./ {
    role(mariadb::core)
}

node /^es1042\.eqiad\./ {
    role(mariadb::core)
}

node /^es1043\.eqiad\./ {
    role(mariadb::core)
}

## codfw servers
node /^es2041\.codfw\./ {
    role(mariadb::core)
}

node /^es2042\.codfw\./ {
    role(mariadb::core)
}

node /^es2043\.codfw\./ {
    role(mariadb::core)
}
# External Storage, Shard 5 (es5) databases
# RO section
## eqiad servers
node /^es1044\.eqiad\./ {
    role(mariadb::core)
}

node /^es1045\.eqiad\./ {
    role(mariadb::core)
}

node /^es1046\.eqiad\./ {
    role(mariadb::core)
}
## codfw servers
node /^es2044\.codfw\./ {
    role(mariadb::core)
}

node /^es2045\.codfw\./ {
    role(mariadb::core)
}

node /^es2046\.codfw\./ {
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

node /^es1047\.eqiad\./ {
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

node /^es2047\.codfw\./ {
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

node /^es1048\.eqiad\./ {
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

node /^es2048\.codfw\./ {
    role(mariadb::core)
}

# eqiad external store storage to set up #T400195
node /^es20(49|50|51)\.codfw\./ {
    role(insetup::data_persistence_ferm)
}

node /^failoid[12]003\.(eqiad|codfw)\./ {
    role(failoid)
}

# T409780
node /^hcaptcha-proxy[1-9][0-9]{3}\./ {
    role(hcaptcha::proxy)
}

# kubernetes masters for staging clusters
node /^kubestagemaster[12]00[345]\.(eqiad|codfw)\./ {
    role(kubernetes::staging::master_stacked)
}

node /^wikikube-ctrl100[2-6]\.eqiad\./ {
    role(kubernetes::master_stacked)
}

node /^wikikube-ctrl200[1-3]\.codfw\./ {
    role(kubernetes::master_stacked)
}

# BEGIN T384970, wikikube-ctrl200[4-5], T406596 wikikube-ctrl2006
node /^wikikube-ctrl200[4-6]\.codfw\./ {
    role(kubernetes::master_stacked)
}
# END T384970 wikikube-ctrl200[4-5], T406596 wikikube-ctrl2006

# Etherpad on bookworm (virtual machine) (T357159, T316421)
node /^etherpad[12]00[24]\.(eqiad|codfw)\./ {
    role(etherpad)
}

node /^lists1004\.wikimedia\./ {
    role(lists)
}

node /^lists2001\.wikimedia\./ {
    role(lists)
}

node /^ganeti10(2[789]|3[0-9]|4[0-9]|5[0-8])\.eqiad\./ {
    role(ganeti)
}

# Routed Ganeti nodes
node /^ganeti203[3-4]\.codfw\./ {
    role(ganeti_routed)
}

node /^ganeti20(2[256789]|3[01256789]|4[0-9]|5[0])\.codfw\./ {
    role(ganeti)
}

node /^ganeti205[123456]\.codfw\./ {
    role(insetup::infrastructure_foundations_nftables)
}

node /^ganeti-test200[123]\.codfw\./ {
    role(ganeti_test)
}

node /^ganeti300[5678]\.esams\./ {
    role(ganeti_routed)
}

node /^ganeti400[5678]\.ulsfo\./ {
    role(ganeti_routed)
}

node /^ganeti500[4567]\.eqsin\./ {
    role(ganeti_routed)
}

node /^ganeti600[1234]\.drmrs\./ {
    role(ganeti)
}

node /^ganeti700[1234]\.magru\./ {
    role(ganeti_routed)
}

# ganeti hosts for large VMs (owned by DPE SRE)
node /^ganeti-jumbo100[123]\.eqiad\./ {
    role(insetup::data_platform_ferm)
}
node /^ganeti-jumbo200[123]\.codfw\./ {
    role(insetup::data_platform_ferm)
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
    role(insetup::collaboration_services_nftables)
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

node /^irc[12]003\.wikimedia\./ {
    role(ircstream)
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

node /^cloudcontrol200[56]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::control)
}

node /^cloudcontrol2010-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::control)
}

node /^cloudvirt200[456]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

# cloudrabbit servers T304888
node /^cloudrabbit100[123]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::rabbitmq)
}

# Soon to be codfw1dev cloudrabbit servers T392539
node /^cloudrabbit200[123]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::rabbitmq)
}

node /^cloudservices200[45]-dev\.codfw\./ {
    role(wmcs::openstack::codfw1dev::services)
}

node /^codesearch[12]001\.(codfw|eqiad)\./ {
    role(insetup::collaboration_services_ferm)
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

node /^idp[12]00[45]\.wikimedia\./ {
    role(idp)
}

node /^cloudidp2001-dev\.codfw\./ {
    role(idp_clouddev)
}

node /^idp-test100[4]\.wikimedia\./ {
    role(idp_test)
}

node /^idp-test[12]005\.wikimedia\./ {
    role(idp_test)
}

node /^install[12]005\.wikimedia\./ {
    role(installserver)
}

node /^install[345]004\.wikimedia\./ {
    role(installserver)
}

node /^install[456]003\.wikimedia\./ {
    role(installserver)
}

node /^install7002\.wikimedia\./ {
    role(installserver)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T370111, T370112)
node /^alert[12]002\.wikimedia\./ {
    role(alerting_host)
}

# Phabricator eqiad (T280540, T279176) (production)
node /^phab1004\.eqiad\./ {
    role(phabricator)
}

# hardware 2024 (eqiad) - T369671
node /^phab1005\.eqiad\./ {
    role(phabricator)
}

# hardware 2026 (eqiad) - T418905
node /^phab1006\.eqiad\./ {
    role(insetup::collaboration_services_nftables)
}

# New Hardware - T423727
node /^phab2003\.codfw\./ {
    role(phabricator)
}

# PKI server
node /^pki[12]002\.(eqiad|codfw)\./ {
    role(pki::multirootca)
}

node /^pki-root1002\.eqiad\./ {
    role(pki::root)
}

node /^kafka-logging100[1-5]\.eqiad\./ {
    role(kafka::logging)
}

node /^kafka-logging200[1-5]\.codfw\./ {
    role(kafka::logging)
}

node /^kafka-main10(0[6-9]|10)\.eqiad\./ {
    role(kafka::main)
}

node /^kafka-main20(0[6-9]|10)\.codfw\./ {
    role(kafka::main)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo101[0-8]\.eqiad\./ {
    role(kafka::jumbo::broker)
}

# Kafkamon bullseye hosts
node /^kafkamon[12]003\.(codfw|eqiad)\./ {
    role(kafka::monitoring)
}

node /^krb100[234]\.eqiad\./ {
    role(kerberos::kdc)
}

node /^krb2002\.codfw\./ {
    role(kerberos::kdc)
}

node /^wikikube-worker10(0[67]|1[56]|21|3[4-9]|4[0-9]|5[0-7]|6[4-9]|7[0-9]|8[01]|8[4-7]|9[3-5])\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker11(1[3-9]|[2-5][0-9]|6[0-5])\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker13(7[5-9]|8[0-4])\.eqiad\./ {
    role(kubernetes::worker)
}

# T368933, T369743 NOTE: We use those hostnames because we are going to be
# renaming parse*, mw*, kubernetes* and those add up to 1231. Leeway included
node /^wikikube-worker1(2[4-9][0-9]|3[0-1][0-9]|32[0-9]|33[0-9]|3[4-6][0-9]|37[0-4])\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker20(0[1256]|1[1-9]|3[3-9]|4[124679]|5[015-9]|6[0-24-9]|7[0-8]|8[5-9]|9[0-5])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker21(0[2-9]|1[0-5]|2[4-9]|[3-9][0-9])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker22(0[0-9]|1[0-5]|4[2389]|[5-9][0-9])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker23([0-3][0-9]|[4-6][0-9]|7[0-4])\.codfw\./ {
    role(kubernetes::worker)
}

# mw-experimental workers T276994 T397051
node /^wikikube-worker-exp1001\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker-exp2001\.codfw\./ {
    role(kubernetes::worker)
}

node /^kubestage100[3-6]\.eqiad\./ {
    role(kubernetes::staging::worker)
}

node /^kubestage200[1234]\.codfw\./ {
    role(kubernetes::staging::worker)
}

node /^cloudcontrol100[67]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::control)
}

node /^cloudcontrol1011.eqiad\./ {
    role(wmcs::openstack::eqiad1::control)
}

# Data Platform - Ceph cluster in eqiad
node /^cephosd100[1-5]\.eqiad\./ {
    role(ceph::server)
}

# Data Platform - Ceph cluster in codfw
node /^cephosd200[1-3]\.codfw\./ {
    role(ceph::server)
}

# cloudceph monitor nodes
node /^cloudcephmon100[4-6]\.eqiad\./ {
    role(wmcs::ceph::mon)
}

# cloudceph storage nodes
node /^cloudcephosd10(1[6-9]|2[0-9]|3[0-9]|4[0-9]|5[0-2])\.eqiad\./ {
    role(wmcs::ceph::osd)
}

node /^cloudcephosd10(5[3-6])\.eqiad\./ {
    role(insetup::wmcs_nftables)
}


node /^cloudelastic100[7-9]\.eqiad\./ {
    role(cirrus::cloudelastic)
}

node /^cloudelastic101[0-2]\.eqiad\./ {
    role(cirrus::cloudelastic)
}

node /^cloudnet100[56]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::net)
}

## Multi-instance wikireplica dbs
node /^clouddb10(13|14|15|16|22|24|26|27|28|29)\.eqiad\./ {
    role(wmcs::db::wikireplicas::web_multiinstance)
}
node /^clouddb10(17|18|20|23|25|30|31|32|33)\.eqiad\./ {
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
node /^logging-hd200[1-5]\.codfw\./ {
    role(logging::opensearch::data)
}

# Logging data nodes, ssd class (codfw)
node /^logstash20(3[34567])\.codfw\./ {
    role(logging::opensearch::data)
}

node /^logging-sd200[1-7]\.codfw\./ {
    role(logging::opensearch::data)
}

# Logging collector nodes (codfw)
node /^logstash20(2[345]|3[012])\.codfw\./ {
    role(logging::opensearch::collector)
}

# Logging data nodes, hdd class (eqiad)
node /^logging-hd100[1-5]\.eqiad\./ {
    role(logging::opensearch::data)
}

# Logging data nodes, ssd class (eqiad)
node /^logstash10(3[34567])\.eqiad\./ {
    role(logging::opensearch::data)
}

node /^logging-sd100[1-7]\.eqiad\./ {
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

# codfw lvs
node /^lvs20(1[1234])\.codfw\./ {
    role(lvs::balancer)
}

node /^lvs30(0[89]|10)\.esams\./ {
    role(liberica)
}

# ULSFO lvs servers
node /^lvs40(0[89]|10)\.ulsfo\./ {
    role(liberica)
}

# EQSIN lvs servers
node /^lvs500[456]\.eqsin\./ {
    role(liberica)
}

# DRMRS lvs servers
node /^lvs600[123]\.drmrs\./ {
    role(liberica)
}

# MAGRU lvs servers
node /^lvs700[123]\.magru\./ {
    role(liberica)
}

node /^maps101[2-4]\.eqiad\./ {
    role(maps::replica_bookworm)
}

node /^maps1011\.eqiad\./ {
    role(maps::master_bookworm)
}

node /^maps201[2-4]\.codfw\./ {
    role(maps::replica_bookworm)
}

node /^maps2011\.codfw\./ {
    role(maps::master_bookworm)
}

node /^maps-test2001\.codfw\./ {
    role(maps::staging)
}

# Bookworm replacement for matomo1002 - T349397
node /^matomo1003\.eqiad\./ {
    role(matomo)
}

# T412255
node /^mc10(5[5-9]|6[0-9]|7[0-2])\.eqiad\./ {
    role(mediawiki::memcached)
}

node /^mc20(3[8-9]|4[0-9]|5[0-5])\.codfw\./ {
    role(mediawiki::memcached)
}

node /^mc-gp100[1-3]\.eqiad\./ {
    role(insetup::serviceops_ferm)
}

node /^mc-gp200[1-3]\.codfw\./ {
    role(insetup::serviceops_ferm)
}

node /^mc-gp100[4-6]\.eqiad\./ {
    role(mediawiki::memcached::gutter)
}

node /^mc-gp200[4-6]\.codfw\./ {
    role(mediawiki::memcached::gutter)
}

node /^mc-misc100[1-2]\.eqiad\./ {
    role(insetup::serviceops_nftables)
}

node /^mc-misc200[1-2]\.codfw\./ {
    role(insetup::serviceops_nftables)
}

# new mc-wf nodes T313963
node /^mc-wf100[12]\.eqiad\./ {
    role(mediawiki::memcached::wikifunctions)
}

# New mc-wf nodes T313966
node /^mc-wf200[1-2]\.codfw\./ {
    role(mediawiki::memcached::wikifunctions)
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

node /^ml-serve10(0[1-9]|1[012345])\.eqiad\./ {
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
    role(ml_lab::gpu)
}

node /^ml-build100[12]\.eqiad\./ {
    role(ml_builder)
}

node /^moss-fe100[12]\.eqiad\./ {
    role(cephadm::rgw)
}

node /^apus-fe100\d\.eqiad\./ {
    role(cephadm::rgw)
}

# Controller for the eqiad apus cephadm cluster
node /^apus-be1005\.eqiad\./ {
    role(cephadm::controller)
}

node /^moss-be100[123]\.eqiad\./ {
    role(cephadm::storage)
}

node /^apus-be100[46789]\.eqiad\./ {
    role(cephadm::storage)
}

# Controller for the codfw apus cephadm cluster
node /^apus-be2005\.codfw\./ {
    role(cephadm::controller)
}

node /^moss-be200[123]\.codfw\./ {
    role(cephadm::storage)
}

node /^apus-be200[46789]\.codfw\./ {
    role(cephadm::storage)
}

node /^moss-fe200[12]\.codfw\./ {
    role(cephadm::rgw)
}

node /^apus-fe200\d\.codfw\./ {
    role(cephadm::rgw)
}

# eqiad media backup worker hosts
node /^ms-backup100[34]\.eqiad\./ {
    role(mediabackup::worker)
}

# codfw media backup worker hosts
node /^ms-backup200[34]\.codfw\./ {
    role(mediabackup::worker)
}

node /^ms-fe1\d\d\d\.eqiad\./ {
    role(swift::proxy)
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be1\d\d\d\.eqiad\./ {
    role(swift::storage)
}

node /^ms-fe2\d\d\d\.codfw\./ {
    role(swift::proxy)
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be2\d\d\d\.codfw\./ {
    role(swift::storage)
}

# mw logging host eqiad
node /^mwlog1002\.eqiad\./ {
    role(logging::mediawiki::udp2log)
}

# mw logging host codfw
node /^mwlog2002\.codfw\./ {
    role(logging::mediawiki::udp2log)
}

# observability test hosts
node /^o11ytest[12]001\.(eqiad|codfw)\./ {
    role(insetup::observability_nftables)
}

node /^mwlog[12]003\.(eqiad|codfw)\./ {
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

node /^vrts1003\.eqiad\./ {
    role(vrts)
}

node /^vrts1004\.eqiad\./ {
    role(insetup::collaboration_services_nftables)
}

node /^vrts2002\.codfw\./ {
    role(vrts)
}

# parser cache databases
# eqiad
# pc1
node /^pc1021\.eqiad\./ {
    role(mariadb::parsercache)
}

# pc2
node /^pc1022\.eqiad\./ {
    role(mariadb::parsercache)
}
# pc3
node /^pc1023\.eqiad\./ {
    role(mariadb::parsercache)
}
# pc4
node /^pc1024\.eqiad\./ {
    role(mariadb::parsercache)
}

# pc5
node /^pc1015\.eqiad\./ {
    role(mariadb::parsercache)
}

# pc6
node /^pc1016\.eqiad\./ {
    role(mariadb::parsercache)
}

# pc7
node /^pc1017\.eqiad\./ {
    role(mariadb::parsercache)
}

# pc8
node /^pc1018\.eqiad\./ {
    role(mariadb::parsercache)
}

# codfw
# pc1
node /^pc2021\.codfw\./ {
    role(mariadb::parsercache)
}

# pc2
node /^pc2022\.codfw\./ {
    role(mariadb::parsercache)
}
# pc3
node /^pc2023\.codfw\./ {
    role(mariadb::parsercache)
}

# pc4
node /^pc2024\.codfw\./ {
    role(mariadb::parsercache)
}

# pc5
node /^pc2015\.codfw\./ {
    role(mariadb::parsercache)
}

# pc6
node /^pc2016\.codfw\./ {
    role(mariadb::parsercache)
}

# pc7
node /^pc2017\.codfw\./ {
    role(mariadb::parsercache)
}

# pc8
node /^pc2018\.codfw\./ {
    role(mariadb::parsercache)
}

# Virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[12]004\.(eqiad|codfw)\./ {
    role(ping_offload)
}

# Virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]003\.(eqiad|codfw)\./ {
    role(planet)
}

node /^poolcounter[12]00[5-7]\.(codfw|eqiad)\./ {
    role(poolcounter::server)
}

node /^prometheus200[5678]\.codfw\./ {
    role(prometheus)
}

node /^prometheus100[5678]\.eqiad\./ {
    role(prometheus)
}

node /^prometheus[34567]00[1-9]\.(esams|ulsfo|eqsin|drmrs|magru)\./ {
    role(prometheus::pop)
}

node /^puppetboard[12]003\.(codfw|eqiad)\./ {
    role(puppetboard)
}

node /^puppetdb[12]003\.(codfw|eqiad)\./ {
    role(puppetdb)
}

node /^puppetserver100[123]\.eqiad\./ {
    role(puppetserver)
}

node /^puppetserver200[124]\.codfw\./ {
    role(puppetserver)
}

node /^puppetserver200[56]\.codfw\./ {
    role(insetup::infrastructure_foundations_ferm)
}

# pybal-test2003 VM is used for pybal testing/development
node /^pybal-test2003\.codfw\./ {
    role(pybaltest)
}

node /^rdb101[35]\.eqiad\./ {
    role(redis::misc::master)
}

node /^rdb101[46]\.eqiad\./ {
    role(redis::misc::slave)
}

node /^rdb201[13]\.codfw\./ {
    role(redis::misc::master)
}

node /^rdb201[24]\.codfw\./ {
    role(redis::misc::slave)
}

# new redis for lockmanager T434188
node /^rdb-lock100[1-3]\.eqiad\./ {
    role(redis::lock::instance)
}

node /^rdb-lock200[1-3]\.codfw\./ {
    role(redis::lock::instance)
}

node /^registry[12]00[345]\.(eqiad|codfw)\./ {
    role(docker_registry)
}

# https://releases.wikimedia.org - VMs for releases files (mediawiki and other)
# https://releases-jenkins.wikimedia.org (automatic MediaWiki builds)
node /^releases[12]003\.(codfw|eqiad)\./ {
    role(releases)
}

# releases on trixie (T418299)
node /^releases[12]004\.(codfw|eqiad)\./ {
    role(insetup::collaboration_services_nftables)
}

# relevance forge servers (run opensearch, owned by DPE SRE)
node /^relforge10(08|09|10)\.eqiad\./ {
    role(cirrus::relforge)
}

# restbase eqiad cluster
node /^restbase10(3[1-9]|4[0-5])\.eqiad\./ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(2[4-9]|3[0-8])\.codfw\./ {
    role(restbase::production)
}

# T416538: FY2526 Q3:rack/setup/install restbase2039
node /^restbase2039\.codfw\./ {
    role(insetup::data_persistence_ferm)
}

# decommissioning
node /^restbase10(2[8-9]|30)\.eqiad\./ {
    role(insetup::data_persistence_ferm)
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
# VMs on trixie, access for all shell users (T280989, T338827, T402596)
node /^people(1005|2004)\.(eqiad|codfw)\./ {
    role(microsites::peopleweb)
}

# parsoidtest1001 is a parsoid test server. it replaced scandium.
# This is now just like an MW appserver plus parsoid repo.
# roundtrip and visualdiff testing moved to testreduce* (T257906)
# Host will be decommed  T421484
node /^parsoidtest1001\.eqiad\./ {
    role(insetup::serviceops_ferm)
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

# The hosts contain all the tools and libraries to access
# the Analytics Cluster services.
node /^stat10(0[8-9]|1[0-1])\.eqiad\./ {
    role(statistics::explorer)
}

# Servers for SRE tests which are not suitable for Cloud VPS
node /^sretest100[56]\.eqiad\./ {
    role(sretest)
}

# Servers for SRE tests in codfw
node /^sretest20(0[1234569])\.codfw\./ {
    role(sretest)
}

# Test node for Data Persistence - T394357
node /^sretest2010\.codfw\./ {
    role(swift::storage)
}

# generic TCP proxy (T408064) - first used for gerrit-ssh
node /^tcp-proxy[1-7]00[1-9]\.(codfw|drmrs|eqiad|eqsin|esams|magru|ulsfo)\./ {
    role(tcpproxy)
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
# also see parsoidtest1001.eqiad.wmnet
# Host will be decommed  T421484
node /^testreduce1002\.eqiad\./ {
    role(insetup::serviceops_ferm)

}

node /^testvm2006.codfw\./ {
    role(test_krb)
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

node /^thanos-fe10\d\d\.eqiad\./ {
    role(thanos::frontend)
}

node /^thanos-fe20\d\d\.codfw\./ {
    role(thanos::frontend)
}

# control-plane servers for toolforge k8s cluster
node /^tools-k8s-ctrl100[12]\.eqiad\./ {
    role(insetup::wmcs_ferm)
}

# worker nodes for toolforge k8s cluster
node /^tools-k8s-worker100[1-8]\.eqiad\./ {
    role(insetup::wmcs_ferm)
}

# deployment servers
node /^deploy(1003|200[23])\.(eqiad|codfw)\./ {
    role(deployment_server::kubernetes)
}

# https://wikitech.wikimedia.org/wiki/Url-downloader
node /^urldownloader[12]00[34]\.wikimedia\./ {
    role(url_downloader)
}

node /^urldownloader[12]00[56]\.wikimedia\./ {
    role(url_downloader)
}

# These are hypervisors that use local storage for their VMs
#  rather than ceph. This is necessary for low-latency workloads
#  like etcd.
node /^cloudvirtlocal100[1-3]\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt)
}

# cloudvirt servers T305194, T299574, T342537
node /^cloudvirt10(4[0-9]|5[0-9]|6[0-9]|7[0-9]|8[0])\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

## WCQS public (there is not WCQS private)
node /^wcqs100[123]\.eqiad\./ {
    role(wcqs::public)
}

node /^wcqs200[123]\.codfw\./ {
    role(wcqs::public)
}

## WDQS public main
node /^wdqs10(11|12|13|14|16|17|18|19|20|21|22)\.eqiad\./ {
    role(wdqs::main)
}
node /^wdqs20(07|08|10|11|12|13|14|15|21|22)\.codfw\./ {
    role(wdqs::main)
}

## WDQS internal main
node /^wdqs10(25|26).eqiad\./ {
    role(wdqs::internal_main)
}
node /^wdqs20(18|19|20).codfw\./ {
    role(wdqs::internal_main)
}

## WDQS public scholary
node /^wdqs10(23|24).eqiad\./ {
    role(wdqs::scholarly)
}
node /^wdqs20(16|23|24).codfw\./ {
    role(wdqs::scholarly)
}

## WDQS internal scholarly
node /^wdqs1027.eqiad\./ {
    role(wdqs::internal_scholarly)
}
node /^wdqs20(17|26|27).codfw\./ {
    role(wdqs::internal_scholarly)
}

## WDQS test servers
node /^wdqs2025.codfw\./ {
    role(wdqs::test)
}

## WDQS test server (to validate Blazegraph alternatives)
node /^wdqs10(29|30|31|32).eqiad\./ {
    role(wdqs::alternatives)
}

node /^wdqs10(3[3-5]).eqiad\./ {
    role(insetup::data_platform_ferm)
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

# new zuul machines - T393873

# zuul - main
node /^zuul([1-2]001)\.(codfw|eqiad)\./ {
    role(zuul::main)
}

# zuul - executors
node /^zuul([1-2]002)\.(codfw|eqiad)\./ {
    role(zuul::executor)
}

# zuul - trusted build nodes
node /^zuul([1-2]003)\.(codfw|eqiad)\./ {
    role(zuul::trusted_build_node)
}

# zuul - physical hardware (T427353)
node /^zuul1004\.eqiad\./ {
    role(zuul::main)
}

node /^zuul100[5-7]\.eqiad\./ {
    role(insetup::collaboration_services_nftables)
}

node default {
    if $::realm == 'production' and (!defined('$::_role') or !$::_role) {

        # hostname prefix default role mappings
        #
        # try to prevent one or more patch round trips for dcops when
        # bringing online hardware matching an established prefix
        #
        # this is meant to use the certificate hostname value which
        # must be signed by an authenticated user or script

        # lint:ignore:wmf_styleguide
        case $trusted['hostname'] {
            /^kafka-logging/:  { role(insetup::observability_nftables) }
            default:           { fail('No puppet role has been assigned to this node.') }
        }
        # lint:endignore

    } elsif $::realm == 'labs' {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require role::wmcs::instance  # lint:ignore:wmf_styleguide
    }
}
