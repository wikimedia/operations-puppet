# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp
# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if !defined('$cluster') {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

# to be decommisioned - replaced by dns2001 (T198286)
node 'acamar.wikimedia.org' {
    role(spare::system)
}

# to be decommisioned - replaced by dns2002 (T198286)
node 'achernar.wikimedia.org' {
    role(spare::system)
}

# Ganeti VMs for acme-chief service
node 'acmechief1001.eqiad.wmnet' {
    role(acme_chief)
    interface::add_ip6_mapped { 'main': }
}

node 'acmechief2001.codfw.wmnet' {
    role(acme_chief)
    interface::add_ip6_mapped { 'main': }
}

# Ganeti VMs for acme-chief staging environment
node 'acmechief-test1001.eqiad.wmnet' {
    role(spare::system)
}

node 'acmechief-test2001.codfw.wmnet' {
    role(spare::system)
}

# url-downloaders
node /^(actinium|alcyone|alsafi|aluminium)\.wikimedia\.org$/ {
    role(url_downloader)
    interface::add_ip6_mapped { 'main': }
}

# The Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'an-master1001.eqiad.wmnet' {
    role(analytics_cluster::hadoop::master)
    interface::add_ip6_mapped { 'main': }
}

# The Hadoop (stanby) master node:
# - primary active NameNode
# - YARN ResourceManager
node 'an-master1002.eqiad.wmnet' {
    role(analytics_cluster::hadoop::standby)
    interface::add_ip6_mapped { 'main': }
}

node 'an-coord1001.eqiad.wmnet' {
    role(analytics_cluster::coordinator)
    interface::add_ip6_mapped { 'main': }
}

# analytics1028-analytics1040 are Hadoop worker nodes.
# These hosts are OOW but they are used as temporary
# Hadoop testing cluster for T211836.
#
# Hadoop Test cluster's master
node 'analytics1028.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::master)
    interface::add_ip6_mapped { 'main': }
}

# Hadoop Test cluster's standby master
node 'analytics1029.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::standby)
    interface::add_ip6_mapped { 'main': }
}

# Hadoop Test cluster's coordinator
node 'analytics1030.eqiad.wmnet' {
    role(analytics_test_cluster::coordinator)
    interface::add_ip6_mapped { 'main': }
}

# Hadoop Test cluster's workers
node /analytics10(3[1-8]|40).eqiad.wmnet/ {
    role(analytics_test_cluster::hadoop::worker)
    interface::add_ip6_mapped { 'main': }
}

# Hadoop Test cluster's UIs
node 'analytics1039.eqiad.wmnet' {
    role(analytics_test_cluster::hadoop::ui)
    interface::add_ip6_mapped { 'main': }
}

# Druid Analytics Test cluster
node 'analytics1041.eqiad.wmnet' {
    role(druid::test_analytics::worker)
    interface::add_ip6_mapped { 'main': }
}

# analytics1042-analytics1077 are Analytics Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# hieradata/common.yaml hadoop_clusters net_topology
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(4[2-9]|5[0-9]|6[0-9]|7[0-7]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)
    interface::add_ip6_mapped { 'main': }
}

# an-worker1078-1095 are new Hadoop worker nodes.
# T207192
node /an-worker10(7[89]|8[0-9]|9[0-5]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)
    interface::add_ip6_mapped { 'main': }
}

# hue.wikimedia.org, yarn.wikimedia.org
node 'analytics-tool1001.eqiad.wmnet' {
    role(analytics_cluster::hadoop::ui)
    interface::add_ip6_mapped { 'main': }
}

# turnilo.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot
node 'analytics-tool1002.eqiad.wmnet' {
    role(analytics_cluster::turnilo)
    interface::add_ip6_mapped { 'main': }
}

# superset.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
node 'analytics-tool1003.eqiad.wmnet' {
    role(analytics_cluster::superset)
    interface::add_ip6_mapped { 'main': }
}

# Future replacement of superset.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# T212243
node 'analytics-tool1004.eqiad.wmnet' {
    role(analytics_cluster::superset)
    interface::add_ip6_mapped { 'main': }
}

# Future staging environment of superset.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# T212243
node 'an-tool1005.eqiad.wmnet' {
    role(spare::system)
    interface::add_ip6_mapped { 'main': }
}

# Analytics Query Service
node /aqs100[456789]\.eqiad\.wmnet/ {
    role(aqs)
    interface::add_ip6_mapped { 'main': }
}

# New Archiva host (replacement of meitnerium).
# T192639
node 'archiva1001.wikimedia.org' {
    role(archiva)
    interface::add_ip6_mapped { 'main': }
}

node 'auth1001.eqiad.wmnet' {
    role('yubiauth_server')
}

node 'auth1002.eqiad.wmnet' {
    role('yubiauth_server')
}

node 'auth2001.codfw.wmnet' {
    role('yubiauth_server')
}

