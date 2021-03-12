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
node /^an-worker11(0[0-9]|1[0-9]|2[0-8]|3[0125678])\.eqiad\.wmnet$/ {
    role(analytics_cluster::hadoop::worker)
}

#staged an-workers via T260445
node /^an-worker11(29|33|34|39|40|41)\.eqiad\.wmnet$/ {
    role(insetup)
}

# hue.wikimedia.org
node 'analytics-tool1001.eqiad.wmnet' {
    role(analytics_cluster::hadoop::ui)
}

# Staging environment of Superset and Turnilo
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo
node 'an-tool1005.eqiad.wmnet' {
    role(analytics_cluster::ui::staging)
}

# turnilo.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot
node 'an-tool1007.eqiad.wmnet' {
    role(analytics_cluster::turnilo)
}

node 'an-tool1008.eqiad.wmnet' {
    role(analytics_cluster::hadoop::yarn)
}

node 'an-tool1009.eqiad.wmnet' {
    role(analytics_cluster::hadoop::ui)
}

node 'an-tool1010.eqiad.wmnet' {
    role(analytics_cluster::ui::dashboards)
}

# Analytics/Search instance of Apache Airflow
node 'an-airflow1001.eqiad.wmnet' {
    role(search::airflow)
}

# Analytics Zookepeer cluster
node /an-conf100[1-3]\.eqiad\.wmnet/ {
    role(analytics_cluster::zookeeper)
}


# Analytics Presto nodes.
node /^an-presto100[1-5]\.eqiad\.wmnet$/ {
    role(analytics_cluster::presto::server)
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
node /aqs101[01]\.eqiad\.wmnet/ {
    role(aqs_next)
}

# New AQS Nodes T267414
node /aqs101[2-5]\.eqiad\.wmnet/ {
    role(insetup)
}

# New Archiva host on Buster
# T254890
node 'archiva1002.wikimedia.org' {
    role(archiva)
}

node 'auth1002.eqiad.wmnet' {
    role(test)
}

node 'auth2001.codfw.wmnet' {
    role(test)
}

node /^authdns[12]001\.wikimedia\.org$/ {
    role(dns::auth)
}

# Primary bacula director and storage daemon
node 'backup1001.eqiad.wmnet' {
    role(backup)
}
# eqiad storage daemon and backup generation for ES databases
node 'backup1002.eqiad.wmnet' {
    role(dbbackups::content)
}

# eqiad new backup node T274184
node 'backup1003.eqiad.wmnet' {
    role(insetup)
}

# codfw storage daemon
node 'backup2001.codfw.wmnet' {
    role(backup::offsite)
}
# codfw storage daemon and backup generation for ES databases
node 'backup2002.codfw.wmnet' {
    role(dbbackups::content)
}

# codfw new backup node T274185
node 'backup2003.codfw.wmnet' {
    role(insetup)
}

# Bastion in Virginia
node 'bast1002.wikimedia.org' {
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

node 'centrallog1001.eqiad.wmnet', 'centrallog2001.codfw.wmnet' {
    role(syslog::centralserver)
}

# system for censorship monitoring scripts (T239250)
node 'cescout1001.eqiad.wmnet' {
    role(cescout)
}

node /^chartmuseum[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(chartmuseum)
}

node /^cloudgw200[12]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::cloudgw)
}

node /^cloudcephosd200[123]-dev\.codfw\.wmnet/ {
    role(wmcs::ceph::osd)
}

#T267378
node /^cloudcephmon200[1-3]-dev\.codfw\.wmnet$/ {
    role(wmcs::ceph::mon)
}

node /^cloudstore100[89]\.wikimedia\.org/ {
    role(wmcs::nfs::secondary)
}

# All gerrit servers (swap master status in hiera)
node 'gerrit1001.wikimedia.org', 'gerrit2001.wikimedia.org' {
    role(gerrit)
}

# Zookeeper and Etcd discovery service nodes in eqiad
node /^conf100[456]\.eqiad\.wmnet$/ {
    role(configcluster_stretch)
}

# Test zookeeper in eqiad
node 'zookeeper-test1002.eqiad.wmnet' {
    role(zookeeper::test)
}

# Test kafka cluster
node /^kafka-test10(10|0[6-9])\.eqiad\.wmnet/ {
    role(kafka::test::broker)
}

