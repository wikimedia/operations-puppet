# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp
# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if !defined('$cluster') {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node 'acamar.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node 'achernar.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

# url-downloaders
node /^(actinium|alcyone|alsafi|aluminium)\.wikimedia\.org$/ {
    role(url_downloader)
    interface::add_ip6_mapped { 'main': }
}

# analytics1001 is the Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'analytics1001.eqiad.wmnet' {
    role(analytics_cluster::hadoop::master)
}


# analytics1002 is the Hadoop standby NameNode and ResourceManager.
node 'analytics1002.eqiad.wmnet' {
    role(analytics_cluster::hadoop::standby)
}

node 'analytics1003.eqiad.wmnet' {
    role(analytics_cluster::coordinator)
}

# analytics1028-analytics1068 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# modules/role/templates/analytics_cluster/hadoop/net-topology.py.erb
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(2[89]|3[0-9]|4[0-9]|5[0-9]|6[0-9]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)
}

# Analytics Query Service
node /aqs100[456789]\.eqiad\.wmnet/ {
    role(aqs)
}

node 'auth1001.eqiad.wmnet' {
    role('yubiauth_server')
}

node 'auth2001.codfw.wmnet' {
    role('yubiauth_server')
}

node 'baham.wikimedia.org' {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

# Bastion in Virginia
node 'bast1001.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

#bast1001 replacement, see T186623
node 'bast1002.wikimedia.org' {
    role(spare::system)
}


# Bastion in Texas
node 'bast2001.wikimedia.org' {
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
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

node 'bast4002.wikimedia.org' {
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

node 'bast5001.wikimedia.org' {
    role(bastionhost::pop)

    interface::add_ip6_mapped { 'main': }
}

node 'bohrium.eqiad.wmnet' {
    role(piwik)
}

# VM with webserver for misc. static sites
node 'bromine.eqiad.wmnet' {
    role(webserver_misc_static)
}

# Californium hosts openstack-dashboard AKA horizon
# and Toolforge admin console AKA Striker
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    role(wmcs::web_interfaces)
    interface::add_ip6_mapped { 'main': }
}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role(restbase::test_cluster)
}

# DNS recursor
node 'chromium.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

# All gerrit servers (swap master status in hiera)
node 'cobalt.wikimedia.org', 'gerrit2001.wikimedia.org' {
    role(gerrit)

    interface::add_ip6_mapped { 'main': }
}

# conf100x are zookeeper and etcd discovery service nodes in eqiad
node /^conf100[123]\.eqiad\.wmnet$/ {
    role(configcluster)
}

# coming soon, see T166081
node /^conf100[456]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# conf200x are etcd/zookeeper service nodes in codfw
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
node 'cp1008.wikimedia.org' {
    role(cache::canary)
    include ::role::authdns::testns
    interface::add_ip6_mapped { 'main': }
}

node /^cp10(45|5[18]|61)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc)
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    # ex-cache_maps, earmarked for experimentation...
    role(test)
}

node /^cp10(4[89]|50|6[234]|7[1-4]|99)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp20(0[147]|1[0369]|23)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp20(0[258]|1[147]|2[0246])\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    # ex-cache_maps, earmarked for experimentation...
    role(test)
}

node /^cp20(06|1[28]|25)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc)
}

node /^cp300[3-6]\.esams\.wmnet$/ {
    # ex-cache_maps, to be decommed
    role(spare::system)
}

node /^cp30(0[789]|10)\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc)
}

node 'cp3022.esams.wmnet' {
    include ::standard
}

node /^cp30[34][0123]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text)
}

node /^cp30[34][4-9]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload)
}

#
# ulsfo varnishes
#

node /^cp40(09|1[078])\.ulsfo\.wmnet$/ {
    # To be decommed - T178801
    role(spare::system)
}

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

node 'darmstadtium.eqiad.wmnet' {
    role(docker::registry)
}

node 'dataset1001.wikimedia.org' {
    role(dumps::web::xmldumps_active)
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1052.eqiad.wmnet' {
    role(mariadb::core)
}
# eqiad replicas
node /^db10(65|66|67|73|80|83|89)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2048.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
node /^db20(42|55|62|69|70|71|72)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1054.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
node /^db1(053|060|074|076|090)\.eqiad\.wmnet/ {
    role(mariadb::core)
}


# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2035.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(41|49|56|63|64)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1075.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db1(072|077|078)\.eqiad\.wmnet/ {
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

node /^db1(064|081|084|091|111|112)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# row-based replication to sanitarium (T150960)
node 'db1064.eqiad.wmnet' {
    role(mariadb::core)
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2051.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(37|44|58|65|73)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki) core production dbs on eqiad
# eqiad master
node 'db1070.eqiad.wmnet' {
    role(mariadb::core)
}

# See also db1096 and db1097 below
node /^db1(051|082|100|106|110)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s5 (dewiki) core production dbs on codfw
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

# See also db1096 and db1098 below
node /^db10(63|85|88|93)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# To be decommissioned T184397
node 'db1030.eqiad.wmnet' {
    role(spare::system)
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

node /^db10(69|79|86|94)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# To be decommissioned T182556
node 'db1034.eqiad.wmnet' {
    role(spare::system)
}

# To be decommissioned T184262
node 'db1039.eqiad.wmnet' {
    role(spare::system)
}

#
# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2040.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(47|54|61|68|77)\.codfw\.wmnet/ {
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
node /^db1(096|097|098|099|101|103|105)\.eqiad\.wmnet/ {
    role(mariadb::core_multiinstance)
}
node /^db20(84|85|86|87|88|89|91)\.codfw\.wmnet/ {
    role(mariadb::core_multiinstance)
}

# pending to be provisioned T170662
node 'db2092.codfw.wmnet' {
    role(spare::system)
}


# pending to be provisioned T184161
node 'db1113.eqiad.wmnet' {
    role(spare::system)
}

node 'db1114.eqiad.wmnet' {
    role(spare::system)
}

## x1 shard
# eqiad
node 'db1055.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1056.eqiad.wmnet' {
    role(mariadb::core)
}

# To be decommissioned T184054
node 'db1029.eqiad.wmnet' {
    role(spare::system)
}
node 'db1031.eqiad.wmnet' {
    role(spare::system)
}

# codfw
node 'db2033.codfw.wmnet' {
    role(mariadb::core)
}

node 'db2034.codfw.wmnet' {
    role(mariadb::core)
}

## m1 shard

node 'db1016.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
}

node 'db1001.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
    }
}

node 'db2078.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm1',
    }
}

## m2 shard
node 'db1020.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm2',
        master => true,
    }
}

node 'db2011.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm2',
    }
}

## m3 shard
node 'db1043.eqiad.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        shard  => 'm3',
        master => true,
    }
}

node 'db1059.eqiad.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        shard => 'm3',
    }
}

node 'db2012.codfw.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        shard => 'm3',
    }
}

# m4 shard

node 'db1107.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::master)
}

# These replicas have an m4 custom replication protocol.

node 'db1108.eqiad.wmnet' {
    role(mariadb::misc::eventlogging::replica)
}

# m5 shard
node 'db1009.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm5',
        master => true,
    }
}

node 'db2030.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm5',
    }
}

# sanitarium
node 'db1095.eqiad.wmnet' {
    role(mariadb::sanitarium_multisource)
}

node 'db1102.eqiad.wmnet' {
    role(mariadb::sanitarium_multiinstance)
}

# tendril db
node 'db1011.eqiad.wmnet' {
    role(mariadb::tendril)
}

node 'dbstore1001.eqiad.wmnet' {
    role(mariadb::temporary_storage)
}

node 'dbstore1002.eqiad.wmnet' {
    role(mariadb::dbstore)
}

node 'dbstore2001.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
    include ::role::mariadb::backup_mydumper
    # include ::role::mariadb::backup

}

node 'dbstore2002.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

# Proxies for misc databases
node /^dbproxy10(01|02|03|04|05|06|07|08|09)\.eqiad\.wmnet$/ {
    role(mariadb::proxy::master)
}

# labsdb proxies (controling replica service dbs)
node /^dbproxy101[01]\.eqiad\.wmnet$/ {
    role(mariadb::proxy::master)
}