node /^authdns[12]001\.wikimedia\.org$/ {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

# Bastion in Virginia
node 'bast1002.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

# Bastion in Texas
node 'bast2001.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

# new Bastion in Texas - to be setup (T196665)
node 'bast2002.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

# Bastion in the Netherlands (replaced bast3001)
node 'bast3002.wikimedia.org' {
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

# Bastion in California
node 'bast4001.wikimedia.org' {
    role(spare::system)
}

node 'bast4002.wikimedia.org' {
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

node 'bast5001.wikimedia.org' {
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

# VM with webserver for misc. static sites
node 'bromine.eqiad.wmnet', 'vega.codfw.wmnet' {
    role(webserver_misc_static)
    interface::add_ip6_mapped { 'main': }
}

# Replacement to Lithium T195416
node 'centrallog1001.eqiad.wmnet' {
    role(syslog::centralserver)
}

node 'cloudstore1008.wikimedia.org' {
    role(wmcs::nfs::misc)
}

node 'cloudstore1009.wikimedia.org' {
    role(wmcs::nfs::misc_backup)
}

# All gerrit servers (swap master status in hiera)
node 'cobalt.wikimedia.org', 'gerrit2001.wikimedia.org' {
    role(gerrit)

    interface::add_ip6_mapped { 'main': }
}

# Zookeeper and Etcd discovery service nodes in eqiad
node /^conf100[456]\.eqiad\.wmnet$/ {
    role(configcluster_stretch)
    interface::add_ip6_mapped { 'main': }
}

# Zookeeper and Etcd discovery service nodes in codfw
node /^conf200[123]\.codfw\.wmnet$/ {
    role(configcluster)
}

# CI master / CI standby (switch in Hiera)
node /^(contint1001|contint2001)\.wikimedia\.org$/ {
    role(ci::master)

    interface::add_ip6_mapped { 'main': }
}

# Debian package/docker images building host in production
node /^boron\.eqiad\.wmnet$/ {
    role(builder)
}

# cp1008: prod-like SSL test host
# to be replaced with cp1099 in the near future
node 'cp1008.wikimedia.org' {
    role(cache::canary)
    include ::role::authdns::testns
    interface::add_ip6_mapped { 'main': }
}

# ATS Test Cluster
node /^cp107[1-4]\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(trafficserver::backend)
}

# new canary, to replace cp1008 in future work
node /^cp1099\.eqiad\.wmnet$/ {
    role(test)
    include ::role::authdns::testns
    interface::add_ip6_mapped { 'main': }
}

node /^cp10(7[579]|8[13579])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp10(7[68]|8[02468]|90)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

node /^cp20(0[1467]|1[02369]|23)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp20(0[258]|1[1478]|2[02456])\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

# ATS Test Cluster
node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(trafficserver::backend)
}

# ex cp-misc_esams
node /^cp30(0[78]|10)\.esams\.wmnet$/ {
    role(spare::system)
}

node 'cp3022.esams.wmnet' {
    include ::standard
}

node /^cp30(3[0123]|4[012])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp30(3[4-9]|4[345679])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

#
# ulsfo varnishes
#

node /^cp402[1-6]\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

node /^cp40(2[789]|3[012])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

#
# eqsin varnishes
#

node /^cp500[1-6]\.eqsin\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

node /^cp50(0[789]|1[012])\.eqsin\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cumin[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(cluster::management)
    interface::add_ip6_mapped { 'main': }
}

node 'darmstadtium.eqiad.wmnet' {
    role(docker::registry)
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1067.eqiad.wmnet' {
    role(mariadb::core)
}
# eqiad replicas
node /^db1(080|083|089|106|118|119)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2048.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
node /^db20(55|62|70|71|72|92)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1066.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# see also db1090, db1103, db1105 bellow
node /^db1(074|076|122)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2035.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(41|49|56|63)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1078.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db1(075|077|123)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2043.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(36|50|57|74)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1068.eqiad.wmnet' {
    role(mariadb::core)
}

# see also db1097 and db1103 below
node /^db1(081|084|091|121)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s4-test hosts on eqiad
node /^db1(111|112)\.eqiad\.wmnet/ {
    role(mariadb::core_test)
}

# temporary test
node 'db1114.eqiad.wmnet' {
    role(mariadb::core_test)
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2051.codfw.wmnet' {
    role(mariadb::core)
}

# see also db2084 and db2091 below
node /^db20(58|65|73|90)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki and others) core production dbs on eqiad
# eqiad master
node 'db1070.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1096 db1097 and db1113 below
node /^db1(082|100|110)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki and others) core production dbs on codfw
# codfw master
node 'db2052.codfw.wmnet' {
    role(mariadb::core)
}

# See also db2084 and db2089 below
node /^db20(38|59|66|75)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1061.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1096 db1098 and db1113 below
node /^db10(85|88|93)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on codfw
# codfw master
node 'db2039.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(46|53|60|67|76)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1062.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1090, db1098 and db1101 bellow
node /^db10(69|79|86|94)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

#
# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2047.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(40|54|61|68|77)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on eqiad
# eqiad master
node 'db1071.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1099 and db1101 below
node /^db1(104|092|087|109)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on codfw
# codfw master
node 'db2045.codfw.wmnet' {
    role(mariadb::core)
}

# See also db2085 and db2086 below
node /^db20(79|80|81|82|83)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# hosts with multiple shards
node /^db1(090|096|097|098|099|101|103|105|113)\.eqiad\.wmnet/ {
    role(mariadb::core_multiinstance)
}
node /^db20(84|85|86|87|88|89|91)\.codfw\.wmnet/ {
    role(mariadb::core_multiinstance)
}

# Spare eqiad hosts to be provisioned #T211613 and #T218985
node /^db11(26|27|28|29|30|31|32|33|34|35|36|37|38|39|40)\.eqiad\.wmnet/ {
    role(spare::system)
}

# Spare codfw hosts to be provisioned #T219463 and #T219461
node /^db2(097|098|099|100|101|102)\.codfw\.wmnet/ {
    role(spare::system)
}

## x1 shard
# eqiad
# x1 eqiad master
node 'db1069.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1064.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1120.eqiad.wmnet' {
    role(mariadb::core)
}


# codfw
# x1 codfw master
node 'db2034.codfw.wmnet' {
    role(mariadb::core)
}

# x1 codfw slaves
node /^db20(69|96)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# Ready for decommission T219493
node 'db2033.codfw.wmnet' {
    role(spare::system)
}


## m1 shard

# See also multiinstance misc hosts db1117 and db2078 below
node 'db1063.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
}

## m2 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1065.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm2',
        master => true,
    }
}

node 'db2044.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm2',
    }
}