# Zookeeper and Etcd discovery service nodes in codfw
node /^conf200[123]\.codfw\.wmnet$/ {
    role(configcluster)
}

# CI master / CI standby (switch in Hiera)
node /^(contint1001|contint2001)\.wikimedia\.org$/ {
    role(ci::master)

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

node /^cp402[1-6]\.ulsfo\.wmnet$/ {
    role(cache::upload)
}

node /^cp40(2[789]|3[012])\.ulsfo\.wmnet$/ {
    role(cache::text)
}

#
# eqsin caches
#

node /^cp500[1-6]\.eqsin\.wmnet$/ {
    role(cache::upload)
}

node /^cp50(0[789]|1[012])\.eqsin\.wmnet$/ {
    role(cache::text)
}

node /^cumin[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(cluster::management)
}

node 'cuminunpriv1001.eqiad.wmnet' {
    role(cluster::unprivmanagement)
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1083.eqiad.wmnet' {
    role(mariadb::core)
}
# eqiad replicas
# See also db1099 and db1105 below
node /^db1(084|106|118|119|134|135|163|164|169)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2112.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2085 and db2088 below
node /^db2(071|072|092|103|116|130|145|146)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1122.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1105, db1146, db1170 below
node /^db1(074|076|129|162)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2107.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2088 and db2138 below
node /^db2(104|108|125|126|148)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on eqiad
# eqiad master
node 'db1123.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
node /^db1(112|157|166|175)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2105.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
node /^db2(074|109|127|149)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1138.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1144 and db1146 below
node /^db1(121|141|142|143|147|148|149|160)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s4-test hosts on eqiad
# temporarilly misc
node 'db1077.eqiad.wmnet' {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2090.codfw.wmnet' {
    role(mariadb::core)
}

# replacement codfw master T252985
node 'db2140.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2137 and db2138 below
node /^db2(073|106|110|119|136|147)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki and others) core production dbs on eqiad
# eqiad master
node 'db1100.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1096, db1113 and db1144 below
node /^db1(082|110|130)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki and others) core production dbs on codfw
# codfw master
node 'db2123.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2089 and db2137 below
node /^db2(075|111|113|128)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1131.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1096, db1098 and db1113 below
node /^db1(085|168|173)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on codfw
# codfw master
node 'db2129.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2087 and db2089 below
node /^db2(076|114|117|124)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1086.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1098, db1101, db1170 below
node /^db1(069|079|127|136|174)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2118.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2086 and db2087 below
node /^db2(077|120|121|122|150)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on eqiad
# eqiad master
node 'db1104.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# See also db1099 and db1101 below
node /^db1(087|109|111|114|126|172)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on codfw
# codfw master
node 'db2079.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
# See also db2085 and db2086 below
node /^db2(080|081|082|083|084|091|152)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# multi-instance hosts with multiple shards
node /^db1(096|098|099|101|105|113|144|146|170)\.eqiad\.wmnet/ {
    role(mariadb::core_multiinstance)
}
node /^db2(085|086|087|088|089|137|138)\.codfw\.wmnet/ {
    role(mariadb::core_multiinstance)
}

## x1 shard
# eqiad
# x1 eqiad master
node 'db1103.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1120.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1137.eqiad.wmnet' {
    role(mariadb::core)
}



# codfw
# x1 codfw master
node 'db2096.codfw.wmnet' {
    role(mariadb::core)
}

# x1 codfw slaves
node /^db2(115|131)\.codfw\.wmnet/ {
    role(mariadb::core)
}



# x2 shard
# eqiad
# x1 eqiad master
node 'db1151.eqiad.wmnet' {
    role(mariadb::core)
}

# x2 eqiad slaves
node /^db11(52|53)\.eqiad\.wmnet$/ {
    role(mariadb::core)
}

# codfw
# x2 codfw master
node 'db2142.codfw.wmnet' {
    role(mariadb::core)
}

# x2 codfw slaves
node /^db21(43|44)\.codfw\.wmnet$/ {
    role(mariadb::core)
}

## m1 shard
# See also multiinstance misc hosts db1117 and db2078 below

# m1 eqiad master
node 'db1080.eqiad.wmnet' {
    role(mariadb::misc)
}

