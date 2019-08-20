# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp
# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if !defined('$cluster') {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

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
    role(acme_chief)
    interface::add_ip6_mapped { 'main': }
}

node 'acmechief-test2001.codfw.wmnet' {
    role(acme_chief)
    interface::add_ip6_mapped { 'main': }
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

# superset.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# T212243
node 'analytics-tool1004.eqiad.wmnet' {
    role(analytics_cluster::superset)
    interface::add_ip6_mapped { 'main': }
}

# Staging environment of superset.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset
# T212243
node 'an-tool1005.eqiad.wmnet' {
    role(analytics_cluster::superset::staging)
    interface::add_ip6_mapped { 'main': }
}

# Analytics Hadoop client for the Testing cluster
# T226844
node 'an-tool1006.eqiad.wmnet' {
    role(analytics_test_cluster::client)
    interface::add_ip6_mapped { 'main': }
}

# turnilo.wikimedia.org
# https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot
node 'an-tool1007.eqiad.wmnet' {
    role(analytics_cluster::turnilo)
    interface::add_ip6_mapped { 'main': }
}

# New Analytics Zookepeer cluster - T227025
# Not yet taking traffic for the Hadoop cluster.
node /an-conf100[1-3]\.eqiad\.wmnet/ {
    role(analytics_cluster::zookeeper)
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

node /auth100[12]\.eqiad\.wmnet/ {
    role('yubiauth_server')
    interface::add_ip6_mapped { 'main': }
}

node 'auth2001.codfw.wmnet' {
    role('yubiauth_server')
    interface::add_ip6_mapped { 'main': }
}

node /^authdns[12]001\.wikimedia\.org$/ {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

# backup1001 entry until service deployment via T196478
node 'backup1001.eqiad.wmnet' {
    role(spare::system)
}

# Bastion in Virginia
node 'bast1002.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

# Bastion in Texas - (T196665, replaced bast2001)
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
    interface::add_ip6_mapped { 'main': }
}

node /^cloudstore100[89]\.wikimedia\.org/ {
    role(wmcs::nfs::secondary)
}

# All gerrit servers (swap master status in hiera)
node 'cobalt.wikimedia.org', 'gerrit2001.wikimedia.org' {
    role(gerrit)

    interface::add_ip6_mapped { 'main': }
}

# gerrit1001 to replace cobalt T231046
node 'gerrit1001.wikimedia.org' {
    role(spare::system)
}

# Zookeeper and Etcd discovery service nodes in eqiad
node /^conf100[456]\.eqiad\.wmnet$/ {
    role(configcluster_stretch)
    interface::add_ip6_mapped { 'main': }
}

# Zookeeper and Etcd discovery service nodes in codfw
node /^conf200[123]\.codfw\.wmnet$/ {
    role(configcluster)
    interface::add_ip6_mapped { 'main': }
}

# CI master / CI standby (switch in Hiera)
node /^(contint1001|contint2001)\.wikimedia\.org$/ {
    role(ci::master)

    interface::add_ip6_mapped { 'main': }
}

# Debian package/docker images building host in production
node /^boron\.eqiad\.wmnet$/ {
    role(builder)
    interface::add_ip6_mapped { 'main': }
}

# cp1008: to be decommed T229586
# to be replaced with cp1099 in the near future
node 'cp1008.wikimedia.org' {
    role(spare::system)
}

# cp107[1-4]: to be decommed T229586
node /^cp107[1-4]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# cp1099: to be decommed T229586
node /^cp1099\.eqiad\.wmnet$/ {
    role(spare::system)
}

node /^cp10(7[79]|8[13579])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node 'cp1075.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role(cache::text_ats)
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

# Actual spares for now, in case of need for cp cluster before next
# procurements arrive
node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(test)
}

# ex cp-misc_esams
node /^cp30(0[78]|10)\.esams\.wmnet$/ {
    role(spare::system)
}

node /^cp30(3[0123]|4[0123])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

# Broken host, decom in T227077
node 'cp3037.esams.wmnet' {
    role(spare::system)
}

node /^cp30(3[45689]|4[45679])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

#
# ulsfo caches
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
# eqsin caches
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

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1067.eqiad.wmnet' {
    role(mariadb::core)
}
# eqiad replicas
node /^db1(080|083|089|106|118|119|134)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2048.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# codfw replicas
node /^db2(055|071|072|092|103|112|116|130)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1066.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
# see also db1090, db1103, db1105 bellow
node /^db1(074|076|122|129)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2107.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

node /^db2(104|108|125|126)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1075.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db1(078|112|123)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2105.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

node /^db2(074|109|127)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1081.eqiad.wmnet' {
    role(mariadb::core)
}