## m3 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1072.eqiad.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        master => true,
    }
}

# codfw
node 'db2042.codfw.wmnet' {
    role(mariadb::misc::phabricator)
}

## m4 shard

node 'db1107.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::master)
}

# These replicas have an m4 custom replication protocol.

node 'db1108.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::replica)
}

## m5 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1073.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm5',
        master => true,
    }
}

node 'db2037.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm5',
    }
}

# misc multiinstance
node 'db1117.eqiad.wmnet' {
    role(mariadb::misc::multiinstance)
}
node 'db2078.codfw.wmnet' {
    role(mariadb::misc::multiinstance)
}

# sanitarium hosts
node /^db1(124|125)\.eqiad\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

node /^db2(094|095)\.codfw\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
}

# tendril db
node 'db1115.eqiad.wmnet' {
    role(mariadb::misc::tendril_and_zarcillo)
}

# Standby tendril host
node 'db2093.codfw.wmnet' {
    role(mariadb::misc::tendril)
}

# eqiad backup sources
node 'db1095.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

node 'db1102.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

node 'db1116.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

node 'dbstore1001.eqiad.wmnet' {
    role(mariadb::backups_and_dbstore_multiinstance)
}

#dbstore100[345] are new via T209620
node /^dbstore100(3|4|5)\.eqiad\.wmnet$/ {
    role(mariadb::dbstore_multiinstance)
}

node 'dbstore2001.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

node 'dbstore2002.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

# database-provisioning and short-term/postprocessing backups servers
# Pending full setup
node 'dbprov2001.codfw.wmnet' {
    role(mariadb::backups)
}
node 'dbprov2002.codfw.wmnet' {
    role(mariadb::backups)
}

# Proxies for misc databases
node /^dbproxy10(01|02|03|04|05|06|07|08|09)\.eqiad\.wmnet$/ {
    role(mariadb::proxy::master)
}

# labsdb proxies (controling replica service dbs)
# analytics proxy
node 'dbproxy1010.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}
# web proxy
node 'dbproxy1011.eqiad.wmnet' {
    role(mariadb::proxy::master)
}

# new dbproxy hosts to be pressed into service by DBA team T196690
node /^dbproxy101[2-7]\.eqiad\.wmnet$/ {
    role(spare::system)
}

node /^dbmonitor[12]001\.wikimedia\.org$/ {
    role(tendril)
}

node /^debmonitor[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(debmonitor::server)
}