# Future m1 eqiad master, will replace db1080
node 'db1159.eqiad.wmnet' {
    role(mariadb::misc)
}

# m1 codfw master
node 'db2132.codfw.wmnet' {
    role(mariadb::misc)
}

## m2 shard
# See also multiinstance misc hosts db1117 and db2078 below

# m2 eqiad master
node 'db1107.eqiad.wmnet' {
    role(mariadb::misc)
}

# m2 codfw master
node 'db2133.codfw.wmnet' {
    role(mariadb::misc)
}

## m3 shard
# See also multiinstance misc hosts db1117 and db2078 below

# m3 eqiad master
node 'db1132.eqiad.wmnet' {
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
# See also multiinstance misc hosts db1117 and db2078 below

# m5 eqiad master
node 'db1128.eqiad.wmnet' {
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
node 'db2078.codfw.wmnet' {
    role(mariadb::misc::multiinstance)
}

# sanitarium hosts
node /^db1(124|125|154|155)\.eqiad\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

node /^db2(094|095)\.codfw\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

# tendril db + zarcillo master
node 'db1115.eqiad.wmnet' {
    role(mariadb::misc::db_inventory)
}

# zarcillo slave / standby tendril host
# Active master for orchestrator DB
node 'db2093.codfw.wmnet' {
    role(mariadb::misc::db_inventory)
}

# Orchestrator central node (VM on ganeti)
node 'dborch1001.wikimedia.org' {
    role(orchestrator)
}



# eqiad backup sources
## x1, buster
node 'db1102.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s7 & s8, stretch
node 'db1116.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s1 & s6, stretch
node 'db1139.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s1 & s6, buster
node 'db1140.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s4 & s5, stretch
node 'db1145.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s4 & s5, buster
node 'db1150.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s2 & s3, stretch
node 'db1171.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

# codfw backup sources
## s1 & s6, stretch
node 'db2097.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s2 & s3, stretch
node 'db2098.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s4 & s5, stretch
node 'db2099.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s7 & s8, stretch
node 'db2100.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## x1, buster
node 'db2101.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s4 & s5, buster
node 'db2139.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
## s1 & s6, buster
node 'db2141.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}
# Codfw new database nodes T273568
node /^db21(51)\.codfw\.wmnet$/ {
    role(insetup)
}

# backup testing hosts
node 'db1133.eqiad.wmnet' {
    role(mariadb::core_test)
}

node 'db2102.codfw.wmnet' {
    role(mariadb::core_test)
}

# Analytics production replicas
node /^dbstore100(3|4|5)\.eqiad\.wmnet$/ {
    role(mariadb::dbstore_multiinstance)
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
node /^dbproxy20(01|02|03)\.codfw\.wmnet$/ {
    role(mariadb::proxy::master)
}


# labsdb proxies (controling replica service dbs)
# analytics proxy
node 'dbproxy1018.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}

# web proxy
node 'dbproxy1019.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}

# new dbproxy hosts to be productionized T223492
node /^dbproxy200[4]\.codfw\.wmnet$/ {
    role(insetup)
}

node 'dbmonitor1001.wikimedia.org' {
    role(tendril)
}

node /^debmonitor[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(debmonitor::server)
}

# Debian package/docker images building host in production (Buster)
node 'deneb.codfw.wmnet' {
    role(builder)
}

node /^dns[12345]00[12]\.wikimedia\.org$/ {
    role(dnsbox)
}

# production https://doc.wikimedia.org (T211974)
node 'doc1001.eqiad.wmnet' {
    role(doc)
}

# upcoming https://doc.wikimedia.org (T211974) on buster (T247653)
node 'doc1002.eqiad.wmnet', 'doc2001.codfw.wmnet' {
    role(doc)
}

# Druid analytics-eqiad (non public) servers.
# These power internal backends and queries.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[123]\.eqiad\.wmnet$/ {
    role(druid::analytics::worker)
}
node /^an-druid100[12]\.eqiad\.wmnet$/ {
    role(druid::analytics::worker)
}

# new an-druid nodes T274163
node /^an-druid100[345]\.eqiad\.wmnet$/ {
    role(insetup)
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

node /^elastic103[2-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}
node /^elastic10[4-5][0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic106[0-7]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic202[5-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic20[3-5][0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node 'elastic2060.codfw.wmnet' {
    role(elasticsearch::cirrus)
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
# master
node 'es1021.eqiad.wmnet' {
    role(mariadb::core)
}

# slaves
node 'es1020.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1022.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
# master
node 'es2021.codfw.wmnet' {
    role(mariadb::core)
}

node /^es202[02]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# External Storage, Shard 5 (es5) databases
## eqiad servers
# master
node 'es1024.eqiad.wmnet' {
    role(mariadb::core)
}

# slaves
node 'es1023.eqiad.wmnet' {
    role(mariadb::core)
}

node 'es1025.eqiad.wmnet' {
    role(mariadb::core)
}

## codfw servers
# master
node 'es2023.codfw.wmnet' {
    role(mariadb::core)
}

node /^es202[45]\.codfw\.wmnet/ {
    role(mariadb::core)
}

node /^failoid[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(failoid)
}

# New hosts to refresh db1074-db1095 T264584 T267043
# 9 expansion hosts T273566
# 2 hosts (db1154 and db1155) will be used to temporary test sanitarium upgrades to 10.4 T268742
# Set them to spare individually as it will take take to transfer the data
node /^db11(56|58|61|65|67|76|77|78|79|80|81|82|83|84)\.eqiad\.wmnet$/ {
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
node /^(acrab|acrux|argon|chlorine)\.(eqiad|codfw)\.wmnet$/ {
    role(kubernetes::master)
}

node /^kubemaster200[12]\.codfw\.wmnet$/ {
    role(kubernetes::master)
}

# New kubernetes masters
node /^kubemaster100[12]\.eqiad.wmnet$/ {
    role(insetup)
}

# new Kubernetes host T258747
node 'kubernetes1017.eqiad.wmnet' {
    role(insetup)
}

# Kubernetes for flink in k8s T258745
node 'kubernetes2017.codfw.wmnet' {
    role(kubernetes::worker)
}

# Etherpad on buster (virtual machine)
node 'etherpad1002.eqiad.wmnet' {
    role(etherpad)
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node 'eventlog1002.eqiad.wmnet' {
    role(eventlogging::analytics)
}

# virtual machine for mailman list server
node 'lists1001.wikimedia.org' {
    role(lists)
}

# Ganeti virtualization hosts - eqiad
node /^ganeti10(0[5-9]|1[0-9]|2[0-2])\.eqiad\.wmnet$/ {
    role(ganeti)
}
# Ganeti virtualization hosts - codfw
node /^ganeti20(0[7-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role(ganeti)
}

node /^ganeti300[123]\.esams\.wmnet$/ {
    role(ganeti)
}

node /^ganeti400[123]\.ulsfo\.wmnet$/ {
    role(ganeti)
}

node /^ganeti500[123]\.eqsin\.wmnet$/ {
    role(ganeti)
}

# T274459
node 'gitlab1001.wikimedia.org' {
    role(gitlab)
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

# irc.wikimedia.org
node 'kraz.wikimedia.org' {
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

node 'cloudweb2001-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::cloudweb)
}

node /^cloudnet200[23]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::net)
}

node 'clouddb2001-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::db)
}

node 'cloudcontrol2003-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
}

node 'cloudcontrol2004-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
}

node 'cloudservices2002-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::services)
}

node 'cloudservices2003-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::services)
}

node /labweb100[12]\.wikimedia\.org/ {
    role(wmcs::openstack::eqiad1::labweb)

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

node /^idp[12]001\.wikimedia\.org$/ {
    role(idp)
}

# IDP staging servers
node /^idp-test[12]001\.wikimedia\.org$/ {
    role(idp_test)
}

# TFTP/DHCP/webproxy but NOT APT repo (T224576)
node /^install[12]003\.wikimedia\.org$/ {
    role(installserver::light)
}

# new install servers in POPs (T254157, T252526, T242602)
node /^install[345]001\.wikimedia\.org$/ {
    role(installserver::light)
}

# new icinga systems, replaced einsteinium and tegmen (T201344, T208824)
node /^icinga[12]001\.wikimedia\.org$/ {
    role(alerting_host)
}

# new alert (icinga + alertmanager) systems, replacing icinga[12]001 (T255072, T255070)
node /^alert[12]001\.wikimedia\.org$/ {
    role(alerting_host)
}


# Phabricator
node /^(phab1001\.eqiad|phab2001\.codfw)\.wmnet$/ {
    role(phabricator)
}

# PKI server
node /^pki[12]001\.(eqiad|codfw)\.wmnet/ {
    role(pki)
}

# New kafka-logging hosts T273778
node /kafka-logging100[123]\.eqiad\.wmnet/ {
    role(insetup)
}

# New Codfw kafka-logging hosts T274905
node /^kafka-logging200[123]\.codfw\.wmnet/ {
    role(insetup)
}

node /kafka-main100[4-5]\.eqiad\.wmnet/ {
    role(insetup)
}

node /kafka-main100[123]\.eqiad\.wmnet/ {
    role(kafka::main)
}

node /kafka-main200[123]\.codfw\.wmnet/ {
    role(kafka::main)
}

node /kafka-main200[4-5]\.codfw\.wmnet/ {
    role(insetup)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo100[1-9]\.eqiad\.wmnet$/ {
    role(kafka::jumbo::broker)
}

# Kafka Burrow Consumer lag monitoring (T187901, T187805)
node /kafkamon[12]001\.(codfw|eqiad)\.wmnet/ {
    role(kafka::monitoring)
}

node /kafkamon[12]002\.(codfw|eqiad)\.wmnet/ {
    role(kafka::monitoring_buster)
}

# virtual machines for misc. applications and static sites
# replaced miscweb1001/2001 in T247648 and bromine/vega in T247650
#
# profile::wikimania_scholarships      # https://scholarships.wikimedia.org/
# profile::iegreview                   # https://iegreview.wikimedia.org
# profile::racktables                  # https://racktables.wikimedia.org
# profile::microsites::annualreport    # https://annual.wikimedia.org
# profile::microsites::static_bugzilla # https://static-bugzilla.wikimedia.org
# profile::microsites::static_rt       # https://static-rt.wikimedia.org
# profile::microsites::transparency    # https://transparency.wikimedia.org
# profile::microsites::research        # https://research.wikimedia.org (T183916)
# profile::microsites::design          # https://design.wikimedia.org (T185282)
# profile::microsites::sitemaps        # https://sitemaps.wikimedia.org
# profile::microsites::bienvenida      # https://bienvenida.wikimedia.org (T207816)
# profile::microsites::wikiworkshop    # https://wikiworkshop.org (T242374)
# profile::microsites::static_codereview # https://static-codereview.wikimedia.org (T243056)

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

node /kubernetes[12]0(0[1-9]|1[0-6])\.(codfw|eqiad)\.wmnet/ {
    role(kubernetes::worker)
}

node /kubestage100[12]\.eqiad\.wmnet/ {
    role(kubernetes::staging::worker)
}

# codfw new kubernetes staging nodes T252185
node /kubestage200[12]\.codfw\.wmnet/ {
    role(kubernetes::staging::worker)
}

node 'cloudcontrol2001-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
}

node /cloudvirt200[1-3]\-dev\.codfw\.wmnet/ {
    role(wmcs::openstack::codfw1dev::virt_ceph)
}

# WMCS Graphite and StatsD hosts
node /cloudmetrics100[1-2]\.eqiad\.wmnet/ {
    role(wmcs::monitoring)
}

node /^cloudcontrol100[3-5]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::control)
}

# ceph monitor nodes
node /^cloudcephmon100[1-3]\.eqiad\.wmnet$/ {
    role(wmcs::ceph::mon)
}

# ceph storage nodes
node /^cloudcephosd10(0[1-9]|1[0-5])\.eqiad\.wmnet$/ {
    role(wmcs::ceph::osd)
}

# New systems placed into service by cloud team via T194186 and T249062
node /^cloudelastic100[1-6]\.wikimedia\.org$/ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[3-4]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::net)
}

## wikireplicas dbs
node 'labsdb1009.eqiad.wmnet' {
    role(wmcs::db::wikireplicas::web)
}
node 'labsdb1010.eqiad.wmnet' {
    role(wmcs::db::wikireplicas::web)
}
node 'labsdb1011.eqiad.wmnet' {
    role(wmcs::db::wikireplicas::analytics)
}

# TODO remove this after decommissioning
node 'labsdb1012.eqiad.wmnet' {
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
    role(wmcs::nfs::primary_backup::misc)
}

# LDAP servers with a replica of OIT's user directory (used by mail servers)
node /^ldap-corp[1-2]001\.wikimedia\.org$/ {
    role(openldap::corp)
}

# Read-only ldap replicas in eqiad
node /^ldap-replica100[1-2]\.wikimedia\.org$/ {
    role(openldap::replica)
}

# Read-only ldap replicas in codfw
node /^ldap-replica200[3-4]\.wikimedia\.org$/ {
    role(openldap::replica)
}

node /^logstash101[0-2]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
    include ::role::kafka::logging # lint:ignore:wmf_styleguide
}