node /^dbmonitor[12]001\.wikimedia\.org$/ {
    role(tendril)
}

# will become a deployment server and fold into deployment stanza with tin/naos T175288
node 'deploy1001.eqiad.wmnet' {
    role(spare::system)
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

# Druid analytics-eqiad (non public) servers.
# These power internal backends and queries.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[123].eqiad.wmnet$/ {
    role(druid::analytics::worker)
}

# Druid public-eqiad servers.
# These power AQS and wikistats 2.0 and contain non sensitive datasets.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[456].eqiad.wmnet$/ {
    role(druid::public::worker)
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

node 'eeden.wikimedia.org' {
    role(authdns::server)

    # use eqiad LVS + codfw LVS (avoid self-dep)
    # TODO: this was probably wrong, and surely has no effect on the catalog. Remove?
    $nameservers_override = [ '208.80.154.254', '208.80.153.254' ]

    interface::add_ip6_mapped { 'main': }
}

# icinga based monitoring hosts (einsteinium = eqiad, tegmen = codfw)
node 'einsteinium.wikimedia.org', 'tegmen.wikimedia.org' {
    role(alerting_host)
}

node /^elastic101[7-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic10[2-4][0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic105[0-2]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
}

node /^elastic20[0-3][0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
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
node 'es1011.eqiad.wmnet' {
    role(mariadb::core)
}

node /^es101[35]\.eqiad\.wmnet/ {
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
node 'es1014.eqiad.wmnet' {
    role(mariadb::core)
}

node /^es101[79]\.eqiad\.wmnet/ {
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
# These nodes are temporarilly up until we get proper
# storage on the backup system
node 'es2001.codfw.wmnet' {
    role(mariadb::otrsbackups)
}

node /^es200[234]\.codfw\.wmnet/ {
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
node 'eventlog1001.eqiad.wmnet' {
    role(eventlogging::analytics)
}

node 'eventlog1002.eqiad.wmnet' {
    role(spare::system)
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

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.eqiad.wmnet' {
    role(webperf)
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

# DNS recursor
node 'hydrogen.wikimedia.org' {
    role(recursor)
    interface::add_ip6_mapped { 'main': }
}

# irc.wikimedia.org
node 'kraz.wikimedia.org' {
    role(mw_rc_irc)
    interface::add_ip6_mapped { 'main': }
}


node 'labpuppetmaster1001.wikimedia.org' {
    role(wmcs::openstack::main::puppetmaster::frontend)
    interface::add_ip6_mapped { 'main': }
}

node 'labpuppetmaster1002.wikimedia.org' {
    role(wmcs::openstack::main::puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

# labservices1001 hosts openstack-designate
# and the powerdns auth and recursive services for instances.
node 'labservices1001.wikimedia.org' {
    role(wmcs::openstack::main::services_primary)
}

node 'labservices1002.wikimedia.org' {
    role(wmcs::openstack::main::services_secondary)
}

node /^labtestneutron200[1-2]\.codfw.wmnet$/ {
    role(wmcs::openstack::labtestn::net)
}

node /^labtestvirt200[1-2]\.codfw\.wmnet$/ {
    role(wmcs::openstack::labtest::virt)
}

node /^labtestvirt2003\.codfw\.wmnet$/ {
    role(wmcs::openstack::labtestn::virt)
}

node 'labtestmetal2001.codfw.wmnet' {
    role(test)
}

node 'labtestnet2002.codfw.wmnet' {
    role(wmcs::openstack::labtest::net_standby)
}

node 'labtestnet2001.codfw.wmnet' {
    role(wmcs::openstack::labtest::net)
}

node 'labtestcontrol2001.wikimedia.org' {
    role(wmcs::openstack::labtest::control)
}

node 'labtestcontrol2003.wikimedia.org' {
    role(wmcs::openstack::labtestn::control)
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

node /labtestservices200[23]\.wikimedia\.org/ {
    role(wmcs::openstack::labtestn::services)
    interface::add_ip6_mapped { 'main': }
}

node /labweb100[12]\.wikimedia\.org/ {
    role(wmcs::openstack::main::labweb)

    interface::add_ip6_mapped { 'main': }
}

# Primary graphite machines
node 'graphite1001.eqiad.wmnet' {
    role(graphite::primary)
    # TODO: move the roles below to ::role::alerting::host
    include ::role::graphite::alerts
    include ::role::restbase::alerts
    include ::role::graphite::alerts::reqstats
    include ::role::elasticsearch::alerts
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    role(test)
}

# graphite additional machine, for additional space
node 'graphite1003.eqiad.wmnet' {
    role(graphite::production)
}

# Primary graphite machines
node 'graphite2001.codfw.wmnet' {
    role(graphite::primary)
}

# graphite additional machine, for additional space
node 'graphite2002.codfw.wmnet' {
    role(graphite::production)
}

# replaced carbon and install1001/install2001 (T132757, T84380, T156440)
node /^install[12]002\.wikimedia\.org$/ {
    role(installserver)
}

# Phabricator
node /^(phab1001\.eqiad|phab2001\.codfw)\.wmnet$/ {
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

# Analytics Kafka Brokers
node /kafka10(12|13|14|20|22|23)\.eqiad\.wmnet/ {
    role(kafka::analytics)
}

# Kafka Brokers - main-eqiad and main-codfw Kafka clusters.
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka[12]00[123]\.(eqiad|codfw)\.wmnet/ {
    role(kafka::main)
}

# kafka-jumbo is a large general purpose Kafka cluster.
# This cluster exists only in eqiad, and serves various uses, including
# mirroring all data from the main Kafka clusters in both main datacenters.
node /^kafka-jumbo100[1-6]\.eqiad\.wmnet$/ {
    role(kafka::jumbo::broker)
}


# virtual machine for misc. applications
# (as opposed to static sites using 'webserver_misc_static')
#
# profile::wikimania_scholarships - https://scholarships.wikimedia.org/
# profile::iegreview              - https://iegreview.wikimedia.org
# profile::grafana::production    - https://grafana.wikimedia.org
# profile::racktables             - https://racktables.wikimedia.org
# kafka::analytics::burrow is a Kafka consumer lag monitor
node 'krypton.eqiad.wmnet' {
    role(webserver_misc_apps)
    include ::role::kafka::analytics::burrow
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

node /labcontrol100[34]\.wikimedia\.org/ {
    role(test)
}

node 'labcontrol1001.wikimedia.org' {
    role(wmcs::openstack::main::control)
}

# labcontrol1002 is a hot spare for 1001.
#  Switching it on involves changing the values in hiera
#  that trigger 1002 to start designate.
#  Changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    role(wmcs::openstack::main::control)
}

# This is the labtest server that implements both:
#  - silver (wikitech.wikimedia.org), and
#  - californium (horizon.wikimedia.org)
node 'labtestweb2001.wikimedia.org' {
    role(wmcs::openstack::labtest::web)
    include ::role::mariadb::wikitech

    interface::add_ip6_mapped { 'main': }
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role(labs::monitoring)
}

# role spare until pushed into service via T165784
node 'labmon1002.eqiad.wmnet' {
    role(spare::system)
}

node 'labnet1001.eqiad.wmnet' {
    role(wmcs::openstack::main::net)
}

# role spare until pushed into service via T165779
node /labnet100[34]\.eqiad\.wmnet/ {
    role(spare::system)
}


node 'labnet1002.eqiad.wmnet' {
    role(wmcs::openstack::main::net_standby)
}

node 'labnodepool1001.eqiad.wmnet' {
    $nagios_contact_group = 'admins,contint'
    role(wmcs::openstack::main::nodepool)
}

## labsdb dbs
node /labsdb10(09|10|11)\.eqiad\.wmnet/ {
    role(labs::db::replica)
}

node 'labsdb1004.eqiad.wmnet' {
    role(postgres::master)
    include ::role::labs::db::slave
}

node 'labsdb1005.eqiad.wmnet' {
    role(labs::db::master)
}

node 'labsdb1006.eqiad.wmnet' {
    role(osm::slave)
}

node 'labsdb1007.eqiad.wmnet' {
    role(osm::master)
}

node /labstore100[12]\.eqiad\.wmnet/ {
    # soon to be recommissioned in T158196
    include ::standard
    # Do not enable yet
    # include ::base::firewall
}

node 'labstore1003.eqiad.wmnet' {
    role(labs::nfs::misc)
    # Do not enable yet
    # include ::base::firewall
}

node /labstore100[45]\.eqiad\.wmnet/ {
    role(labs::nfs::secondary)
    # Do not enable yet
    # include ::base::firewall
}

node /labstore100[67]\.wikimedia\.org/ {
    role(dumps::distribution::server)
}

node /labstore200[1-2]\.codfw\.wmnet/ {
    include ::standard
    # Do not enable yet
    # include ::base::firewall
}

node 'labstore2003.codfw.wmnet' {
    role(labs::nfs::secondary_backup::tools)
    # Do not enable yet
    # include ::base::firewall
}

node 'labstore2004.codfw.wmnet' {
    role(labs::nfs::secondary_backup::misc)
    # Do not enable yet
    # include ::base::firewall
}

node 'lawrencium.eqiad.wmnet' {
    role(spare::system)
}

node 'lithium.eqiad.wmnet' {
    role(syslog::centralserver)
}

node /^logstash100[4-6]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
}

# logstash collectors (Ganeti VM)
node 'logstash1007.eqiad.wmnet' {
    role(logstash)
    include ::role::logstash::eventlogging
    include ::lvs::realserver
}
node /^logstash100[8-9]\.eqiad\.wmnet$/ {
    role(logstash)
    include ::lvs::realserver
}

node /lvs100[1-6]\.wikimedia\.org/ {
    role(lvs::balancer)

    lvs::interface_tweaks {
        'eth0':;
        'eth1':;
        'eth2':;
        'eth3':;
    }
}

node /^lvs10(0[789]|10)\.eqiad\.wmnet$/ {
    role(lvs::balancer)

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000;
        'eth1': bnx2x => true, txqlen => 10000;
        'eth2': bnx2x => true, txqlen => 10000;
        'eth3': bnx2x => true, txqlen => 10000;
    }
}

node /^lvs101[12]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# codfw lvs
node /lvs200[1-6]\.codfw\.wmnet/ {
    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000;
        'eth1': bnx2x => true, txqlen => 10000;
        'eth2': bnx2x => true, txqlen => 10000;
        'eth3': bnx2x => true, txqlen => 10000;
    }
}

# ESAMS lvs servers
node /^lvs300[1-4]\.esams\.wmnet$/ {
    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 20000;
    }
}

node /^lvs400[1-4]\.ulsfo\.wmnet$/ {
    role(spare::system)
}

# ULSFO lvs servers
node /^lvs400[567]\.ulsfo\.wmnet$/ {
    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000;
    }
}

# EQSIN lvs servers
node /^lvs500[123]\.eqsin\.wmnet$/ {
    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000;
    }
}

node 'maerlant.wikimedia.org' {
    role(recursor)

    interface::add_ip6_mapped { 'main': }
}

node 'maps-test2001.codfw.wmnet' {
    role(maps::test::master)
}

node /^maps-test200[23]\.codfw\.wmnet/ {
    role(maps::test::slave)
}

node 'maps-test2004.codfw.wmnet' {
    role(maps::test::vectortiles_master)
}

node 'maps1001.eqiad.wmnet' {
    role(maps::master)
}

node /^maps100[2-4]\.eqiad\.wmnet/ {
    role(maps::slave)
}

node 'maps2001.codfw.wmnet' {
    role(maps::master)
}

node /^maps200[2-4]\.codfw\.wmnet/ {
    role(maps::slave)
}

node /^mc10(19|2[0-9]|3[0-6])\.eqiad\.wmnet/ {
    role(mediawiki::memcached)
}

node /^mc20(19|2[0-9]|3[0-6])\.codfw\.wmnet/ {
    role(mediawiki::memcached)
}

# archiva.wikimedia.org
node 'meitnerium.wikimedia.org' {
    role(archiva)
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role(otrs)
}

# misc. test server, keep (T156208)
node 'multatuli.wikimedia.org' {
    role(test)

    interface::add_ip6_mapped { 'main': }
}

# also see dataset1001
node 'ms1001.wikimedia.org' {
    role(dumps::web::xmldumps_fallback)
}

node 'ms1002.eqiad.wmnet' {
    include ::standard
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

node /^ms-be101[3-5]\.eqiad\.wmnet$/ {
    role(swift::storage)
}

# HP machines have different disk ordering T90922
node /^ms-be10(1[6-9]|2[0-9]|3[0-9])\.eqiad\.wmnet$/ {
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

node /^ms-be201[3-5]\.codfw\.wmnet$/ {
    role(swift::storage)
}

node /^ms-be20(0[1-9]|1[0-2])\.codfw\.wmnet$/ {
    role(spare::system)
}

# HP machines have different disk ordering T90922
node /^ms-be20(1[6-9]|2[0-9]|3[0-9])\.codfw\.wmnet$/ {
    role(swift::storage)
}


## MEDIAWIKI APPLICATION SERVERS

## DATACENTER: EQIAD

# Debug servers
node /^mwdebug100[12]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

# Hosts to decommission (if any)

# mw1201-1208 are api apaches
node /^mw120[1-8]\.eqiad\.wmnet$/ {
    role(spare::system)
}

# mw1209-1216, 1218-1220 are apaches
node /^mw12(09|1[012345689]|20)\.eqiad\.wmnet$/ {
    role(spare::system)
}

# mw1259-60 are videoscalers
node /^mw12(59|60)\.eqiad\.wmnet/ {
    role(mediawiki::videoscaler)
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


# Imagescalers (mostly obsolete functionality, replaced by thumbor)

# Row B (B6)
node /^mw129[3-8]\.eqiad\.wmnet$/ {
    role(mediawiki::imagescaler)
}

# Jobrunners (now mostly used via changepropagation as a LVS endpoint)

# Row A

# mw1308-mw1311 are in rack A6
node /^mw13(0[89]|1[01])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row B

# mw1299-mw1306 are in rack B6
node /^mw1(299|30[0-6])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Row C

# mw1334-mw1337 are in rack C6
node /^mw133[4-7]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
}

# Videoscalers

# Row A (A6)
node 'mw1307.eqiad.wmnet' {
    role(mediawiki::videoscaler)
}

# Row B (B7)
node 'mw1318.eqiad.wmnet' {
    role(mediawiki::videoscaler)
}

# Row C (C6)
node 'mw1338.eqiad.wmnet' {
    role(mediawiki::videoscaler)
}

## DATACENTER: CODFW

# ROW A codfw appservers: mw2017, mw2075-mw2079, and mw2215-2250

# mw2017/mw2099 are codfw test appservers
node /^mw20(17|99)\.codfw\.wmnet$/ {
    role(mediawiki::canary_appserver)
}

#mw2097, mw2100-mw2117 are appservers
node /^mw2(097|10[0-9]|11[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

#mw2120-2147 are api appservers
node /^mw21([2-3][0-9]|4[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# ROW B codfw appservers

node /^mw211[89]\.codfw\.wmnet$/ {
    role(mediawiki::videoscaler)
}

# ROW C codfw appservers: mw2150-mw2234

#mw2150-mw2151 are imagescalers
node /^mw215[01]\.codfw\.wmnet$/ {
    role(mediawiki::imagescaler)
}

#mw2152 is a videoscaler
node 'mw2152.codfw.wmnet' {
    role(mediawiki::videoscaler)
}

#mw2153-62 are jobrunners
node /^mw21(5[3-9]|6[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

#mw2163-mw2199 are appservers
node /^mw21(6[3-9]|[6-9][0-9])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

#mw2200-2214 are api appservers
node /^mw22(0[0-9]|1[0-4])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# New Appservers, in row A3/A4

#mw2215-2223 are api appservers
node /^mw22(1[5-9]|2[0123])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

# mw2224-42 are appservers
node /^mw22(2[4-9]|3[0-9]|4[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

#mw2244-mw2245 are imagescalers
node /^mw224[45]\.codfw\.wmnet$/ {
    role(mediawiki::imagescaler)
}

# mw2246 is a videoscaler
node 'mw2246.codfw.wmnet' {
    role(mediawiki::videoscaler)
}

# mw2247-2250 are jobrunners
node /^mw22(4[3789]|50)\.codfw\.wmnet$/ {
    role(mediawiki::jobrunner)
}

#mw2251-2253 are api-appservers
node /^mw225[1-3]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
}

#mw2254-2258 are appservers
node /^mw225[4-8]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
}

## END MEDIAWIKI APPLICATION SERVERS

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(logging::mediawiki::udp2log)
    include ::role::xenon
}

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(logging::mediawiki::udp2log)
    include ::role::xenon
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

# Experimental Jupyter notebook servers
node 'notebook1001.eqiad.wmnet' {
    role(paws_internal)
}
#notebook100[34] are new systems being placed into service on T183935
node 'notebook1003.eqiad.wmnet' {
    role(spare::system)
}

node 'notebook1004.eqiad.wmnet' {
    role(spare::system)
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

node /^(nihal\.codfw|nitrogen\.eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
}

# Offline Content Generator - decommissioned, see T177931
node /^ocg100[123]\.eqiad\.wmnet$/ {
    role(spare::system)
}

node /^ores[12]00[1-9]\.(eqiad|codfw)\.wmnet$/ {
    role(ores)
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
    role(ores::redis)
    include ::standard
}

node /^oresrdb200[12]\.codfw\.wmnet$/ {
    role(ores::redis)
    include ::standard
}

# oxygen runs a kafkatee instance that consumes webrequest from Kafka
# and writes to a couple of files for quick and easy ops debugging.,
node 'oxygen.eqiad.wmnet'
{
    role(logging::kafkatee::webrequest::ops)
}

# parser cache databases
# eqiad
node 'pc1004.eqiad.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc1',
    }
}
node 'pc1005.eqiad.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc2',
    }
}
node 'pc1006.eqiad.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc3',
    }
}
# codfw
node 'pc2004.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc1',
    }
}
node 'pc2005.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc2',
    }
}
node 'pc2006.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc3',
    }
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

node /poolcounter[12]00[12]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
}

