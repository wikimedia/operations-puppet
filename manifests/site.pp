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

# Namenode servers for the temporary HDFS backup cluster
node /^an-backup-namenode100[1-2]\.eqiad\./ {
    role(insetup::data_platform_ferm)
}

# Datanode servers for the temporary HDFS backup cluster
node /^an-backup-datanode10(0[1-9]|2[0-9]|3[0-9]|4[0-6])\.eqiad\./ {
    role(insetup::data_platform_ferm)
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
node /^an-test-master1001\.eqiad\./ {
    role(analytics_test_cluster::hadoop::master)
}

node /^an-test-master1002\.eqiad\./ {
    role(analytics_test_cluster::hadoop::standby)
}

node /^an-test-master100[3-4]\.eqiad\./ {
    role(insetup::data_platform_ferm)
}

node /^an-test-worker100[1-3]\.eqiad\./ {
    role(analytics_test_cluster::hadoop::worker)
}

node /^an-test-coord1001\.eqiad\./ {
    role(analytics_test_cluster::coordinator)
}

# New an-test-coord1002 - See #T393029
node /^an-test-coord1002\.eqiad\./ {
    role(insetup::data_platform_ferm)
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
node /^an-worker1(11[7-9]|12[0-9]|13[0-9]|14[0-9]|15[0-9]|16[0-9]|17[0-9]|18[0-9]|19[0-9]|20[0-9]|21[0-9]|22[0-9]|23[0-6])\.eqiad\./ {
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
node /^an-airflow100(2|[3-7])\.eqiad\./ {
    role(insetup::data_platform_ferm)
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
node /^aqs10(1[0-2]|1[4-9]|2[0-2])\.eqiad\./ {
    role(aqs)
}

# Hardware refreshes: T407032
node /^aqs102[3-7]\.eqiad\./ {
    role(insetup::data_persistence_ferm)
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
node /^aux-k8s-worker[12]00[2-5]\.(eqiad|codfw)\./ {
    role(aux_k8s::worker)
}
# T393053 and T393054
node /^aux-k8s-worker[12]00[6-9]\.(eqiad|codfw)\./ {
    role(insetup::infrastructure_foundations_ferm)
}

# eqiad bacula storage for External Storage databases
node /^backup1003\.eqiad\./ {
    role(backup::es)
}

# eqiad media backup storage
node /^backup100[4567]\.eqiad\./ {
    role(mediabackup::storage)
}
node /^backup101[01]\.eqiad\./ {
    role(mediabackup::storage)
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

# codfw bacula for External Storage DBs
node /^backup2003\.codfw\./ {
    role(backup::es)
}

# codfw media backup storage
node /^backup200[4567]\.codfw\./ {
    role(mediabackup::storage)
}
node /^backup201[01]\.codfw\./ {
    role(mediabackup::storage)
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
    role(insetup::data_persistence_ferm)
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
    role(insetup::infrastructure_foundations_ferm)
}

node /^bast7002\.wikimedia\./ {
    role(bastionhost)
}

# Debian package/docker images building host in production
node /^build200[1-3]\.codfw\./ {
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

node /^cloudgw200[23]-dev\.codfw\./ {
    role(wmcs::cloudgw)
}

node /^cloudlb200[234]-dev\.codfw\./ {
    role(wmcs::cloudlb)
}

node /^cloudcephosd200[4-7]-dev\.codfw\./ {
    role(wmcs::ceph::osd)
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
node /^gerrit(1003|2002|2003)\.wikimedia\./ {
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

# New nodes - T392851
node /^cp20(4[3-9]|5[0-8])\.codfw\./ {
    role(insetup_noferm)
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

node /^cumin1002\.eqiad\./ {
    role(insetup::infrastructure_foundations_ferm)
}

node /^cumin1003\.eqiad\./ {
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

node /^db-test100[1-3]\.eqiad\./ {
    role(mariadb::core_test)
}

node /^db-test200[1-2]\.codfw\./ {
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
node /^db1(163|169|184|186|195|206|218|219|232|234|235|251)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1196\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s1 (enwiki) core production dbs on codfw
node /^db2(145|146|153|170|173|174|176|188|203|212|216)\.codfw\./ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
# See also db1239 below
node /^db1(162|182|188|197|222|229|233|246|254|259)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1156\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s2 (large wikis) core production dbs on codfw
node /^db2(148|175|189|204|207|225|226|238)\.codfw\./ {
    role(mariadb::core)
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
node /^db2(149|156|177|190|194|205|209|227)\.codfw\./ {
    role(mariadb::core)
}

# s4 (commons) core production dbs on eqiad
# See also db1245 and db1150 below
node /^db1(160|190|199|238|241|242|243|244|247|248|249|252|260|261|262|263)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1221\.eqiad\./ {
    role(mariadb::sanitarium_master)
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
node /^db2(147|155|172|179|206|210|219|236|237|240|245|246|247|248)\.codfw\./ {
    role(mariadb::core)
}

# s5 (default, dewiki and others) core production dbs on eqiad
# See also db1216 and db1245 below
node /^db1(159|185|200|207|210|230)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1161\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s5 (default, dewiki and others) core production dbs on codfw
node /^db2(157|171|178|192|211|213|223|228)\.codfw\./ {
    role(mariadb::core)
}

# s6 (frwiki, jawiki, ruwiki labswiki) core production dbs on eqiad
node /^db1(168|173|180|187|201)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1165\.eqiad\./ {
    role(mariadb::sanitarium_master)
}


# s6 (frwiki, jawiki, ruwiki labswiki) core production dbs on codfw
node /^db2(151|158|169|180|193|214|217|224|229)\.codfw\./ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
node /^db1(069|170|174|178|181|191|194|202|227|231|236|253)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1158\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
node /^db2(150|159|168|182|218|208|220|221|222)\.codfw\./ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on eqiad
node /^db1(172|177|192|193|203|209|214|226)\.eqiad\./ {
    role(mariadb::core)
}

# eqiad sanitarium master
node /^db1167\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# x3 (split from s8) core production dbs
# the database name is called wikidatawiki
node /^db1(255|256|257|258)\.eqiad\./ {
    role(mariadb::core)
}

node /^db1211\.eqiad\./ {
    role(mariadb::sanitarium_master)
}

# s8 (wikidata) core production dbs on codfw
node /^db2(152|154|161|162|163|164|165|166|167|181|195)\.codfw\./ {
    role(mariadb::core)
}

# x3 (split from s8) core production dbs
# the database name is called wikidatawiki
node /^db2(187|241|242|243|244)\.codfw\./ {
    role(mariadb::core)
}

## x1 shard
# eqiad
node /^db1(179|220|224|237|264)\.eqiad\./ {
    role(mariadb::core)
}

# codfw
node /^db2(186|191|196|215|231)\.codfw\./ {
    role(mariadb::core)
}

# x1 expansion T405272
node /^db224[9]\.codfw\./ {
    role(insetup::data_persistence_ferm)
}

# Refresh hosts T405273
node /^db12(65|66|67|68|69|70|71|72|73|74|75|76|77|78|79|80|81|82|83|84|85|86|87|88|89|90|91|92|93|94|95|96|97|98)\.eqiad\./ {
    role(insetup::data_persistence_ferm)
}
# ms1 ms2 and ms3 shards
# They use the parsercache role in puppet so masters are RW all the time.
# eqiad
node /^db11(52)\.eqiad\./ {
    role(mariadb::parsercache)
}

# codfw
node /^db21(42)\.codfw\./ {
    role(mariadb::parsercache)
}

# ms2 shard
# eqiad

node /^db11(51)\.eqiad\./ {
    role(mariadb::parsercache)
}

# codfw
node /^db21(44)\.codfw\./ {
    role(mariadb::parsercache)
}

# ms3 shard
# eqiad
node /^db11(53)\.eqiad\./ {
    role(mariadb::parsercache)
}

# codfw
node /^db21(43)\.codfw\./ {
    role(mariadb::parsercache)
}
## m1 shard
# See also multiinstance misc hosts db1217, db2160 below
# m1 master
node /^db1213\.eqiad\./ {
    role(mariadb::misc)
}

# m1 codfw master
node /^db2232\.codfw\./ {
    role(mariadb::misc)
}
## m2 shard
# See also multiinstance misc hosts db1217, db2160 below

# m2 master
node /^db1228\.eqiad\./ {
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

# m5 master
node /^db1164\.eqiad\./ {
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
node /^db1(154|155)\.eqiad\./ {
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
## s3 & s4
node /^db1150\.eqiad\./ {
    role(mariadb::backup_source)
}
## s7 & s8
node /^db1171\.eqiad\./ {
    role(mariadb::backup_source)
}
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

# codfw backup sources
## s3 & s4
node /^db2239\.codfw\./ {
    role(mariadb::backup_source)
}
## s1
node /^db2141\.codfw\./ {
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

# dse-k8s-crtl control plane servers in eqiad
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

# dse-k8s-workers T29157, T3074009, T394647, T395557, T398438, T405209
node /^dse-k8s-worker10(0[1-9]|1[0-9])\.eqiad\./ {
    role(dse_k8s::worker)
}

# dse-k8s-workers in codfw - See #T353789, T399778
node /^dse-k8s-worker200[1-3]\.codfw\./ {
    role(dse_k8s::worker)
}

# New dse-k8s-workers in codfw - See T405406
node /^dse-k8s-worker200[4-5]\.codfw\./ {
    role(insetup::data_platform_ferm)
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

# soon-to-be-decommed T395855
node /^cirrussearch20[55-60]\.codfw\./ {
    role(insetup::data_platform_ferm)
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
# es2028
node /^es2028\.codfw\./ {
    role(mariadb::core)
}

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

# Will replace es1033
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

# Testing debian trixie - this host will be decommissioned T408772 T409257
node /^es1033\.eqiad\./ {
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

node /^failoid[12]002\.(eqiad|codfw)\./ {
    role(insetup::infrastructure_foundations_ferm)
}

node /^failoid[12]003\.(eqiad|codfw)\./ {
    role(failoid)
}

# hcaptcha proxy (T405631)
node /^hcaptcha[1-9][0-9]{3}\./ {
    role(hcaptcha_proxy)
}

# hcaptcha proxy: bird-based (T409780). This will replace role(hcaptcha_proxy)
node /^hcaptcha-proxy[1-9][0-9]{3}\./ {
    role(hcaptcha::proxy)
}

# kubernetes masters for staging clusters
node /^kubestagemaster[12]00[345]\.(eqiad|codfw)\./ {
    role(kubernetes::staging::master_stacked)
}

node /^wikikube-ctrl100[2-4]\.eqiad\./ {
    role(kubernetes::master_stacked)
}

node /^wikikube-ctrl200[1-3]\.codfw\./ {
    role(kubernetes::master_stacked)
}

# BEGIN T384970 wikikube-ctrl200[4-5]
node /^wikikube-ctrl200[4-5]\.codfw\./ {
    role(insetup::serviceops_ferm)
}
# END T384970 wikikube-ctrl200[4-5]

node /^wikikube-ctrl2006\.codfw\./ {
    role(insetup::serviceops_ferm)
}

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

node /^ganeti10(2[3456789]|3[0-9]|4[0-9]|5[0-4])\.eqiad\./ {
    role(ganeti)
}

# Routed Ganeti nodes
node /^ganeti203[3-4]\.codfw\./ {
    role(ganeti_routed)
}

node /^ganeti20(2[256789]|3[01256789]|4[0-9]|5[0])\.codfw\./ {
    role(ganeti)
}

node /^ganeti-test200[123]\.codfw\./ {
    role(ganeti_test)
}

node /^ganeti300[5678]\.esams\./ {
    role(ganeti_routed)
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

# New cloudnet node used for OVS experiments
node /^cloudnet200[78]-dev\.codfw\./ {
    role(insetup_noferm)
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

node /^install3004\.wikimedia\./ {
    role(installserver)
}

node /^install[3456]003\.wikimedia\./ {
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

# new hardware (eqiad) - T369671
node /^phab1005\.eqiad\./ {
    role(phabricator::migration)
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
    role(insetup::infrastructure_foundations_ferm)
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
    role(insetup::infrastructure_foundations_ferm)
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

# See T397447
node /^kafka-jumbo100[7-9].eqiad\./ {
    role(insetup::data_platform_ferm)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo101[0-8]\.eqiad\./ {
    role(kafka::jumbo::broker)
}

# Kafkamon bullseye hosts
node /^kafkamon[12]003\.(codfw|eqiad)\./ {
    role(kafka::monitoring_bullseye)
}

node /^krb1002\.eqiad\./ {
    role(kerberos::kdc)
}

node /^krb2002\.codfw\./ {
    role(kerberos::kdc)
}

node /^wikikube-worker10(0[2-7]|1[12569]|2[019]|3[014-9]|[4-9][0-9])\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker11([0-5][0-9]|6[0-8])\.eqiad\./ {
    role(kubernetes::worker)
}

# T368933, T369743 NOTE: We use those hostnames because we are going to be
# renaming parse*, mw*, kubernetes* and those add up to 1231. Leeway included
node /^wikikube-worker1(2[4-9][0-9]|3[0-1][0-9]|32[0-7])\.eqiad\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker20(0[1-9]|[1-9][0-9])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker21([0-9][0-9])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker22([0-3][0-9]|4([0-3]|[8-9])|[5-9][0-9])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker23([0-2][0-9]|3[0])\.codfw\./ {
    role(kubernetes::worker)
}

node /^wikikube-worker2331\.codfw\./ {
    role(insetup::serviceops_ferm)
}

# T408749 eqiad expansion
node /^wikikube-worker13(2[8-9]|3[0-4])\.eqiad\./ {
    role(insetup::serviceops_ferm)
}

# T408752 eqiad refresh
node /^wikikube-worker13(3[5-9]|[4-5][0-9])\.eqiad\./ {
    role(insetup::serviceops_ferm)
}

# T408760 eqiad refresh
node /^wikikube-worker13(6[0-9]|7[0-2])\.eqiad\./ {
    role(insetup::serviceops_ferm)
}

# T408757 codfw expansion
node /^wikikube-worker23(3[2-9]|4[0-9]|5[0-6])\.codfw\./ {
    role(insetup::serviceops_ferm)
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

# New cloudcontrol nodes T342455
node /^cloudcontrol10(0[8-9]|1[0])\-dev\.eqiad\./ {
    role(insetup::wmcs_ferm)
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

# migrate cloudelastic to opensearch, see T387904
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
node /^clouddb10(13|14|15|16|22|24)\.eqiad\./ {
    role(wmcs::db::wikireplicas::web_multiinstance)
}
node /^clouddb10(17|18|19|20|23|25)\.eqiad\./ {
    role(wmcs::db::wikireplicas::analytics_multiinstance)
}
# clouddb1021 is skipped, it was a special host that's now gone
node /^clouddb10(2[6-9]|3[0-3])\.eqiad\./ {
    role(insetup::wmcs_ferm)
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

node /^logging-sd200[1-4]\.codfw\./ {
    role(logging::opensearch::data)
}

node /^logging-sd200[567]\.codfw\./ {
    role(insetup::observability_ferm)
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

node /^logging-sd100[1-4]\.eqiad\./ {
    role(logging::opensearch::data)
}

node /^logging-sd100[567]\.eqiad\./ {
    role(insetup::observability_ferm)
}

# Logging collector nodes (eqiad)
node /^logstash10(2[345]|3[012])\.eqiad\./ {
    role(logging::opensearch::collector)
}

# new lvs servers T295804 (in prod use)
node /^lvs10(1[689]|20)\.eqiad\./ {
    role(lvs::balancer)
}

# Setting up lvs1017 for testing (T387145)
node /^lvs1017\.eqiad\./ {
    role(insetup_noferm)
}

# old lvs servers T295804 (insetup for future experimentation!)
node /^lvs101[345]\.eqiad\./ {
    role(insetup_noferm)
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

node /^mc10(3[7-9]|4[0-9]|5[0-4])\.eqiad\./ {
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
    role(insetup::serviceops_ferm)
}

node /^mc-misc200[1-2]\.codfw\./ {
    role(insetup::serviceops_ferm)
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

node /^ml-serve10(0[1-9]|1[0-3])\.eqiad\./ {
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
node /^moss-be1001\.eqiad\./ {
    role(cephadm::controller)
}

node /^moss-be100[23]\.eqiad\./ {
    role(cephadm::storage)
}

node /^apus-be100\d\.eqiad\./ {
    role(cephadm::storage)
}

# Controller for the codfw apus cephadm cluster
node /^moss-be2001\.codfw\./ {
    role(cephadm::controller)
}

node /^moss-be200[23]\.codfw\./ {
    role(cephadm::storage)
}

node /^apus-be200\d\.codfw\./ {
    role(cephadm::storage)
}

node /^moss-fe200[12]\.codfw\./ {
    role(cephadm::rgw)
}

node /^apus-fe200\d\.codfw\./ {
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
# pc4
node /^pc1014\.eqiad\./ {
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

# Future pc8 codfw host
node /^pc2018\.codfw\./ {
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

# pc4
node /^pc2014\.codfw\./ {
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
# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[12]004\.(eqiad|codfw)\./ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]003\.(eqiad|codfw)\./ {
    role(planet)
}

node /^planet[12]004\.(eqiad|codfw)\./ {
    role(insetup::collaboration_services_nftables)
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

node /^puppetserver100[123]\.eqiad\./ {
    role(puppetserver)
}

node /^puppetserver200[124]\.codfw\./ {
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
# T393121
node /^rdb201[12]\.codfw\./ {
    role(insetup::serviceops_ferm)
}

node /^registry[12]00[345]\.(eqiad|codfw)\./ {
    role(docker_registry)
}

# https://releases.wikimedia.org - VMs for releases files (mediawiki and other)
# https://releases-jenkins.wikimedia.org (automatic MediaWiki builds)
node /^releases[12]003\.(codfw|eqiad)\./ {
    role(releases)
}

# relevance forge servers (run opensearch, owned by DPE SRE)
node /^relforge10(08|09|10)\.eqiad\./ {
    role(cirrus::test)
}

# restbase eqiad cluster
node /^restbase10(3[1-9]|4[0-5])\.eqiad\./ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(2[4-9]|3[0-8])\.codfw\./ {
    role(restbase::production)
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
node /^parsoidtest1001\.eqiad\./ {
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

# Servers for SRE tests which are not suitable for Cloud VPS
node /^sretest100[2-6]\.eqiad\./ {
    role(sretest)
}

# Servers for SRE tests in codfw
node /^sretest20(0[1234569]|10)\.codfw\./ {
    role(sretest)
}

# generic TCP proxy (T408064) - first used for gerrit-ssh
node /^tcp-proxy[1-7]00[1-2]\.(codfw|drmrs|eqiad|eqsin|esams|magru|ulsfo)\./ {
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
node /^testreduce1002\.eqiad\./ {
    role(parsoid::testreduce)
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

# test VM for T396864
node /^testvm7001\.magru\./ {
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
node /^deploy(1003|2002)\.(eqiad|codfw)\./ {
    role(deployment_server::kubernetes)
}

node /^deploy2003\.codfw\./ {
    role(insetup::serviceops_ferm)
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
node /^cloudvirt10(4[0-9]|5[0-9]|6[0-9]|7[0-6])\.eqiad\./ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

node /^wcqs100[123]\.eqiad\./ {
    role(wcqs::public)
}

node /^wcqs200[123]\.codfw\./ {
    role(wcqs::public)
}

node /^wdqs101[1-9]\.eqiad\./ {
    role(wdqs::main)
}

node /^wdqs(20(07|08|10|11|12|13|14|15))\.codfw\./ {
    role(wdqs::main)
}

node /^wdqs2009\.codfw\./ {
    role(wdqs::public)
}

node /^wdqs102[0-2].eqiad\./ {
    role(wdqs::main)
}

node /^wdqs102[3-4].eqiad\./ {
    role(wdqs::scholarly)
}

node /^wdqs102[5-6].eqiad\./ {
    role(wdqs::internal_main)
}

node /^wdqs1027.eqiad\./ {
    role(wdqs::internal_scholarly)
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

node /^wdqs2016.codfw\./ {
    role(wdqs::scholarly)
}

node /^wdqs2017.codfw\./ {
    role(wdqs::internal_scholarly)
}

node /^wdqs20(1[8-9]|20).codfw\./ {
    role(wdqs::internal_main)
}

node /^wdqs202[6-7].codfw\./ {
    role(wdqs::internal_scholarly)
}

node /^wdqs10(2[8-9]|3[0-2]).eqiad\./ {
    role(wdqs::alternatives)
}

node /^wdqs10(3[3-5]).eqiad\./ {
    role(insetup::data_platform_ferm)
}

node /^wdqs-categories1001.eqiad\./ {
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

# zuul - trusted runners
node /^zuul([1-2]003)\.(codfw|eqiad)\./ {
    role(zuul::trusted_runner)
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