# ELK 7 ES only SSD backends (no kafka-logging brokers)
node /^logstash[12]02[6-9]\.(eqiad|codfw)\.wmnet$/ {
    role(logstash::elasticsearch7)
}

# ELK 7 ES only HDD backends (no kafka-logging brokers)
node /^logstash[12]02[0-2]\.(eqiad|codfw)\.wmnet$/ {
    role(logstash::elasticsearch7)
}

# ELK 7 logstash collectors (Ganeti)
node /^logstash[12]02[345]\.(eqiad|codfw)\.wmnet$/ {
    role(logstash7)
}
node /^logstash[12]03[01]\.(eqiad|codfw)\.wmnet$/ {
    role(logstash7)
}
node 'logstash1032.eqiad.wmnet' {
    role(kibana7_ecs)
}

# eqiad logstash collectors (Ganeti)
node /^logstash100[7-9]\.eqiad\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver
}

# eqiad new logstash nodes T267666
node /^logstash103[345]\.eqiad\.wmnet/ {
    role(insetup)
}

# codfw logstash kafka/elasticsearch
node /^logstash200[1-3]\.codfw\.wmnet$/ {
    role(logstash::elasticsearch)
    # Remove kafka::logging role after dedicated logging kafka hardware is online
    include ::role::kafka::logging # lint:ignore:wmf_styleguide
}