# see also db1097 and db1103 below
node /^db1(084|091|121|138)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s4-test hosts on eqiad
node /^db1(077|111)\.eqiad\.wmnet/ {
    role(mariadb::core_test)
    interface::add_ip6_mapped { 'main': }
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2090.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# see also db2084 and db2091 below
node /^db2(073|106|110|119)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s5 (dewiki and others) core production dbs on eqiad
# eqiad master
node 'db1070.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1096 db1097 and db1113 below
node /^db1(082|100|110|130)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki and others) core production dbs on codfw
# codfw master
node 'db2123.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# See also db2084 and db2089 below
node /^db2(075|111|113|128)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1061.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1096 db1098 and db1113 below
node /^db1(085|088|093|131)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on codfw
# codfw master
node 'db2129.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

node /^db2(046|053|060|076|114|117|124)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1062.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1090, db1098 and db1101 bellow
node /^db1(069|079|086|094|136)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

#
# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2047.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

node /^db2(054|061|068|077|118|120|121|122)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# s8 (wikidata) core production dbs on eqiad
# eqiad master
node 'db1104.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1099 and db1101 below
node /^db1(092|087|109|126)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s8 (wikidata) core production dbs on codfw
# codfw master
node 'db2079.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# See also db2085 and db2086 below
node /^db20(80|81|82|83)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# hosts with multiple shards
node /^db1(090|096|097|098|099|101|103|105|113)\.eqiad\.wmnet/ {
    role(mariadb::core_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node /^db20(84|85|86|87|88|89|91)\.codfw\.wmnet/ {
    role(mariadb::core_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

## x1 shard
# eqiad
# x1 eqiad master
node 'db1120.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1127.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1137.eqiad.wmnet' {
    role(mariadb::core)
}



# codfw
# x1 codfw master
node 'db2096.codfw.wmnet' {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# x1 codfw slaves
node /^db2(115|131)\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# To be decommissioned T229381
node 'db1071.eqiad.wmnet' {
    role(spare::system)
}

# To be decommissioned T228956
node 'db1072.eqiad.wmnet' {
    role(spare::system)
}

# To be decommissioned # T229784
node 'db2035.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T223885
node 'db2036.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T224720
node 'db2037.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T227565
node 'db2038.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T224079
node 'db2040.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T223950
node 'db2041.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230311
node 'db2043.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230761
node 'db2044.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230721
node 'db2049.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230391
node 'db2050.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230778
node 'db2051.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230883
node 'db2052.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230777
node 'db2056.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230394
node 'db2057.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T229543
node 'db2058.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230884
node 'db2059.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230704
node 'db2063.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230885
node 'db2066.codfw.wmnet' {
    role(spare::system)
}

# To be decommissioned # T230107
node 'db2069.codfw.wmnet' {
    role(spare::system)
}

## m1 shard

# See also multiinstance misc hosts db1117 and db2078 below
node 'db1063.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
    interface::add_ip6_mapped { 'main': }
}

node 'db1135.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
        master => false,
    }
    interface::add_ip6_mapped { 'main': }
}

node 'db2062.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
    }
    interface::add_ip6_mapped { 'main': }
}


## m2 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1132.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm2',
        master => true,
    }
    interface::add_ip6_mapped { 'main': }
}

node 'db2067.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm2',
    }
    interface::add_ip6_mapped { 'main': }
}

## m3 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1128.eqiad.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        master => true,
    }
    interface::add_ip6_mapped { 'main': }
}


# codfw
node 'db2065.codfw.wmnet' {
    role(mariadb::misc::phabricator)
    interface::add_ip6_mapped { 'main': }
}


## m4 shard

node 'db1107.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::master)
    interface::add_ip6_mapped { 'main': }
}

# These replicas have an m4 custom replication protocol.

node 'db1108.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::replica)
    interface::add_ip6_mapped { 'main': }
}

## m5 shard

# See also multiinstance misc hosts db1117 and db2078 below

node 'db1073.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm5',
        master => true,
    }
    interface::add_ip6_mapped { 'main': }
}

node 'db1133.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm5',
        master => false,
    }
    interface::add_ip6_mapped { 'main': }
}

node /^db20(70)\.codfw\.wmnet/ {
    class { '::role::mariadb::misc':
        shard => 'm5',
    }
    interface::add_ip6_mapped { 'main': }
}