node /^prometheus200[34]\.codfw\.wmnet$/ {
    role(prometheus)
}

node /^prometheus100[34]\.eqiad\.wmnet$/ {
    role(prometheus)
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::frontend)
}

node /^puppetmaster[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}

node /^puppetdb[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(spare::system)
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

# Tor relay
node 'radium.wikimedia.org' {
    role(tor_relay)
    interface::add_ip6_mapped { 'main': }
}

node 'radon.wikimedia.org' {
    role(authdns::server)
    interface::add_ip6_mapped { 'main': }
}

node /^rdb100[1357]\.eqiad\.wmnet$/ {
    role(jobqueue_redis::master)
}

node /^rdb100[24689]\.eqiad\.wmnet/ {
    role(jobqueue_redis::slave)
}


node /^rdb200[135]\.codfw\.wmnet$/ {
    role(jobqueue_redis::master)
}


node /^rdb200[246]\.codfw\.wmnet/ {
    role(jobqueue_redis::slave)
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
    role(restbase::production_ng)
}

# restbase codfw cluster
node /^restbase20(0[1-9]|1[012])\.codfw\.wmnet$/ {
    role(restbase::production_ng)
}

# cassandra multi-dc temporary test T111382
node /^restbase-test200[1-3]\.codfw\.wmnet$/ {
    role(restbase::test_cluster)
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
node 'rutherfordium.eqiad.wmnet' {
    role(microsites::peopleweb)
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
# Right now, both rt-server and rt-clients run on the same node
# But, we are likely going to split them into different boxes soon.
node 'ruthenium.eqiad.wmnet' {
    role(parsoid::testing)
    include ::role::test
    include ::role::parsoid::rt_server, ::role::parsoid::vd_server
    include ::role::parsoid::rt_client, ::role::parsoid::vd_client
    include ::role::parsoid::diffserver
}

# cluster management (cumin master)
node 'sarin.codfw.wmnet' {
    role(cluster::management)

    interface::add_ip6_mapped { 'main': }
}

# Services 'A'
node /^sca[12]00[1234]\.(eqiad|codfw)\.wmnet$/ {
    role(sca)

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
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    role(wmcs::openstack::main::wikitech)
    include ::role::mariadb::wikitech
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
    # thorium is mainly used to host Analytics websites like:
    # - https://stats.wikimedia.org (Wikistats)
    # - https://analytics.wikimedia.org (Analytics dashboards and datasets)
    # - https://datasets.wikimedia.org (deprecated, redirects to analytics.wm.org/datasets/archive)
    # - https://metrics.wikimedia.org (https://metrics.wmflabs.org/ (Wikimetrics))
    # - https://pivot.wikimedia.org (Imply's Pivot UI for Druid data)
    # - https://hue.wikimedia.org (Hadoop User Experience GUI)
    #
    # For a complete and up to date list please check the
    # related role/module.
    #
    # This node is not intended for data processing.
    role(analytics_cluster::webserver)
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
}

# WIP: stat1002 replacement (T152712)
node 'stat1005.eqiad.wmnet' {
    role(statistics::private)
    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::role::analytics_cluster::users

    # Include Hadoop and other analytics cluster
    # clients so that analysts can access Hadoop
    # from here.
    include ::role::analytics_cluster::client

    # Include analytics/refinery deployment target.
    include ::role::analytics_cluster::refinery

    # Set up a read only rsync module to allow access
    # to public data generated by the Analytics Cluster.
    include ::role::analytics_cluster::rsyncd

    # Deploy wikimedia/discovery/analytics repository
    # to this node.
    include ::role::elasticsearch::analytics
}

# stat1006 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1006.eqiad.wmnet' {
    role(statistics::cruncher)
}


node /^snapshot1001\.eqiad\.wmnet/ {
    role(dumps::generation::worker::testbed)
}

node /^snapshot100[5-6]\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera/common.yaml:dataset_clients_snapshots,
    # hieradata/hosts/ with a file named after the host,
    # and modules/scap/files/dsh/group/mediawiki-installation
    role(dumps::generation::worker::dumper)
}

node /^snapshot1007\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera/common.yaml:dataset_clients_snapshots,
    # hieradata/hosts/ with a file named after the host,
    # and modules/scap/files/dsh/group/mediawiki-installation
    role(dumps::generation::worker::dumper_misc)
}