# codfw logstash collectors (Ganeti)
node /^logstash200[4-6]\.codfw\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver # lint:ignore:wmf_styleguide
}

#codfw new logstash nodes T267420
node /^logstash203[345]\.codfw\.wmnet/ {
    role(insetup)
}

node /lvs101[3456]\.eqiad\.wmnet/ {
    role(lvs::balancer)
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

node /^maps10(0[1-3]|0[5-8]|1[0])\.eqiad\.wmnet/ {
    role(maps::replica)
}

node 'maps1004.eqiad.wmnet' {
    role(maps::master)
}

# testing buster master - maps2.0 migration
node 'maps1009.eqiad.wmnet' {
    role(maps::master)
}

node /^maps20(0[1-3]|0[5-9]|10)\.codfw\.wmnet/ {
    role(maps::replica)
}

node 'maps2004.codfw.wmnet' {
    role(maps::master)
}

# Buster replacement for matomo1001 - T252740
node 'matomo1002.eqiad.wmnet' {
    role(piwik)
}

node /^mc10(19|2[0-3]|2[5-9]|3[0-6])\.eqiad\.wmnet/ {
    role(mediawiki::memcached)
}

node /^mc20(19|2[0-7]|29|3[0-7])\.codfw\.wmnet/ {
    role(mediawiki::memcached)
}

node /^mc-gp100[1-3]\.eqiad\.wmnet/ {
    role(mediawiki::memcached::gutter)
}

node /^mc-gp200[1-3]\.codfw\.wmnet/ {
    role(mediawiki::memcached::gutter)
}

node /^ml-serve200[1234]\.codfw\.wmnet/ {
    role(ml_serve)
}
node /^ml-serve100[1234]\.eqiad\.wmnet/ {
    role(ml_serve)
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

# RT, replaced ununpentium
node 'moscovium.eqiad.wmnet' {
    role(requesttracker)
}

node /^ms-backup100[12]\.eqiad\.wmnet/ {
    role(insetup)
}

node /^ms-backup200[12]\.codfw\.wmnet/ {
    role(insetup)
}

node /^ms-fe1005\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::swiftrepl # lint:ignore:wmf_styleguide
    include ::lvs::realserver
}

node /^ms-fe1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

# Newly provisioned ms-be hosts are safe to add to swift::storage at any time
node /^ms-be1\d\d\d\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe2005\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::swiftrepl # lint:ignore:wmf_styleguide
    include ::lvs::realserver
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

# Debug servers - 1,2 are on stretch, 3 is on buster
node /^mwdebug100[123]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# Appservers (serving normal website traffic)

# Row A

# rack A5
node /^mw126[1-5]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# rack A5
node /^mw1266\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A7
node /^mw12(69|7[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A8
node /^mw126[7-8]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A5
node /^mw13(8[579]|91)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row B

# rack B3 and B5
node /^mw1(39[3579]|40[13])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row C

# rack C3
node /^mw140[57]\.eqiad\.wmnet$/ {
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

# rack D8
node /^mw1383\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack D8
node /^mw1384\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# API (serving api traffic)

# Row A

# rack A7
node /^mw127[6-9]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
}

# rack A8
node /^mw128[1-3]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

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

# rack B6
node /^mw12(8[4-9]|9[07])\.eqiad\.wmnet$/ {
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

# rack B6
node /^mw1(29[345689]|30[0-6])\.eqiad\.wmnet$/ {
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

# rack A3 and rack A4
node /^mw22(2[4-9]|3[0-9]|4[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# rack A3
node /^mw2(29[1-9]|300)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack A6
node /^mw230[13579]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row B

# rack B3
node /^mw225[4-8]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

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
node /^mw23(5[13579]|6[135])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row C

# rack C3
node /^mw23(3[5-9])\.codfw\.wmnet$/ {
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

# API

# Row A

# rack A6
node /^mw230[2468]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# rack A4
node /^mw22(4[45])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
}

# rack A4
node /^mw22(5[1-3])\.codfw\.wmnet$/ {
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

# rack A4 - jobrunner canaries
node /^mw22(49|50)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# rack A4 - jobrunners
node /^mw22(4[3678])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

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

# rack D4
node /^mw22(7[8-9]|8[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
}

# New mwlog node T267271
node 'mwlog1002.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
}

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(logging::mediawiki::udp2log)
}

# New mwlog node T267272
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

node /^netbox(1001|2001)\.wikimedia\.org$/ {
    role(netbox::frontend)
}

node /^netboxdb(1001|2001)\.(eqiad|codfw)\.wmnet$/ {
    role(netbox::database)
}

node /^netbox-dev2001\.wikimedia\.org$/ {
    role(netbox::standalone)
}

# network monitoring tools, stretch (T125020, T166180)
node /^netmon(1002|2001)\.wikimedia\.org$/ {
    role(netmon)
}

# Network insights (netflow/pmacct, etc.)
node /^netflow[1-5]001\.(eqiad|codfw|ulsfo|esams|eqsin)\.wmnet$/ {
    role(netinsights)
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
}

node /orespoolcounter[12]00[34]\.(codfw|eqiad)\.wmnet/ {
    role(orespoolcounter)
}

node 'otrs1001.eqiad.wmnet' {
    role(otrs)
}

# Wikidough, experimental (T252132)
node 'malmok.wikimedia.org' {
    role(wikidough)
}

# new parsoid nodes - codfw (T243112, T247441)
node /^parse20(0[1-9]|1[0-9]|20)\.codfw\.wmnet$/ {
    role(parsoid)
}

# parser cache databases
# eqiad
# pc1
node /^pc10(07|10)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
}
# pc2
node /^pc10(08)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
}
# pc3
node /^pc10(09)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
}

# codfw
# pc1
node /^pc20(07|10)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
}
# pc2
node /^pc20(08)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
}
# pc3
node /^pc20(09)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[123]001\.(eqiad|codfw|esams)\.wmnet$/ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(planet)
}

node /poolcounter[12]00[345]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
}