# misc multiinstance
node 'db1117.eqiad.wmnet' {
    role(mariadb::misc::multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db2078.codfw.wmnet' {
    role(mariadb::misc::multiinstance)
    interface::add_ip6_mapped { 'main': }
}

# sanitarium hosts
node /^db1(124|125)\.eqiad\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

node /^db2(094|095)\.codfw\.wmnet/ {
    role(mariadb::sanitarium_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

# tendril db
node 'db1115.eqiad.wmnet' {
    role(mariadb::misc::tendril_and_zarcillo)
    interface::add_ip6_mapped { 'main': }
}

# Standby tendril host
node 'db2093.codfw.wmnet' {
    role(mariadb::misc::tendril)
    interface::add_ip6_mapped { 'main': }
}

# eqiad backup sources
node 'db1095.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

node 'db1102.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

node 'db1116.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

node 'db1139.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db1140.eqiad.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

# codfw backup sources

node 'db2097.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db2098.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db2099.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db2100.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}
node 'db2101.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}

# backup testing hosts
node 'db1114.eqiad.wmnet' {
    role(mariadb::core_test)
    interface::add_ip6_mapped { 'main': }
}

node 'db2102.codfw.wmnet' {
    role(mariadb::core_test)
    interface::add_ip6_mapped { 'main': }
}

# old eqiad dbstores
node 'dbstore1001.eqiad.wmnet' {
    role(spare::system)
}

# old codfw dbstores
node 'dbstore2001.codfw.wmnet' {
    role(spare::system)
}

node 'dbstore2002.codfw.wmnet' {
    role(spare::system)
}

# Analytics production replicas
node /^dbstore100(3|4|5)\.eqiad\.wmnet$/ {
    role(mariadb::dbstore_multiinstance)
    interface::add_ip6_mapped { 'main': }
}


# database-provisioning and short-term/postprocessing backups servers

# eqiad ones pending full setup
node 'dbprov1001.eqiad.wmnet' {
    role(mariadb::backups)
    interface::add_ip6_mapped { 'main': }
}
node 'dbprov1002.eqiad.wmnet' {
    role(mariadb::backups)
    interface::add_ip6_mapped { 'main': }
}
node 'dbprov2001.codfw.wmnet' {
    role(mariadb::backups)
    interface::add_ip6_mapped { 'main': }
}
node 'dbprov2002.codfw.wmnet' {
    role(mariadb::backups)
    interface::add_ip6_mapped { 'main': }
}

# Active eqiad proxies for misc databases
node /^dbproxy10(01|02|03|05|06|07|08|13|14)\.eqiad\.wmnet$/ {
    role(mariadb::proxy::master)
    interface::add_ip6_mapped { 'main': }
}

# Passive codfw proxies for misc databases
node /^dbproxy20(01|02|03)\.codfw\.wmnet$/ {
    role(mariadb::proxy::master)
    interface::add_ip6_mapped { 'main': }
}


# labsdb proxies (controling replica service dbs)
# analytics proxy
node 'dbproxy1010.eqiad.wmnet' {
    role(mariadb::proxy::master)
    interface::add_ip6_mapped { 'main': }
}
# web proxy
# dbproxy1011 will be decommissioned at some point
node 'dbproxy1011.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
    interface::add_ip6_mapped { 'main': }
}

node 'dbproxy1019.eqiad.wmnet' {
    role(mariadb::proxy::replicas)
}

# new dbproxy hosts to be pressed into service by DBA team T202367
node /^dbproxy10(12|15|16|17|18|20|21)\.eqiad\.wmnet$/ {
    role(spare::system)
}

# new dbproxy hosts to be productionized T223492
node /^dbproxy200[4]\.codfw\.wmnet$/ {
    role(spare::system)
}

node /^dbmonitor[12]001\.wikimedia\.org$/ {
    role(tendril)
}

node /^debmonitor[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(debmonitor::server)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

# fallback nfs server for dumps generation, also
# will rsync data to web servers
node /^dumpsdata1002.eqiad.wmnet$/ {
    role(dumps::generation::server::fallback)
    interface::add_ip6_mapped { 'main': }
}

# misc. test server, keep (T156208)
node 'eeden.wikimedia.org' {
    role(test)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic101[7-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic102[023456789]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic10[3-4][0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic105[0-2]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic202[5-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic20[3-4][0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
}

node /^elastic205[0-4]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

node /^es201[45]\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

node /^es201[89]\.codfw\.wmnet/ {
    role(mariadb::core)
    interface::add_ip6_mapped { 'main': }
}

# Disaster recovery hosts for external storage
# These nodes are in process of being decommissioned

node /^es200[1-4]\.codfw\.wmnet/ {
    role(mariadb::temporary_storage)
    interface::add_ip6_mapped { 'main': }
}

node /^failoid[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(failoid)
    interface::add_ip6_mapped { 'main': }
}

# Backup system, see T176505.
# This is a reserved system. Ask Otto or Faidon.
node 'flerovium.eqiad.wmnet' {
    role(analytics_cluster::hadoop::client)
    interface::add_ip6_mapped { 'main': }
}

# Backup system, see T176506.
# This is a reserved system. Ask Otto or Faidon.
node 'furud.codfw.wmnet' {
    role(analytics_cluster::hadoop::client)
    interface::add_ip6_mapped { 'main': }
}

# Test Ganeti instance aimed to iron out all
# the details related to a Kerberos service for
# the Hadoop test cluster. This instance has a
# generic name and it might be confusing, but its
# sole purpose is to reach a point in which we know
# what hardware to get etc..
# More details: T211836
node 'kerberos1001.eqiad.wmnet' {
    role(kerberos::kdc)
    interface::add_ip6_mapped { 'main': }
}

# Etcd cluster for kubernetes
# TODO: Rename the eqiad etcds to the codfw etcds naming scheme
node /^(kub)?etcd[12]00[123]\.(eqiad|codfw)\.wmnet$/ {
    role(etcd::kubernetes)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    role(etherpad)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

# Virtualization hosts
node /^ganeti[12]00[0-8]\.(codfw|eqiad)\.wmnet$/ {
    role(ganeti)
}

# new ulsfo ganeti hosts T226444
node /^ganeti400[1-3]\.ulsfo.wmnet$/ {
    role(spare::system)
}


# Virtual machine being turned up to run Grafana (T210416)
node 'grafana1001.eqiad.wmnet' {
    role(grafana)
    interface::add_ip6_mapped { 'main': }
}

# debug_proxy hosts; Varnish backend for X-Wikimedia-Debug reqs
node /^(hassaleh|hassium)\.(codfw|eqiad)\.wmnet$/ {
    role(debug_proxy)
    interface::add_ip6_mapped { 'main': }
}

node 'helium.eqiad.wmnet' {
    role(backup)
    interface::add_ip6_mapped { 'main': }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    role(backup::offsite)
    interface::add_ip6_mapped { 'main': }
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

# cloudservices1003/1004 hosts openstack-designate
# and the powerdns auth and recursive services for instances in eqiad1.
node /^cloudservices100[34]\.wikimedia\.org$/ {
    role(wmcs::openstack::eqiad1::services)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudweb2001-dev.wikimedia.org' {
    role(spare::system)
}

node /^cloudnet200[23]-dev\.codfw\.wmnet$/ {
    role(wmcs::openstack::codfw1dev::net)
}

node /^labtestvirt2003\.codfw\.wmnet$/ {
    role(spare::system)
}

node 'clouddb2001-dev.codfw.wmnet' {
    role(wmcs::openstack::codfw1dev::db)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudcontrol2003-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestpuppetmaster2001.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::puppetmaster::frontend)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudservices2002-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::services)
    interface::add_ip6_mapped { 'main': }
}

node 'labtestservices2003.wikimedia.org' {
    role(spare::system)
}

node /labweb100[12]\.wikimedia\.org/ {
    role(wmcs::openstack::eqiad1::labweb)

    interface::add_ip6_mapped { 'main': }
}

node 'graphite2001.codfw.wmnet' {
    role(spare::system)
}

# Primary graphite host
node 'graphite1004.eqiad.wmnet' {
    role(graphite::production)
    # TODO: move the roles below to ::role::alerting::host
    include ::role::graphite::alerts
    include ::role::elasticsearch::alerts
    interface::add_ip6_mapped { 'main': }
}

# Standby graphite host
node 'graphite2003.codfw.wmnet' {
    role(graphite::production)
    interface::add_ip6_mapped { 'main': }
}

node 'idp1001.wikimedia.org' {
    role(idp)
    interface::add_ip6_mapped { 'main': }
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
node /^(phab1003\.eqiad|phab2001\.codfw)\.wmnet$/ {
    role(phabricator)
    interface::add_ip6_mapped { 'main': }
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Experimental Yubico two factor authentication bastion',
    }
    interface::add_ip6_mapped { 'main': }
    role(bastionhost::twofa)
}

# Kafka Brokers - main-eqiad and main-codfw Kafka clusters.
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka100[123]\.eqiad\.wmnet/ {
    role(kafka::main)
    interface::add_ip6_mapped { 'main': }
}

# eqiad kafka main servers, pushing into service via T226274
node /kafka-main100[1-5]\.eqiad\.wmnet/ {
    role(spare::system)
}

node /kafka-main200[123]\.codfw\.wmnet/ {
    role(kafka::main)
    interface::add_ip6_mapped { 'main': }
}

node /kafka200[123]\.codfw\.wmnet/ {
    role(spare::system)
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
# profile::racktables             - https://racktables.wikimedia.org
node 'krypton.eqiad.wmnet', 'miscweb2001.codfw.wmnet' {
    role(webserver_misc_apps)
    interface::add_ip6_mapped { 'main': }
}

node /kubernetes[12]00[1-6]\.(codfw|eqiad)\.wmnet/ {
    role(kubernetes::worker)
    interface::add_ip6_mapped { 'main': }
}

node /kubestage100[12]\.eqiad\.wmnet/ {
    role(kubernetes::staging::worker)
    interface::add_ip6_mapped { 'main': }
}

node 'cloudcontrol2001-dev.wikimedia.org' {
    role(wmcs::openstack::codfw1dev::control)
    interface::add_ip6_mapped { 'main': }
}

node /cloudvirt200[1-3]-dev\.codfw\.wmnet/ {
    role(wmcs::openstack::codfw1dev::virt)
}

# WMCS Graphite and StatsD hosts
node /labmon100[12]\.eqiad\.wmnet/ {
    role(wmcs::monitoring)
    interface::add_ip6_mapped { 'main': }
}

node /^cloudcontrol100[3-4].wikimedia.org$/ {
    role(wmcs::openstack::eqiad1::control)
    interface::add_ip6_mapped { 'main': }
}

# New systems to be placed into service by cloud team via T194186
node /^cloudelastic100[1-4].wikimedia.org$/ {
    role(elasticsearch::cloudelastic)
    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide
}

node /^cloudnet100[3-4].eqiad.wmnet$/ {
    role(wmcs::openstack::eqiad1::net)
}

## labsdb dbs
node 'labsdb1009.eqiad.wmnet' {
    role(labs::db::wikireplica_web)
}
node 'labsdb1010.eqiad.wmnet' {
    role(labs::db::wikireplica_web)
}
node 'labsdb1011.eqiad.wmnet' {
    role(labs::db::wikireplica_analytics)
}

node 'labsdb1012.eqiad.wmnet'{
    role(labs::db::wikireplica_analytics::dedicated)
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
    role(wmcs::nfs::primary_backup::tools)
}

node 'labstore2004.codfw.wmnet' {
    role(wmcs::nfs::primary_backup::misc)
}


# Read-only ldap replicas in eqiad, these were setup with a non-standard naming
# scheme and will be renamed the next time they are reimaged (e.g. for the
# buster upgrade)
node /^ldap-eqiad-replica0[1-2]\.wikimedia\.org$/ {
    role(openldap::replica)
    interface::add_ip6_mapped { 'main': }
}

# Read-only ldap replicas in codfw
node /^ldap-replica200[1-2]\.wikimedia\.org$/ {
    role(openldap::replica)
    interface::add_ip6_mapped { 'main': }
}

node 'lithium.eqiad.wmnet' {
    role(spare::system)
}

node /^logstash101[0-2]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
    include ::role::kafka::logging # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide
}

# eqiad logstash collectors (Ganeti)
node /^logstash100[7-9]\.eqiad\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

node /lvs101[3456]\.eqiad\.wmnet/ {
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

node /^maps100[1-3]\.eqiad\.wmnet/ {
    role(maps::slave)
    interface::add_ip6_mapped { 'main': }
}

node 'maps1004.eqiad.wmnet' {
    role(maps::master)
    interface::add_ip6_mapped { 'main': }
}

node /^maps200[1-3]\.codfw\.wmnet/ {
    role(maps::slave)
    interface::add_ip6_mapped { 'main': }
}

node 'maps2004.codfw.wmnet' {
    role(maps::master)
    interface::add_ip6_mapped { 'main': }
}

node 'matomo1001.eqiad.wmnet' {
    role(piwik)
    interface::add_ip6_mapped { 'main': }
}

node /^mc10(19|2[0-9]|3[0-6])\.eqiad\.wmnet/ {
    role(mediawiki::memcached)
    interface::add_ip6_mapped { 'main': }
}

node /^mc20(19|2[0-9]|3[0-6])\.codfw\.wmnet/ {
    role(mediawiki::memcached)
    interface::add_ip6_mapped { 'main': }
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role(otrs)
    interface::add_ip6_mapped { 'main': }
}

node 'multatuli.wikimedia.org' {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

node /^ms-fe1005\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::stats_reporter
    include ::lvs::realserver
    interface::add_ip6_mapped { 'main': }
}

node /^ms-fe100[6-8]\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
    interface::add_ip6_mapped { 'main': }
}

node /^ms-be10(1[6-9]|[2345][0-9])\.eqiad\.wmnet$/ {
    role(swift::storage)
    interface::add_ip6_mapped { 'main': }
}

node /^ms-fe2005\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::role::swift::stats_reporter
    include ::lvs::realserver
    interface::add_ip6_mapped { 'main': }
}

node /^ms-fe200[6-8]\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
    interface::add_ip6_mapped { 'main': }
}

# Legacy Dell machines with partitioning scheme - T189633
node /^ms-be201[3-5]\.codfw\.wmnet$/ {
    role(spare::system)
}

node /^ms-be20(1[6-9]|[2345][0-9])\.codfw\.wmnet$/ {
    role(swift::storage)
    interface::add_ip6_mapped { 'main': }
}


## MEDIAWIKI APPLICATION SERVERS

## DATACENTER: EQIAD

# Debug servers
node /^mwdebug100[12]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
    interface::add_ip6_mapped { 'main': }
}

# Appservers (serving normal website traffic)

# Row A

# mw1261 - mw1275 are in rack A7
node /^mw126[1-5]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
    interface::add_ip6_mapped { 'main': }
}
node /^mw12(6[6-9]|7[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Row C

# mw1319-33 are in rack C6
node /^mw13(19|2[0-9]|3[0-3])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Row D

#mw1238-mw1258 are in rack D5
node /^mw12(3[8-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# API (serving api traffic)

# Row A

# mw1276 - mw1283 are in rack A7
node /^mw127[6-9]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
    interface::add_ip6_mapped { 'main': }
}
node /^mw128[0-3]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# mw1312 is in rack A6
node 'mw1312.eqiad.wmnet' {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row B

# mw1284-1290,mw1297 are in rack B6
node /^mw12(8[4-9]|9[07])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# mw1313-17 are in rack B7
node /^mw13(1[3-7])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row C

# mw1339-48 are in rack C6
node /^mw13(39|4[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row D
# mw1221-mw1235 are in rack D5
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# mediawiki maintenance server (cron jobs)
# replaced mwmaint1001 (T201343) which replaced terbium (T192185)
node 'mwmaint1002.eqiad.wmnet' {
    role(mediawiki::maintenance)
    interface::add_ip6_mapped { 'main': }
}

# Former imagescaler (replaced by thumbor) T192457
# Row B (B6)
node /^mw1298\.eqiad\.wmnet$/ {
    role(spare::system)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Row A

# mw1307-mw1311 are in rack A6
node /^mw13(0[7-9]|1[01])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# Row B

# mw1293-6,mw1299-mw1306 are in rack B6
node /^mw1(29[34569]|30[0-6])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# Rack B7
node 'mw1318.eqiad.wmnet' {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# Row C

# mw1334-mw1338 are in rack C6
node /^mw133[4-8]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

## DATACENTER: CODFW

# Debug servers
# mwdebug2001 is in row A, mwdebug2002 is in row B
node /^mwdebug200[12]\.codfw\.wmnet$/ {
    role(mediawiki::canary_appserver)
    interface::add_ip6_mapped { 'main': }
}


# Appservers

# Row A

# mw2224-38 are in rack A3
# mw2239-42 are in rack A4
node /^mw22(2[4-9]|3[0-9]|4[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Row B

#mw2254-2258 are in rack B3
node /^mw225[4-8]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

#mw2268-70 are in rack B3
node /^mw22(6[8-9]|70)\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Row C

# mw2163-mw2186 are in rack C3
# mw2187-mw2199 are in rack C4
node /^mw21(6[3-9]|[7-9][0-9])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Row D

#mw2271-77 are in rack D3
node /^mw227[1-7]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    interface::add_ip6_mapped { 'main': }
}

# Api

# Row A

# mw2215-2223 are in rack A3
node /^mw22(1[5-9]|2[0123])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# mw2244-mw2245,mw2251-2253 are rack A4
node /^mw22(4[45]|5[1-3])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row B

# mw2135-2147 are in rack B4
node /^mw21([3][5-9]|4[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# mw2261-mw2262 are in rack B3
node /^mw226[1-2]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row C

# mw2200-2214 are in rack C4
node /^mw22(0[0-9]|1[0124])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Row D

#mw2283-90 are in rack D4
node /^mw22(8[3-9]|90)\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    interface::add_ip6_mapped { 'main': }
}

# Jobrunners

# Row A

# mw2243, mw2246-mw2250 are in rack A4
node /^mw22(4[36789]|50)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# Row B

# mw2259-60 are in rack B3
node /^mw22(59|60)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# mw2263-7 are in rack B3
node /^mw226[3-7]\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

# mw2150-62 are in rack C3
node /^mw21(5[0-9]|6[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

# Row D

# mw2278-80 are in rack D3, mw2281-2 are in rack D4
node /^mw22(7[8-9]|8[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
    interface::add_ip6_mapped { 'main': }
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(logging::mediawiki::udp2log)
    interface::add_ip6_mapped { 'main': }
}

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
    interface::add_ip6_mapped { 'main': }
}

node 'mx1001.wikimedia.org' {
    role(mail::mx)
    interface::add_ip6_mapped { 'main': }

    interface::alias { 'wiki-mail-eqiad.wikimedia.org':
        ipv4 => '208.80.154.91',
        ipv6 => '2620:0:861:3:208:80:154:91',
    }
}

node 'mx2001.wikimedia.org' {
    role(mail::mx)
    interface::add_ip6_mapped { 'main': }

    interface::alias { 'wiki-mail-codfw.wikimedia.org':
        ipv4 => '208.80.153.46',
        ipv6 => '2620:0:860:2:208:80:153:46',
    }
}

# ncredir instances
node /^ncredir100[12]\.eqiad\.wmnet$/ {
    role(ncredir)
    interface::add_ip6_mapped { 'main': }
}

node /^ncredir200[12]\.codfw\.wmnet$/ {
    role(ncredir)
    interface::add_ip6_mapped { 'main': }
}

# SWAP (Jupyter Notebook) Servers with Analytics Cluster Access
node /notebook100[34].eqiad.wmnet/ {
    role(swap)
    interface::add_ip6_mapped { 'main': }
}


# cluster management (cumin master) + other management tools
node 'neodymium.eqiad.wmnet' {
    role(spare::system)
}

node 'nescio.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

# network monitoring tools, stretch (T125020, T166180)
node /^netmon(1002|2001)\.wikimedia\.org$/ {
    role(netmon)
}

# Network insights (netflow/pmacct, etc.)
node 'netflow1001.eqiad.wmnet' {
    role(netinsights)
    interface::add_ip6_mapped { 'main': }
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
    interface::add_ip6_mapped { 'main': }
}

node /orespoolcounter[12]00[34]\.(codfw|eqiad)\.wmnet/ {
    role(orespoolcounter)
    interface::add_ip6_mapped { 'main': }
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
    role(ores::redis)
    interface::add_ip6_mapped { 'main': }
}

node /^oresrdb200[12]\.codfw\.wmnet$/ {
    role(ores::redis)
    interface::add_ip6_mapped { 'main': }
}

# parser cache databases
# eqiad
# pc1
node /^pc10(07|10)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}
# pc2
node /^pc10(08)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}
# pc3
node /^pc10(09)\.eqiad\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}

# codfw
# pc1
node /^pc20(07|10)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}
# pc2
node /^pc20(08)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}
# pc3
node /^pc20(09)\.codfw\.wmnet$/ {
    role(mariadb::parsercache)
    interface::add_ip6_mapped { 'main': }
}

# virtual machines for https://wikitech.wikimedia.org/wiki/Ping_offload
node /^ping[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(ping_offload)
    interface::add_ip6_mapped { 'main': }
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(planet)
    interface::add_ip6_mapped { 'main': }
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    role(openldap::corp)
    interface::add_ip6_mapped { 'main': }
}

node /poolcounter[12]00[345]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
    interface::add_ip6_mapped { 'main': }
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

node 'puppetmaster1003.eqiad.wmnet' {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

node /^puppetboard[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetboard)
    interface::add_ip6_mapped { 'main': }
}

node /^puppetdb[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
    interface::add_ip6_mapped { 'main': }
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
    interface::add_ip6_mapped { 'main': }
}

# New rdb servers T206450
node /^rdb100[59]\.eqiad\.wmnet$/ {
    role(redis::misc::master)
    interface::add_ip6_mapped { 'main': }
}

node /^(rdb1006|rdb1010)\.eqiad\.wmnet$/ {
    role(redis::misc::slave)
    interface::add_ip6_mapped { 'main': }
}

node /^rdb200[35]\.codfw\.wmnet$/ {
    role(redis::misc::master)
    interface::add_ip6_mapped { 'main': }
}
node /^rdb200[46]\.codfw\.wmnet$/ {
    role(redis::misc::slave)
    interface::add_ip6_mapped { 'main': }
}

node /^registry[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role(docker_registry_ha::registry)
    interface::add_ip6_mapped { 'main': }
}


# https://releases.wikimedia.org - VMs for releases (mediawiki and other)
# https://releases-jenkins.wikimedia.org - for releases admins
node /^releases[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(releases)
    interface::add_ip6_mapped { 'main': }
}

node /^relforge100[1-2]\.eqiad\.wmnet/ {
    role(elasticsearch::relforge)
    interface::add_ip6_mapped { 'main': }
}

# restbase eqiad cluster
node /^restbase10(1[6-9]|2[0-7])\.eqiad\.wmnet$/ {
    role(restbase::production)
    interface::add_ip6_mapped { 'main': }
}

# restbase codfw cluster
node /^restbase20(09|1[0-9]|20)\.codfw\.wmnet$/ {
    role(restbase::production)
    interface::add_ip6_mapped { 'main': }
}

# cassandra/restbase dev cluster
node /^restbase-dev100[4-6]\.eqiad\.wmnet$/ {
    role(restbase::dev_cluster)
    interface::add_ip6_mapped { 'main': }
}

# Failoid service (Ganeti VM)
node 'roentgenium.eqiad.wmnet' {
    role(failoid)
}

# virtual machines for https://wikitech.wikimedia.org/wiki/RPKI#Validation
node /^rpki[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(rpkivalidator)
    interface::add_ip6_mapped { 'main': }
}

# people.wikimedia.org, for all shell users
# replaced rutherfordium in T210036
node 'people1001.eqiad.wmnet' {
    role(microsites::peopleweb)
    interface::add_ip6_mapped { 'main': }
}

# cluster management (cumin master)
node 'sarin.codfw.wmnet' {
    role(spare::system)
}

# scandium is a parsoid regression test server. it replaced ruthenium.
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
# Right now, both rt-server and rt-clients run on the same node
# But, we are likely going to split them into different boxes soon.
node 'scandium.eqiad.wmnet' {
    role(parsoid::testing)
    interface::add_ip6_mapped { 'main': }
}

node /schema[12]00[12].(eqiad|codfw).wmnet/ {
    role(eventschemas::service)
    interface::add_ip6_mapped { 'main': }
}

# new sessionstore servers via T209393 & T209389
node /sessionstore[1-2]00[1-3].(eqiad|codfw).wmnet/ {
    role(sessionstore)
    interface::add_ip6_mapped { 'main': }
}

# Services 'B'
node /^scb[12]00[123456]\.(eqiad|codfw)\.wmnet$/ {
    role(scb)

    interface::add_ip6_mapped { 'main': }
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::labs)
    interface::add_ip6_mapped { 'main': }
}

node 'sodium.wikimedia.org' {
    role(mirrors)
    interface::add_ip6_mapped { 'main': }
}

node /^rhodium.eqiad.wmnet/ {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
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

# stat1005 contains all the tools and libraries to access
# the Analytics Cluster services, but should not be used
# for local data processing.
# Testing GPU for T148843
node 'stat1005.eqiad.wmnet' {
    role(statistics::explorer::gpu)
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
    interface::add_ip6_mapped { 'main': }
}

node /^snapshot1007\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_monitor)
    interface::add_ip6_mapped { 'main': }
}

node /^snapshot1008\.eqiad\.wmnet/ {
    role(dumps::generation::worker::dumper_misc_crons_only)
    interface::add_ip6_mapped { 'main': }
}

node 'mwmaint2001.codfw.wmnet' {
    role(mediawiki::maintenance)
    interface::add_ip6_mapped { 'main': }
}

# Thumbor servers for MediaWiki image scaling
node /^thumbor100[1234]\.eqiad\.wmnet/ {
    role(thumbor::mediawiki)
    interface::add_ip6_mapped { 'main': }
}

node /^thumbor200[1234]\.codfw\.wmnet/ {
    role(thumbor::mediawiki)
    interface::add_ip6_mapped { 'main': }
}

# deployment servers
node 'deploy1001.eqiad.wmnet', 'deploy2001.codfw.wmnet' {
    role(deployment_server)
    interface::add_ip6_mapped { 'main': }
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role(xhgui::app)
    interface::add_ip6_mapped { 'main': }
}

# replaced magnesium (RT) (T119112 T123713)
node 'ununpentium.wikimedia.org' {
    role(requesttracker)
    interface::add_ip6_mapped { 'main': }
}

# To see cloudvirt nodes active in the scheduler look at hiera:
#  key: profile::openstack::eqiad1::nova::scheduler_pool
# We try to keep a few empty as emergency fail-overs
#  or transition hosts for maintenance to come
node /^cloudvirt10[0-3][0-9]\.eqiad\.wmnet$/ {
    role(wmcs::openstack::eqiad1::virt)
    interface::add_ip6_mapped { 'main': }
}

# New analytics cloudvirt nodes via T207194
node /^cloudvirtan100[1-5].eqiad.wmnet$/ {
    role(spare::system)
}

# Wikidata query service
node /^wdqs100[4-6]\.eqiad\.wmnet$/ {
    role(wdqs)
    interface::add_ip6_mapped { 'main': }
}

node /^wdqs200[1-3]\.codfw\.wmnet$/ {
    role(wdqs)
    interface::add_ip6_mapped { 'main': }
}

# Wikidata query service internal
node /^wdqs100[378]\.eqiad\.wmnet$/ {
    role(wdqs::internal)
    interface::add_ip6_mapped { 'main': }
}

node /^wdqs200[4-6]\.codfw\.wmnet$/ {
    role(wdqs::internal)
    interface::add_ip6_mapped { 'main': }
}

# Wikidata query service automated deployment
node 'wdqs1009.eqiad.wmnet' {
    role(wdqs::autodeploy)
    interface::add_ip6_mapped { 'main': }
}

# Wikidata query service test
node 'wdqs1010.eqiad.wmnet' {
    role(wdqs::test)
    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main': }
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp10(2[5-9]|[34][0-9])\.eqiad\.wmnet$/ {
    role(parsoid)
    interface::add_ip6_mapped { 'main': }
}

node /^wtp20(0[1-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role(parsoid)
    interface::add_ip6_mapped { 'main': }
}

node default {
    if $::realm == 'production' {
        include ::profile::standard
        interface::add_ip6_mapped { 'main': }
    } else {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require ::role::wmcs::instance
    }
}