# mediawiki maintenance servers (https://wikitech.wikimedia.org/wiki/Terbium)
node 'terbium.eqiad.wmnet', 'wasat.codfw.wmnet' {
    role(mediawiki_maintenance)
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
node 'tin.eqiad.wmnet', 'naos.codfw.wmnet' {
    role(deployment_server)
    interface::add_ip6_mapped { 'main': }
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role(xhgui::app)
    include ::role::test
}

# replaced magnesium (RT) (T119112 T123713)
node 'ununpentium.wikimedia.org' {
    role(requesttracker)
    interface::add_ip6_mapped { 'main': }
}

node /^labvirt100[0-9].eqiad.wmnet/ {
    role(wmcs::openstack::main::virt)
    include ::standard
}

# To see labvirt nodes active in the scheduler look at hiera:
#  key: profile::openstack::main::nova::scheduler_pool
# We try to keep a few empty as emergency fail-overs
#  or transition hosts for maintenance to come
node /^labvirt101[0-8].eqiad.wmnet/ {
    role(wmcs::openstack::main::virt)
    include ::standard
}

#labvirt10[19-20] are to run labdb instances, set to spare for now T172538
node /^labvirt10(19|20)\.eqiad\.wmnet$/ {
    role(spare::system)
}

# Wikidata query service
node /^wdqs100[3-5]\.eqiad\.wmnet$/ {
    role(wdqs)
}

node /^wdqs200[1-3]\.codfw\.wmnet$/ {
    role(wdqs)
}

# VMs for performance team replacing hafnium (T179036)
node /^webperf[12]001\.(codfw|eqiad)\.wmnet/ {
    role(test)
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
    } else {
        # Require instead of include so we get NFS and other
        # base things setup properly
        require ::role::labs::instance
    }
}