node /^prometheus200[34]\.codfw\.wmnet$/ {
    role(prometheus)
}

node /^prometheus100[34]\.eqiad\.wmnet$/ {
    role(prometheus)
}

node /^prometheus[345]001\.(esams|ulsfo|eqsin)\.wmnet$/ {
    role(prometheus::pop)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]00[23]\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
}

node /^puppetboard[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard)
}

node /^puppetboard[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(insetup)
}

node /^puppetdb[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
}

# New rdb servers T206450
node /^rdb100[59]\.eqiad\.wmnet$/ {
    role(redis::misc::master)
}

node /^(rdb1006|rdb1010)\.eqiad\.wmnet$/ {
    role(redis::misc::slave)
}

node /^(rdb1011|rdb1012)\.eqiad\.wmnet$/ {
    role(insetup)
}

node /^rdb200[35]\.codfw\.wmnet$/ {
    role(redis::misc::master)
}
node /^rdb200[46]\.codfw\.wmnet$/ {
    role(redis::misc::slave)
}

# New rdb node T251626
node /^rdb200[78]\.codfw\.wmnet$/ {
    role(insetup)
}

node /^(rdb2009|rdb2010)\.codfw\.wmnet$/ {
    role(insetup)
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

# restbase eqiad cluster
node /^restbase10(1[6-9]|2[0-9]|30)\.eqiad\.wmnet$/ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(09|1[0-9]|2[0-3])\.codfw\.wmnet$/ {
    role(restbase::production)
}

# cassandra/restbase dev cluster
node /^restbase-dev100[4-6]\.eqiad\.wmnet$/ {
    role(restbase::dev_cluster)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(rpkivalidator)
}

# T252210
node 'peek2001.codfw.wmnet' {
    role(peek)
}

# people.wikimedia.org, for all shell users
# buster VMs. replaced people1001 (T247649)
node 'people1002.eqiad.wmnet', 'people2001.codfw.wmnet' {
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

# Services 'B'
node /^scb[12]00[123456]\.(eqiad|codfw)\.wmnet$/ {
    role(scb)

}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::labs)
}