node /^dns100[12]\.wikimedia\.org$/ {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node /^dns200[12]\.wikimedia\.org$/ {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node /^dns400[12]\.wikimedia\.org$/ {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node /^dns500[12]\.wikimedia\.org$/ {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

# https://doc.wikimedia.org (T211974)
node 'doc1001.eqiad.wmnet' {
    role(doc)
    interface::add_ip6_mapped { 'main': }
}

# Druid analytics-eqiad (non public) servers.
# These power internal backends and queries.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[123].eqiad.wmnet$/ {
    role(druid::analytics::worker)
    interface::add_ip6_mapped { 'main': }
}

# Druid public-eqiad servers.
# These power AQS and wikistats 2.0 and contain non sensitive datasets.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[456].eqiad.wmnet$/ {
    role(druid::public::worker)
    interface::add_ip6_mapped { 'main': }
}

# nfs server for dumps generation, also rsyncs
# data to fallback nfs server(s)
node /^dumpsdata1001.eqiad.wmnet$/ {
    role(dumps::generation::server::primary)
}

# fallback nfs server for dumps generation, also
# will rsync data to web servers
node /^dumpsdata1002.eqiad.wmnet$/ {
    role(dumps::generation::server::fallback)
}

# misc. test server, keep (T156208)
node 'eeden.wikimedia.org' {
    role(test)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic101[7-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic102[023456789]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic10[3-4][0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic105[0-2]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic202[5-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic20[3-4][0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic205[0-4]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
}

node 'elnath.codfw.wmnet' {
    role(spare::system)
}

# External Storage, Shard 1 (es1) databases

## eqiad servers
node /^es101[268]\.eqiad\.wmnet/ {
    role(mariadb::core)
}

## codfw servers
node /^es201[123]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# External Storage, Shard 2 (es2) databases

## eqiad servers
node 'es1015.eqiad.wmnet' {
    role(mariadb::core)
}

node /^es101[13]\.eqiad\.wmnet/ {
    role(mariadb::core)
}

## codfw servers
node 'es2016.codfw.wmnet' {
    role(mariadb::core)
}

node /^es201[45]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# External Storage, Shard 3 (es3) databases

## eqiad servers
node 'es1017.eqiad.wmnet' {
    role(mariadb::core)
}

node /^es101[49]\.eqiad\.wmnet/ {
    role(mariadb::core)
}

## codfw servers
node 'es2017.codfw.wmnet' {
    role(mariadb::core)
}

node /^es201[89]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# Disaster recovery hosts for external storage
# These nodes are in process of being decommissioned

node /^es200[1-4]\.codfw\.wmnet/ {
    role(mariadb::temporary_storage)
}

# Backup system, see T176505.
# This is a reserved system. Ask Otto or Faidon.
node 'flerovium.eqiad.wmnet' {
    role(analytics_cluster::hadoop::client)

    include ::standard
}

# Backup system, see T176506.
# This is a reserved system. Ask Otto or Faidon.
node 'furud.codfw.wmnet' {
    role(analytics_cluster::hadoop::client)

    include ::standard
}

# Test Ganeti instance aimed to iron out all
# the details related to a Kerberos service for
# the Hadoop test cluster. This instance has a
# generic name and it might be confusing, but its
# sole purpose is to reach a point in which we know
# what hardware to get etc..
# More details: T211836
node 'kerberos1001.eqiad.wmnet' {
    role(spare::system)
}

# Etcd cluster for kubernetes
# TODO: Rename the eqiad etcds to the codfw etcds naming scheme
node /^(kub)?etcd[12]00[123]\.(eqiad|codfw)\.wmnet$/ {
    role(etcd::kubernetes)
}

# Etcd cluster for kubernetes staging
node /^kubestagetcd100[123]\.eqiad\.wmnet$/ {
    role(kubernetes::staging::etcd)
    interface::add_ip6_mapped { 'main': }
}

# kubernetes masters
node /^(acrab|acrux|argon|chlorine)\.(eqiad|codfw)\.wmnet$/ {
    role(kubernetes::master)
    interface::add_ip6_mapped { 'main': }
}

# kubernetes staging master
node 'neon.eqiad.wmnet' {
    role(kubernetes::staging::master)
    interface::add_ip6_mapped { 'main': }
}

# Etcd cluster for "virtual" networking
node /^etcd100[456]\.eqiad\.wmnet$/ {
    role(etcd::networking)
}

# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    role(etherpad)
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node 'eventlog1002.eqiad.wmnet' {
    role(eventlogging::analytics)
    interface::add_ip6_mapped { 'main': }
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role(lists)
    interface::add_ip6_mapped { 'main': }
}

# HTML dumps from Restbase
node 'francium.eqiad.wmnet' {
    role(dumps::web::htmldumps)
}

# Virtualization hosts
node /^ganeti[12]00[0-9]\.(codfw|eqiad)\.wmnet$/ {
    role(ganeti)
}

# Virtual machine being turned up to run Grafana (T210416)
node 'grafana1001.eqiad.wmnet' {
    role(grafana)
}

# debug_proxy hosts; Varnish backend for X-Wikimedia-Debug reqs
node /^(hassaleh|hassium)\.(codfw|eqiad)\.wmnet$/ {
    role(debug_proxy)
}

node 'helium.eqiad.wmnet' {
    role(backup)
    interface::add_ip6_mapped { 'main': }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    role(backup::offsite)
}

# irc.wikimedia.org
node 'kraz.wikimedia.org' {
    role(mw_rc_irc)
    interface::add_ip6_mapped { 'main': }
}


node 'labpuppetmaster1001.wikimedia.org' {
    role(wmcs::openstack::eqiad1::puppetmaster::frontend)
    interface::add_ip6_mapped { 'main': }
}

node 'labpuppetmaster1002.wikimedia.org' {
    role(wmcs::openstack::eqiad1::puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

# labservices1001 hosts openstack-designate
# and the powerdns auth and recursive services for instances.
node 'labservices1001.wikimedia.org' {
    role(wmcs::openstack::main::services_primary)
    interface::add_ip6_mapped { 'main': }
}

node 'labservices1002.wikimedia.org' {
    role(wmcs::openstack::main::services_secondary)
    interface::add_ip6_mapped { 'main': }
}

# cloudservices1003/1004 hosts openstack-designate
# and the powerdns auth and recursive services for instances in eqiad1.
node 'cloudservices1003.wikimedia.org' {
    role(wmcs::openstack::eqiad1::services_primary)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudservices1004.wikimedia.org' {
    role(wmcs::openstack::eqiad1::services_secondary)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudnet2001-dev.codfw.wmnet' {
    role(spare::system)
}

node 'cloudnet2002-dev.codfw.wmnet' {
    role(wmcs::openstack::labtestn::net)
}

node 'cloudnet2003-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::net)
}

node /^labtestvirt2003\.codfw\.wmnet$/ {
    role(wmcs::openstack::labtestn::virt)
}

node 'clouddb2001-dev.codfw.wmnet' {
    role(spare::system)
}

node 'labtestnet2002.codfw.wmnet' {
    role(spare::system)
}

node 'labtestcontrol2001.wikimedia.org' {
    role(wmcs::openstack::labtest::control)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestcontrol2003.wikimedia.org' {
    role(wmcs::openstack::labtestn::control)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestpuppetmaster2001.wikimedia.org' {
    role(wmcs::openstack::labtest::puppetmaster::frontend)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestservices2001.wikimedia.org' {
    role(wmcs::openstack::labtest::services)
    include ::role::openldap::labtest
    interface::add_ip6_mapped { 'main': }
}

node 'cloudservices2002-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::services)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestservices2003.wikimedia.org' {
    role(spare::system)
    interface::add_ip6_mapped { 'main': }
}

node /labweb100[12]\.wikimedia\.org/ {
    role(wmcs::openstack::eqiad1::labweb)

    interface::add_ip6_mapped { 'main': }
}

node /^graphite200[12]\.codfw\.wmnet/ {
    role(spare::system)
}

# Primary graphite host
node 'graphite1004.eqiad.wmnet' {
    role(graphite::production)
    # TODO: move the roles below to ::role::alerting::host
    include ::role::graphite::alerts
    include ::role::restbase::alerts
    include ::role::graphite::alerts::reqstats
    include ::role::elasticsearch::alerts
}

# Standby graphite host
node 'graphite2003.codfw.wmnet' {
    role(graphite::production)
}

# replaced carbon and install1001/install2001 (T132757, T84380, T156440)
node /^install[12]002\.wikimedia\.org$/ {
    role(installserver)
}

# new icinga systems, replaced einsteinium and tegmen (T201344, T208824)
node /^icinga[12]001\.wikimedia.org$/ {
    role(alerting_host)
    interface::add_ip6_mapped { 'main': }
}

# Phabricator
node /^(phab1001\.eqiad|phab2001\.codfw)\.wmnet$/ {
    role(phabricator)
    interface::add_ip6_mapped { 'main': }
}

# temp replacement for phab1001 during upgrade (T196019)
node 'phab1002.eqiad.wmnet' {
    role(phabricator)
    # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': }
    # lint:endignore
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Experimental Yubico two factor authentication bastion',
    }
    interface::add_ip6_mapped { 'main': }
    role(bastionhost::twofa)
}

# Analytics Kafka Brokers
node /kafka10(12|13|14|20|22|23)\.eqiad\.wmnet/ {
    role(kafka::analytics)
    interface::add_ip6_mapped { 'main': }
}

# Kafka Brokers - main-eqiad and main-codfw Kafka clusters.
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka[12]00[123]\.(eqiad|codfw)\.wmnet/ {
    role(kafka::main)
    interface::add_ip6_mapped { 'main': }
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo100[1-6]\.eqiad\.wmnet$/ {
    role(kafka::jumbo::broker)
    interface::add_ip6_mapped { 'main': }
}


# Kafka Burrow Consumer lag monitoring (T187901, T187805)
node /kafkamon[12]001\.(codfw|eqiad)\.wmnet/ {
    role(kafka::monitoring)
    interface::add_ip6_mapped { 'main': }
}

# virtual machine for misc. applications
# (as opposed to static sites using 'webserver_misc_static')
#
# profile::wikimania_scholarships - https://scholarships.wikimedia.org/
# profile::iegreview              - https://iegreview.wikimedia.org
# profile::grafana::production    - https://grafana.wikimedia.org
# profile::racktables             - https://racktables.wikimedia.org
node 'krypton.eqiad.wmnet' {
    role(webserver_misc_apps)
}

node /kubernetes[12]00[1-4]\.(codfw|eqiad)\.wmnet/ {
    role(kubernetes::worker)
    include ::standard

    interface::add_ip6_mapped { 'main': }
}

node /kubestage100[12]\.eqiad\.wmnet/ {
    role(kubernetes::staging::worker)
    include ::standard

    interface::add_ip6_mapped { 'main': }
}

node 'labcontrol1001.wikimedia.org' {
    role(wmcs::openstack::main::control)
    interface::add_ip6_mapped { 'main': }
}

# labcontrol1002 is a hot spare for 1001.
#  Switching it on involves changing the values in hiera
#  that trigger 1002 to start designate.
#  Changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    role(wmcs::openstack::main::control)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudcontrol2001-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
    interface::add_ip6_mapped { 'main': }
}

node /cloudvirt200[1-3]-dev\.codfw\.wmnet/ {
    role(wmcs::openstack::labtestn::virt)
}

# This is the labtest server that implements wikitech, horizon, and striker.
node 'labtestweb2001.wikimedia.org' {
    role(wmcs::openstack::labtest::labweb)

    include ::role::mariadb::labtestwikitech

    interface::add_ip6_mapped { 'main': }
}


# WMCS Graphite and StatsD hosts
node /labmon100[12]\.eqiad\.wmnet/ {
    role(wmcs::monitoring)
    interface::add_ip6_mapped { 'main': }
}

node 'labnet1001.eqiad.wmnet' {
    role(wmcs::openstack::main::net)
}

node /^cloudcontrol100[3-4].wikimedia.org$/ {
    role(wmcs::openstack::eqiad1::control)
    interface::add_ip6_mapped { 'main': }
}

# New systems to be placed into service by cloud team via T194186
node /^cloudelastic100[1-4].wikimedia.org$/ {
    role(elasticsearch::cloudelastic)
}

node /^cloudnet100[3-4].eqiad.wmnet$/ {
    role(wmcs::openstack::eqiad1::net)
}


node 'labnet1002.eqiad.wmnet' {
    role(wmcs::openstack::main::net)
}

## labsdb dbs
node /labsdb1009\.eqiad\.wmnet/ {
    role(labs::db::wikireplica_web)
}
node /labsdb10(10|11)\.eqiad\.wmnet/ {
    role(labs::db::wikireplica_analytics)
}

node 'labsdb1012.eqiad.wmnet'{
    role(labs::db::wikireplica_analytics::dedicated)
}


# labsdb1004 and labsdb1005 are ready to be decommissioned T216749
node 'labsdb1004.eqiad.wmnet' {
    role(spare::system)
}

node 'labsdb1005.eqiad.wmnet' {
    role(spare::system)
}

# labsdb1006 and labsdb1007 are ready to be decommissioned T220144
node 'labsdb1006.eqiad.wmnet' {
    role(spare::system)
}

node 'labsdb1007.eqiad.wmnet' {
    role(spare::system)
}

node /labstore100[12]\.eqiad\.wmnet/ {
    role(spare::system)
}

node 'labstore1003.eqiad.wmnet' {
    role(labs::nfs::misc)
    # Do not enable yet
    # include ::profile::base::firewall
}

node /labstore100[45]\.eqiad\.wmnet/ {
    role(wmcs::nfs::primary)
    # Do not enable yet
    # include ::profile::base::firewall
}

node /labstore100[67]\.wikimedia\.org/ {
    role(dumps::distribution::server)
}

node /labstore200[1-2]\.codfw\.wmnet/ {
    role(spare::system)
}

node 'labstore2003.codfw.wmnet' {
    role(labs::nfs::secondary_backup::tools)
    # Do not enable yet
    # include ::profile::base::firewall
}

node 'labstore2004.codfw.wmnet' {
    role(labs::nfs::secondary_backup::misc)
    # Do not enable yet
    # include ::profile::base::firewall
}

node 'lithium.eqiad.wmnet' {
    role(syslog::centralserver)
}

node /^logstash101[0-2]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
    include ::role::kafka::logging # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide
}

node /^logstash101[1-2]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide
}

# eqiad logstash collectors (Ganeti)
node /^logstash100[7-9]\.eqiad\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver
}

# New logstash servers being setup via T214608
node /^logstash101[012]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# codfw logstash kafka/elasticsearch
node /^logstash200[1-3]\.codfw\.wmnet$/ {
    role(logstash::elasticsearch)
    # Remove kafka::logging role after dedicated logging kafka hardware is online
    include ::role::kafka::logging # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide
}

# codfw logstash collectors (Ganeti)
node /^logstash200[4-6]\.codfw\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver # lint:ignore:wmf_styleguide
}

node /lvs100[1-2]\.wikimedia\.org/ {
    role(lvs::balancer)
}

node 'lvs1003.wikimedia.org' {
    role(spare::system)
}

node /lvs100[4-6]\.wikimedia\.org/ {
    role(lvs::balancer)
}

node 'lvs1015.eqiad.wmnet' {
    role(spare::system)
}

node 'lvs1016.eqiad.wmnet' {
    role(lvs::balancer)
}

# codfw lvs
node /lvs200[1-6]\.codfw\.wmnet/ {
    role(lvs::balancer)
}

node 'lvs2010.codfw.wmnet' {
    role(spare::system)
}

# ESAMS lvs servers
node /^lvs300[1-4]\.esams\.wmnet$/ {
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

node 'maerlant.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node 'maps1004.eqiad.wmnet' {
    role(maps::master)
}

node /^maps100[1-3]\.eqiad\.wmnet/ {
    role(maps::slave)
}

node 'maps2001.codfw.wmnet' {
    role(maps::master)
}

node 'maps2002.codfw.wmnet' {
    role(maps::slave)
}

node 'maps2003.codfw.wmnet' {
    role(maps::slave)
}

node 'maps2004.codfw.wmnet' {
    role(maps::master)
}

node 'matomo1001.eqiad.wmnet' {
    role(piwik)
    interface::add_ip6_mapped { 'main': }
}

node /^mc10(19|2[0-9]|3[0-6])\.eqiad\.wmnet/ {
    role(mediawiki::memcached)
}

node /^mc20(19|2[0-9]|3[0-6])\.codfw\.wmnet/ {
    role(mediawiki::memcached)
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role(otrs)
}

node 'multatuli.wikimedia.org' {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

node /^ms-fe1005\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::stats_reporter
    include ::lvs::realserver
}

node /^ms-fe100[6-8]\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

# Legacy Dell machines with partitioning scheme - T189633
node /^ms-be101[3-5]\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-be10(1[6-9]|[2345][0-9])\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe2005\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::stats_reporter
    include ::lvs::realserver
}

node /^ms-fe200[6-8]\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

# Legacy Dell machines with partitioning scheme - T189633
node /^ms-be201[3-5]\.codfw\.wmnet$/ {
    role(swift::storage)
}

node /^ms-be20(1[6-9]|[2345][0-9])\.codfw\.wmnet$/ {
    role(swift::storage)
}


## MEDIAWIKI APPLICATION SERVERS

## DATACENTER: EQIAD

# Debug servers
node /^mwdebug100[12]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# Appservers (serving normal website traffic)

# Row A

# mw1261 - mw1275 are in rack A7
node /^mw126[1-5]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}
node /^mw12(6[6-9]|7[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row C

# mw1319-33 are in rack C6
node /^mw13(19|2[0-9]|3[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row D

#mw1238-mw1258 are in rack D5
node /^mw12(3[8-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
}

# API (serving api traffic)

# Row A

# mw1276 - mw1283 are in rack A7
node /^mw127[6-9]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
}
node /^mw128[0-3]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mw1312 is in rack A6
node 'mw1312.eqiad.wmnet' {
    role(mediawiki::appserver::api)
}

# Row B

# mw1284-1290 are in rack B6
node /^mw12(8[4-9]|90)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mw1313-17 are in rack B7
node /^mw13(1[3-7])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row C

# mw1339-48 are in rack C6
node /^mw13(39|4[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row D
# mw1221-mw1235 are in rack D5
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mediawiki maintenance server (cron jobs)
# replaced mwmaint1001 (T201343) which replaced terbium (T192185)
node 'mwmaint1002.eqiad.wmnet' {
    role(mediawiki::maintenance)
    interface::add_ip6_mapped { 'main': }
}

# Former imagescalers (replaced by thumbor) T192457

# Row B (B6)
node /^mw129[78]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Row A

# mw1307-mw1311 are in rack A6
node /^mw13(0[7-9]|1[01])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row B

# mw1293-6,mw1299-mw1306 are in rack B6
node /^mw1(29[34569]|30[0-6])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Rack B7
node 'mw1318.eqiad.wmnet' {
    role(mediawiki::jobrunner)
}

# Row C

# mw1334-mw1338 are in rack C6
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

# mw2224-38 are in rack A3
# mw2239-42 are in rack A4
node /^mw22(2[4-9]|3[0-9]|4[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row B

#mw2254-2258 are in rack B3
node /^mw225[4-8]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

#mw2268-70 are in rack B3
node /^mw22(6[8-9]|70)\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row C

# mw2163-mw2186 are in rack C3
# mw2187-mw2199 are in rack C4
node /^mw21(6[3-9]|[7-9][0-9])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Row D

#mw2271-77 are in rack D3
node /^mw227[1-7]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

# Api

# Row A

# mw2215-2223 are in rack A3
node /^mw22(1[5-9]|2[0123])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mw2251-2253 are rack A4
node /^mw225[1-3]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row B

# mw2135-2147 are in rack B4
node /^mw21([3][5-9]|4[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mw2261-mw2262 are in rack B3
node /^mw226[1-2]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row C

# mw2200-2214 are in rack C4
node /^mw22(0[0-9]|1[0124])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Row D

#mw2283-90 are in rack D4
node /^mw22(8[3-9]|90)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# Former imagescalers (T192457)

# Row C (C3)
node /^mw2150\.codfw\.wmnet$/ {
    role(spare::system)
}

# Row A (A4)
node /^mw224[45]\.codfw\.wmnet$/ {
    role(spare::system)
}

# Jobrunners

# Row A

# mw2243, mw2246-mw2250 are in rack A4
node /^mw22(4[36789]|50)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row B

# mw2259-60 are in rack B3
node /^mw22(59|60)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# mw2263-7 are in rack B3
node /^mw226[3-7]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

# mw2151-62 are in rack C3
node /^mw21(5[1-9]|6[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row D

# mw2278-80 are in rack D3, mw2281-2 are in rack D4
node /^mw22(7[8-9]|8[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(logging::mediawiki::udp2log)
}

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
}

node 'mx1001.wikimedia.org' {
    role(mail::mx)
    include ::standard
    interface::add_ip6_mapped { 'main': }

    interface::alias { 'wiki-mail-eqiad.wikimedia.org':
        ipv4 => '208.80.154.91',
        ipv6 => '2620:0:861:3:208:80:154:91',
    }
}

node 'mx2001.wikimedia.org' {
    role(mail::mx)
    include ::standard
    interface::add_ip6_mapped { 'main': }

    interface::alias { 'wiki-mail-codfw.wikimedia.org':
        ipv4 => '208.80.153.46',
        ipv6 => '2620:0:860:2:208:80:153:46',
    }
}

# SWAP (Jupyter Notebook) Servers with Analytics Cluster Access
node /notebook100[34].eqiad.wmnet/ {
    role(swap)
}


# cluster management (cumin master) + other management tools
node 'neodymium.eqiad.wmnet' {
    role(cluster::management)
    include ::role::mgmt::drac_ilo
    interface::add_ip6_mapped { 'main': }
}

node 'nescio.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

# network monitoring tools, stretch (T125020, T166180)
node /^netmon(1002|2001)\.wikimedia\.org$/ {
    role(netmon)
}

# jessie VM for servermon until it supports stretch (T170653)
node 'netmon1003.wikimedia.org' {
    role(servermon)
    include ::role::network::monitor
    interface::add_ip6_mapped { 'main': }
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
}

node /orespoolcounter[12]00[12]\.(codfw|eqiad)\.wmnet/ {
    role(orespoolcounter)
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
    role(ores::redis)
    include ::standard
}

node /^oresrdb200[12]\.codfw\.wmnet$/ {
    role(ores::redis)
    include ::standard
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

# pc1004, pc1005 and pc1006 will be decommissioned - T210969
node /^pc10(04|05|06)\.eqiad\.wmnet$/ {
    role(spare::system)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(ping_offload)
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(planet)
    interface::add_ip6_mapped { 'main': }
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    role(openldap::corp)
}

node /poolcounter[12]00[123]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
}

node /^prometheus200[34]\.codfw\.wmnet$/ {
    role(prometheus)
}

node /^prometheus100[34]\.eqiad\.wmnet$/ {
    role(prometheus)
}

node /^proton[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(proton)

    interface::add_ip6_mapped { 'main': }
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

node /^puppetboard[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard)
}

node /^puppetdb[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

# New rdb servers T206450
node /^rdb100[59]\.eqiad\.wmnet$/ {
    role(redis::misc::master)
}

node /^(rdb1006|rdb1010)\.eqiad\.wmnet$/ {
    role(redis::misc::slave)
}

node /^rdb200[35]\.codfw\.wmnet$/ {
    role(redis::misc::master)
}
node /^rdb200[46]\.codfw\.wmnet$/ {
    role(redis::misc::slave)
}

node /^registry[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(docker_registry_ha::registry)
}


# https://releases.wikimedia.org - VMs for releases (mediawiki and other)
# https://releases-jenkins.wikimedia.org - for releases admins
node /^releases[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(releases)
    interface::add_ip6_mapped { 'main': }
}

node /^relforge100[1-2]\.eqiad\.wmnet/ {
    role(elasticsearch::relforge)
}

# restbase eqiad cluster
node /^restbase10(0[789]|1[012345678])\.eqiad\.wmnet$/ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20(0[7-9]|1[0-9]|20)\.codfw\.wmnet$/ {
    role(restbase::production)
}

# cassandra/restbase dev cluster
node /^restbase-dev100[4-6]\.eqiad\.wmnet$/ {
    role(restbase::dev_cluster)
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role(netinsights)
}

# Failoid service (Ganeti VM)
node 'roentgenium.eqiad.wmnet' {
    role(failoid)
}

# people.wikimedia.org, for all shell users
# replaced rutherfordium in T210036
node 'people1001.eqiad.wmnet' {
    role(microsites::peopleweb)
    interface::add_ip6_mapped { 'main': }
}

# cluster management (cumin master)
node 'sarin.codfw.wmnet' {
    role(cluster::management)

    interface::add_ip6_mapped { 'main': }
}

# scandium is a parsoid regression test server. it replaced ruthenium.
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
# Right now, both rt-server and rt-clients run on the same node
# But, we are likely going to split them into different boxes soon.
node 'scandium.eqiad.wmnet' {
    role(parsoid::testing)
}

# new sessionstore servers via T209393 & T209389
node /sessionstore[1-2]00[1-3].(eqiad|codfw).wmnet/ {
    role(sessionstore)
}

# Services 'B'
node /^scb[12]00[123456]\.(eqiad|codfw)\.wmnet$/ {
    role(scb)

    interface::add_ip6_mapped { 'main': }
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::labs)
}

# Read-only ldap replicas
node /^ldap-eqiad-replica0[1-2]\.wikimedia\.org$/ {
    role(openldap::replica)
}

node 'sodium.wikimedia.org' {
    role(mirrors)
    interface::add_ip6_mapped { 'main': }
}

node /^rhodium.eqiad.wmnet/ {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

# NEW network insights (netflow/pmacct, etc.) via T201364
node 'sulfur.wikimedia.org' {
    role(netinsights)
}



node 'thorium.eqiad.wmnet' {
    # thorium is used to host public Analytics websites like:
    # - https://stats.wikimedia.org (Wikistats)
    # - https://analytics.wikimedia.org (Analytics dashboards and datasets)
    # - https://datasets.wikimedia.org (deprecated, redirects to analytics.wm.org/datasets/archive)
    # - https://metrics.wikimedia.org (https://metrics.wmflabs.org/ (Wikimetrics))
    #
    # For a complete and up to date list please check the
    # related role/module.
    #
    # This node is not intended for data processing.
    role(analytics_cluster::webserver)
    interface::add_ip6_mapped { 'main': }
}

# new tor relay server, replaced radium T196701
node 'torrelay1001.wikimedia.org' {
    role(tor_relay)
    interface::add_ip6_mapped { 'main': }
}


# Failoid service (Ganeti VM)
node 'tureis.codfw.wmnet' {
    role(failoid)
}

# stat1004 contains all the tools and libraries to access
# the Analytics Cluster services, but should not be used
# for local data processing.
node 'stat1004.eqiad.wmnet' {
    role(statistics::explorer)
    interface::add_ip6_mapped { 'main': }
}

# Testing GPU for T148843
node 'stat1005.eqiad.wmnet' {
    role(statistics::gpu)
    interface::add_ip6_mapped { 'main': }
}

# stat1006 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1006.eqiad.wmnet' {
    role(statistics::cruncher)
    interface::add_ip6_mapped { 'main': }
}

# stat1007 will replace stat1005 very soon to allow
# SRE/Analytics to make the stat1005's GPU to work.
# T148843
node 'stat1007.eqiad.wmnet' {
    role(statistics::private)
    interface::add_ip6_mapped { 'main': }
}

# NOTE: new snapshot hosts must also be manually added to
# hieradata/common.yaml:dumps_nfs_clients for dump fs nfs mount,
# hieradata/common/scap/dsh.yaml for mediawiki installation,
# and to hieradata/hosts/ if running dumps for enwiki or wikidata.
node /^snapshot100[569]\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper)
}

node /^snapshot1007\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_monitor)
}

node /^snapshot1008\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_misc_crons_only)
}

node 'mwmaint2001.codfw.wmnet' {
    role(mediawiki::maintenance)
    interface::add_ip6_mapped { 'main': }
}

# Thumbor servers for MediaWiki image scaling
node /^thumbor100[1234]\.eqiad\.wmnet/ {
    role(thumbor::mediawiki)
}

node /^thumbor200[1234]\.codfw\.wmnet/ {
    role(thumbor::mediawiki)
}

# deployment servers
node 'deploy1001.eqiad.wmnet', 'deploy2001.codfw.wmnet' {
    role(deployment_server)
    interface::add_ip6_mapped { 'main': }
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role(xhgui::app)
}

# replaced magnesium (RT) (T119112 T123713)
node 'ununpentium.wikimedia.org' {
    role(requesttracker)
    interface::add_ip6_mapped { 'main': }
}

# To see labvirt nodes active in the scheduler look at hiera:
#  key: profile::openstack::main::nova::scheduler_pool
# We try to keep a few empty as emergency fail-overs
#  or transition hosts for maintenance to come
node /^labvirt100[0-7].eqiad.wmnet/ {
    role(wmcs::openstack::main::virt)
    include ::standard
}

# To see cloudvirt nodes active in the scheduler look at hiera:
#  key: profile::openstack::eqiad1::nova::scheduler_pool
# We try to keep a few empty as emergency fail-overs
#  or transition hosts for maintenance to come
node /^cloudvirt100[8-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

node /^cloudvirt101[2-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

node /^cloudvirt102[0-9].eqiad.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudvirt1030.eqiad.wmnet' {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

# New analytics cloudvirt nodes via T207194
node /^cloudvirtan100[1-5].eqiad.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

# Wikidata query service
node /^wdqs100[4-6]\.eqiad\.wmnet$/ {
    role(wdqs)
}

node /^wdqs200[1-3]\.codfw\.wmnet$/ {
    role(wdqs)
}

# Wikidata query service internal
node /^wdqs100[378]\.eqiad\.wmnet$/ {
    role(wdqs::internal)
}

node /^wdqs200[4-6]\.codfw\.wmnet$/ {
    role(wdqs::internal)
}

# Wikidata query service automated deployment
node 'wdqs1009.eqiad.wmnet' {
    role(wdqs::autodeploy)
}

# Wikidata query service test
node 'wdqs1010.eqiad.wmnet' {
    role(wdqs::test)
}

node 'weblog1001.eqiad.wmnet'
{
    role(logging::webrequest::ops)
    interface::add_ip6_mapped { 'main': }
}

# VMs for performance team replacing hafnium (T179036)
node /^webperf[12]001\.(codfw|eqiad)\.wmnet/ {
    role(webperf::processors_and_site)
    # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': }
    # lint:endignore
}

# VMs for performance team profiling tools (T194390)
node /^webperf[12]002\.(codfw|eqiad)\.wmnet/ {
    role(webperf::profiling_tools)
    # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': }
    # lint:endignore
}

node 'wezen.codfw.wmnet' {
    role(syslog::centralserver)
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp10(2[5-9]|[34][0-9])\.eqiad\.wmnet$/ {
    role(parsoid)
}

node /^wtp20(0[1-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role(parsoid)
}

node default {
    if $::realm == 'production' {
        include ::standard
        interface::add_ip6_mapped { 'main': }
    } else {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require ::role::labs::instance
    }
}