node 'sodium.wikimedia.org' {
    role(mirrors)
}

node 'thorium.eqiad.wmnet' {
    # thorium is used to host public Analytics websites like:
    # - https://stats.wikimedia.org (Wikistats)
    # - https://analytics.wikimedia.org (Analytics dashboards and datasets)
    # - https://datasets.wikimedia.org (deprecated, redirects to analytics.wm.org/datasets/archive)
    #
    # For a complete and up to date list please check the
    # related role/module.
    #
    # This node is not intended for data processing.
    role(analytics_cluster::webserver)
}

# The hosts contain all the tools and libraries to access
# the Analytics Cluster services.
node /^stat100[4-8]\.eqiad\.wmnet/ {
    role(statistics::explorer)
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
node /^snapshot100[679]\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper)
}
node /^snapshot1005\.eqiad\.wmnet/ {
    role(dumps::generation::worker::testbed)
}
node /^snapshot1008\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_misc_crons_only)
}
node /^snapshot1010\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_monitor)
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
node /^thumbor100[1234]\.eqiad\.wmnet/ {
    role(thumbor::mediawiki)
}

node /^thumbor200[1234]\.codfw\.wmnet/ {
    role(thumbor::mediawiki)
}

# deployment servers
node /^deploy[12]002\.(eqiad|codfw)\.wmnet$/ {
    role(deployment_server)
}

# new url-downloaders (T224551)
# https://wikitech.wikimedia.org/wiki/Url-downloader
node /^urldownloader[12]00[12]\.wikimedia\.org/ {
    role(url_downloader)
}

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
node /^cloudvirt102[1-8]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph_and_backy)
}

node 'cloudvirt1029.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

node /^cloudvirt103[0-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

node /^cloudvirt101[2-8]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt_ceph)
}

# Private virt hosts for wdqs T221631
node /^cloudvirt-wdqs100[123]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
}

# Wikidata query service
node /^wdqs100[4-7]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}

# T260083 brought wdqs101[1-3] into service with [2,3] public and [1] private
node /^wdqs101[2-3]\.eqiad\.wmnet$/ {
    role(wdqs::public)
}

node /^wdqs200[1237]\.codfw\.wmnet$/ {
    role(wdqs::public)
}

# Wikidata query service internal
node /^wdqs100[38]\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs1011\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs200[4568]\.codfw\.wmnet$/ {
    role(wdqs::internal)
}

# Wikidata query service test
node /^wdqs10(09|10)\.eqiad\.wmnet$/ {
    role(wdqs::test)
}

# VMs for performance team replacing hafnium (T179036)
node /^webperf[12]001\.(codfw|eqiad)\.wmnet/ {
    role(webperf::processors_and_site)
}

# VMs for performance team profiling tools (T194390)
node /^webperf[12]002\.(codfw|eqiad)\.wmnet/ {
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
