# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp
unless ($::environment == 'future') {
    import 'realm.pp' # These ones first
}
# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node 'acamar.wikimedia.org' {
    role(dnsrecursor, ntp)

    # use achernar (directly) + eqiad LVS (avoid self-dep)
    $nameservers_override = [ '208.80.153.42', '208.80.154.254' ]

    interface::add_ip6_mapped { 'main': }
}

node 'achernar.wikimedia.org' {
    role(dnsrecursor, ntp)

    # use acamar (directly) + eqiad LVS (avoid self-dep)
    $nameservers_override = [ '208.80.153.12', '208.80.154.254' ]

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
    role(analytics_cluster::hadoop::master,
        analytics_cluster::users,
        # Need druid user and HDFS directories
        analytics_cluster::druid::hadoop)

    include ::standard
    include ::base::firewall
}


# analytics1002 is the Hadoop standby NameNode and ResourceManager.
node 'analytics1002.eqiad.wmnet' {
    role(analytics_cluster::hadoop::standby,
        analytics_cluster::users,
        # analytics1002 is usually inactive, and it has a
        # decent amount of disk space.  We use it to
        # store backups of the analytics_cluster::database::meta
        # (MySQL analytics-meta) instance.  If you move this,
        # make sure /srv/backup/mysql/analytics-meta has
        # enough space to store backups.
        analytics_cluster::database::meta::backup_dest,
        # Need druid user and HDFS directories
        analytics_cluster::druid::hadoop)

    include ::standard
    include ::base::firewall
}

# This node hosts Oozie and Hive servers,
# as well as a MySQL instance that stores
# meta data associated with those and other
# Analytics Cluster services.
#
# This node is also is a launch pad for various cron based Hadoop jobs.
# Many ingestion jobs need a starting point.  Oozie is a great
# Hadoop job scheduler, but it is not better than cron
# for some jobs that need to be launched at regular time
# intervals.  Cron is used for those.  These crons
# do not use local resources, instead, they launch
# Hadoop jobs that run throughout the cluster.
#
node 'analytics1003.eqiad.wmnet' {
    role(analytics_cluster::client,
        analytics_cluster::database::meta,
        # Back up analytics-meta MySQL instance
        # to analytics1002. $dest is configured in
        # hieradata/role/eqiad/analytics_cluster/database/meta/backup.yaml
        analytics_cluster::database::meta::backup,
        analytics_cluster::hive::metastore::database,
        analytics_cluster::oozie::server::database,
        analytics_cluster::hive::metastore,
        analytics_cluster::hive::server,
        analytics_cluster::oozie::server,

        # Include a weekly cron job to run hdfs balancer.
        analytics_cluster::hadoop::balancer,

        # We need hive-site.xml in HDFS.  This can be included
        # on any node with a Hive client, but we really only
        # want to include it in one place.  analytics1003
        # is a little special and standalone, so we do it here.
        analytics_cluster::hive::site_hdfs,

        # Camus crons import data into
        # from Kafka into HDFS.
        analytics_cluster::refinery::job::camus,

        # Various crons that launch Hadoop jobs.
        analytics_cluster::refinery,
        analytics_cluster::refinery::job::data_drop,
        analytics_cluster::refinery::job::project_namespace_map,
        analytics_cluster::refinery::job::sqoop_mediawiki)

    include ::standard
    include ::base::firewall
}

# analytics1028-analytics1068 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# modules/role/templates/analytics_cluster/hadoop/net-topology.py.erb
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(2[89]|3[0-9]|4[0-9]|5[0-9]|6[0-9]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)

    include ::base::firewall
    include ::standard
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

# Bastion in Texas
node 'bast2001.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': }
}

# Bastion in the Netherlands (replaced bast3001)
node 'bast3002.wikimedia.org' {
    role(bastionhost::general,
        installserver::tftp,
        prometheus::ops)

    interface::add_ip6_mapped { 'main': }
    class { '::ganglia::monitor::aggregator': sites =>  'esams', }
}

# Bastion in California
node 'bast4001.wikimedia.org' {
    role(bastionhost::general,
        ipmi::mgmt,
        installserver::tftp,
        prometheus::ops)

    interface::add_ip6_mapped { 'main': }

    class { '::ganglia::monitor::aggregator':
        sites =>  'ulsfo',
    }
}

node 'bohrium.eqiad.wmnet' {
    role(piwik::server)
}

# VM with webserver for misc. static sites
node 'bromine.eqiad.wmnet' {
    role(webserver_misc_static)
}

# Californium hosts openstack-dashboard AKA horizon
# and Tool Labs admin console AKA Striker
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    role(wmcs::openstack::main::horizon,
          horizon,
          striker::web,
          labs::instance_info_dumper)
    include ::standard
    include ::base::firewall
    include ::openstack::horizon::puppetpanel
    include ::ldap::role::client::labs
}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role(restbase::test_cluster)
}

# DNS recursor
node 'chromium.wikimedia.org' {
    role(dnsrecursor, ntp)

    # use hydrogen (directly) + codfw LVS (avoid self-dep)
    $nameservers_override = [ '208.80.154.50', '208.80.153.254' ]

    interface::add_ip6_mapped { 'main': }
}

# All gerrit servers (swap master status in hiera)
node 'cobalt.wikimedia.org', 'gerrit2001.wikimedia.org' {
    role(gerrit::server)

    interface::add_ip6_mapped { 'main': }
}

# conf100x are zookeeper and etcd discovery service nodes in eqiad
node /^conf100[123]\.eqiad\.wmnet$/ {
    role(configcluster)
}

# conf200x are etcd/zookeeper service nodes in codfw
node /^conf200[123]\.codfw\.wmnet$/ {
    role(configcluster)
}

# CI master / CI standby (switch in Hiera)
node /^(contint1001|contint2001)\.wikimedia\.org$/ {
    role(ci::master,
        ci::slave,
        ci::website,
        zuul::merger,
        zuul::server)

    interface::add_ip6_mapped { 'main': }
    include ::contint::firewall
}

# Debian package/docker images building host in production
node 'copper.eqiad.wmnet' {
    role(builder)
}

# cp1008: prod-like SSL test host
node 'cp1008.wikimedia.org' {
    role(cache::canary, authdns::testns)
    interface::add_ip6_mapped { 'main': }
}

node /^cp10(45|5[18]|61)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    # ex-cache_maps, not true spares, earmarked for experimentation...
    role(spare::system)
}

node /^cp10(4[89]|50|6[234]|7[1-4]|99)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
}

node /^cp20(0[147]|1[0369]|23)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
}

node /^cp20(0[258]|1[147]|2[0246])\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    # ex-cache_maps, not true spares, earmarked for experimentation...
    role(spare::system)
}

node /^cp20(06|1[28]|25)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node /^cp300[3-6]\.esams\.wmnet$/ {
    # ex-cache_maps, to be decommed
    role(spare::system)
}

node /^cp30(0[789]|10)\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node 'cp3022.esams.wmnet' {
    include ::standard
}

node /^cp30[34][0123]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
}

node /^cp30[34][4-9]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

#
# ulsfo varnishes
#

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

node /^cp40(0[89]|1[067])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
}

# nginx-lua-prometheus testing on a text node
node 'cp4018.ulsfo.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
    class { 'tlsproxy::prometheus': }
}

# temporary entry for testing new cache node hardware setup...
node 'cp4021.ulsfo.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

# temporary entry for new cache nodes
node /^cp402[2-8]\.ulsfo\.wmnet$/ {
    role(spare::system)
}

node 'darmstadtium.eqiad.wmnet' {
    role(docker::registry)
}

node /^(diadem|dysprosium)\.wikimedia\.org$/ {
    include ::standard
    include ::base::firewall
}

node 'dataset1001.wikimedia.org' {

    role(dataset::primary, dumps::server)

    interface::add_ip6_mapped { 'main': }
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1052.eqiad.wmnet' {
    role(mariadb::core)
}
# eqiad replicas
node /^db10(51|55|65|66|67|72|73|80|83|89)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2048.codfw.wmnet' {
    role(mariadb::core)
}

# codfw replicas
node /^db20(16|34|42|55|62|69|70|71|72)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1054.eqiad.wmnet' {
    role(mariadb::core)
}

# eqiad replicas
node /^db10(18|21|36|60|74|76|90)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# To be decommissioned in T162699
node 'db1024.eqiad.wmnet' {
    role(spare::system)
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2017.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(35|41|49|56|63|64)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1075.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db10(15|35|38|44|77|78)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2018.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(36|43|50|57|74)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1068.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db10(53|56|59|64|81|84|91|97)\.eqiad\.wmnet/ {
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

node /^db20(19|37|44|58|65|73)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s5 (wikidata/dewiki) core production dbs on eqiad
# eqiad master
node 'db1063.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db10(26|45|49|70|71|82|87|92)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s5 (wikidata/dewiki) core production dbs on codfw
# codfw master
node 'db2023.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(38|45|52|59|66|75)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1061.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db10(30|37|50|85|88|93)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# To be decommissioned in T166486
node 'db1023.eqiad.wmnet' {
    role(spare::system)
}

# s6 core production dbs on codfw
# codfw master
node 'db2028.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(39|46|53|60|67)\.codfw\.wmnet/ {
    role(mariadb::core)
}

# To be decommissioned in T163778
node 'db1022.eqiad.wmnet' {
    role(spare::system)
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1062.eqiad.wmnet' {
    role(mariadb::core)
}

node /^db10(28|33|34|39|41|79|86|94)\.eqiad\.wmnet/ {
    role(mariadb::core)
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2029.codfw.wmnet' {
    role(mariadb::core)
}

node /^db20(40|47|54|61|68)\.codfw\.wmnet/ {
    role(mariadb::core)
}

## x1 shard
# eqiad
node 'db1031.eqiad.wmnet' {
    role(mariadb::core)
}

node 'db1029.eqiad.wmnet' {
    role(mariadb::core)
}

# codfw
node 'db2033.codfw.wmnet' {
    role(mariadb::core)
}

## m1 shard

node 'db1016.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
    include ::base::firewall
}

node 'db1001.eqiad.wmnet' {
    class { '::role::mariadb::misc':
        shard  => 'm1',
    }
    include ::base::firewall
}

node 'db2010.codfw.wmnet' {
    class { '::role::mariadb::misc':
        shard => 'm1',
    }
    include ::base::firewall
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
    include ::base::firewall
}

node 'db1048.eqiad.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        shard => 'm3',
    }
    include ::base::firewall
}

node 'db2012.codfw.wmnet' {
    class { '::role::mariadb::misc::phabricator':
        shard => 'm3',
    }
    include ::base::firewall
}

# m4 shard
node 'db1046.eqiad.wmnet' {
    class { '::role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => true,
    }
    include ::base::firewall
}
node 'db1047.eqiad.wmnet' {
    # this slave has an m4 custom replication protocol
    # this slave additionally replicates s1 and s2
    role(mariadb::analytics, mariadb::analytics::custom_repl_slave)
    class { '::role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => false,
    }
    include ::base::firewall
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
    include ::base::firewall
}

# sanitarium
node 'db1069.eqiad.wmnet' {
    role(mariadb::sanitarium)
    include ::base::firewall
}

node 'db1095.eqiad.wmnet' {
    role(mariadb::sanitarium_multisource)
}

node 'db1102.eqiad.wmnet' {
    role(mariadb::sanitarium_multiinstance)
}

# tendril db
node 'db1011.eqiad.wmnet' {
    role(mariadb::tendril)
    include ::base::firewall
}

node 'dbstore1001.eqiad.wmnet' {
    include ::role::mariadb::backup
    # 24h delay on all repl streams
    class { '::role::mariadb::dbstore':
        lag_warn     => 90000,
        lag_crit     => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
    include ::base::firewall
}

node 'dbstore1002.eqiad.wmnet' {
    # this slave has an m4 custom replication protocol
    role(mariadb::dbstore, mariadb::analytics::custom_repl_slave)
    include ::base::firewall
}

node 'dbstore2001.codfw.wmnet' {
    # 24h delay on all repl streams
    class { 'role::mariadb::dbstore2':
        lag_warn     => 90000,
        lag_crit     => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
    include ::base::firewall
}

node 'dbstore2002.codfw.wmnet' {
    role(mariadb::dbstore_multiinstance)
}

# Proxies for misc databases
node /^dbproxy100(1|6)\.eqiad\.wmnet$/ {
    class { '::role::mariadb::proxy::master':
        shard          => 'm1',
        primary_name   => 'db1016',
        primary_addr   => '10.64.0.20',
        secondary_name => 'db1001',
        secondary_addr => '10.64.0.5',
    }
}

node /^dbproxy100(2|7)\.eqiad\.wmnet$/ {
    class { '::role::mariadb::proxy::master':
        shard          => 'm2',
        primary_name   => 'db1020',
        primary_addr   => '10.64.16.9',
        secondary_name => 'db2011',
        secondary_addr => '10.192.0.14',
    }
}

node /^dbproxy100(3|8)\.eqiad\.wmnet$/ {
    class { '::role::mariadb::proxy::master':
        shard          => 'm3',
        primary_name   => 'db1043',
        primary_addr   => '10.64.16.32',
        secondary_name => 'db1048',
        secondary_addr => '10.64.16.37',
    }
}

node /^dbproxy100(4|9)\.eqiad\.wmnet$/ {
    class { '::role::mariadb::proxy::master':
        shard          => 'm4',
        primary_name   => 'db1046',
        primary_addr   => '10.64.16.35',
        secondary_name => 'db1047',
        secondary_addr => '10.64.16.36',
    }
}

node 'dbproxy1005.eqiad.wmnet' {
    class { '::role::mariadb::proxy::master':
        shard          => 'm5',
        primary_name   => 'db1009',
        primary_addr   => '10.64.0.13',
        secondary_name => 'db2030',
        secondary_addr => '10.192.16.18',
    }
}

# labsdb proxies (controling replica service dbs)
node 'dbproxy1010.eqiad.wmnet' {
    class { '::role::mariadb::proxy::master':
        shard          => 'labsdb',
        primary_name   => 'labsdb1009',
        primary_addr   => '10.64.4.14',
        secondary_name => 'labsdb1010',
        secondary_addr => '10.64.37.23',
    }
}

node 'dbproxy1011.eqiad.wmnet' {
    class { '::role::mariadb::proxy::master':
        shard          => 'labsdb',
        primary_name   => 'labsdb1011',
        primary_addr   => '10.64.37.24',
        secondary_name => 'labsdb1010',
        secondary_addr => '10.64.37.23',
    }
}

node /^dbmonitor[12]001\.wikimedia\.org$/ {
    role(tendril)
}


# Analytics Druid servers.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[123].eqiad.wmnet$/ {
    role(analytics_cluster::druid::worker,
        analytics_cluster::hadoop::client,
        analytics_cluster::druid::zookeeper)

    include ::base::firewall
    include ::standard
}

node /^druid100[123].eqiad.wmnet$/ {
    role(spare::system)
    include ::base::firewall
    include ::standard
}



node 'eeden.wikimedia.org' {
    role(authdns::server)

    # use eqiad LVS + codfw LVS (avoid self-dep)
    $nameservers_override = [ '208.80.154.254', '208.80.153.254' ]

    interface::add_ip6_mapped { 'main': }
}

# icinga based monitoring hosts (einsteinium = eqiad, tegmen = codfw)
node 'einsteinium.wikimedia.org', 'tegmen.wikimedia.org' {
    role(icinga, tcpircbot, certspotter)
    interface::add_ip6_mapped { 'main': }
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
node 'es2018.codfw.wmnet' {
    role(mariadb::core)
}

node /^es201[79]\.codfw\.wmnet/ {
    role(mariadb::core)
}

# Disaster recovery hosts for external storage
# These nodes are temporarilly up until we get proper
# storage on the backup system
node 'es2001.codfw.wmnet' {
    role(mariadb::otrsbackups)
    include ::standard
    include ::base::firewall
    # temporary measure until mysql is uninstalled
    include ::mariadb::mysqld_safe
}

node /^es200[234]\.codfw\.wmnet/ {
    include ::standard
    include ::base::firewall
    # temporary measure until mysql is uninstalled
    include ::mariadb::mysqld_safe
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
    role(eventlogging::analytics::zeromq,
        eventlogging::analytics::processor,
        eventlogging::analytics::mysql,
        eventlogging::analytics::files,
        logging::mediawiki::errors)

    include ::standard
    include ::base::firewall
    interface::add_ip6_mapped { 'main': }
}

# EventLogging Analytics does not (yet?) run in codfw.
node 'eventlog2001.codfw.wmnet' {
    include ::standard
    include ::base::firewall
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role(lists)
    interface::add_ip6_mapped { 'main': }
}

# ZIM dumps (https://en.wikipedia.org/wiki/ZIM_%28file_format%29)
node 'francium.eqiad.wmnet' {
    role(dumps::zim)
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
    role(dnsrecursor, ntp)

    # use chromium (directly) + codfw LVS (avoid self-dep)
    $nameservers_override = [ '208.80.154.157', '208.80.153.254' ]

    interface::add_ip6_mapped { 'main': }
}

# irc.wikimedia.org
node 'kraz.wikimedia.org' {
    role(mw_rc_irc)
    interface::add_ip6_mapped { 'main': }
}


node 'labpuppetmaster1001.wikimedia.org' {
    role(labs::puppetmaster::frontend)
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

node 'labpuppetmaster1002.wikimedia.org' {
    role(labs::puppetmaster::backend)
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

# labservices1001 hosts openstack-designate, the labs DNS service.
node 'labservices1001.wikimedia.org' {
    role(wmcs::openstack::main::services,
          labs::dns,
          labs::openstack::designate::server,
          labs::dnsrecursor,
          labs::dns_floating_ip_updater)
    include ::standard
    include ::base::firewall
    include ::ldap::role::client::labs
}

node 'labservices1002.wikimedia.org' {
    role(wmcs::openstack::main::services,
          labs::dns,
          labs::openstack::designate::server,
          labs::dnsrecursor)
    include ::standard
    include ::base::firewall
    include ::ldap::role::client::labs
}

node 'labtestneutron2001.codfw.wmnet' {
    role(wmcs::openstack::labtestn::net)
    include ::standard
}

node /^labtestvirt200[1-3]\.codfw\.wmnet$/ {
    role(wmcs::openstack::labtest::virt,
          labs::openstack::nova::compute)
    include ::standard
}

node 'labtestnet2001.codfw.wmnet' {
    role(wmcs::openstack::labtest::net,
          labs::openstack::nova::api,
          labs::openstack::nova::network)
    include ::standard
}

node 'labtestcontrol2001.wikimedia.org' {
    include ::standard
    include ::base::firewall
    role(wmcs::openstack::labtest::control,
          labs::openstack::nova::controller,
          labs::puppetmaster)

    # Labtest is weird; the mysql server is on labtestcontrol2001.  So
    #  we need some special fw rules to allow that
    $designate = ipresolve(hiera('labs_designate_hostname'),4)
    $horizon = ipresolve(hiera('labs_horizon_host'),4)
    $wikitech = ipresolve(hiera('labs_osm_host'),4)
    $puppetmaster = ipresolve('labtestpuppetmaster2001.wikimedia.org',4)
    $fwrules = {
        mysql_designate => {
            rule  => "saddr ${designate} proto tcp dport (3306) ACCEPT;",
        },
        mysql_puppetmaster => {
            rule  => "saddr ${puppetmaster} proto tcp dport (3306) ACCEPT;",
        },
        mysql_horizon => {
            rule  => "saddr ${horizon} proto tcp dport (3306) ACCEPT;",
        },
        mysql_wikitech => {
            rule  => "saddr ${wikitech} proto tcp dport (3306) ACCEPT;",
        },
        labspuppetbackend_horizon => {
            rule  => "saddr ${horizon} proto tcp dport (8100) ACCEPT;",
        },
    }
    create_resources (ferm::rule, $fwrules)

}

node 'labtestcontrol2003.wikimedia.org' {
    role(wmcs::openstack::labtestn::control)
    include ::base::firewall
    include ::standard
}

node 'labtestpuppetmaster2001.wikimedia.org' {
    role(labs::puppetmaster::frontend)
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

node 'labtestservices2001.wikimedia.org' {
    role(wmcs::openstack::labtest::services,
          labs::dns,
          labs::openstack::designate::server,
          labs::dnsrecursor,
          openldap::labtest,
          labs::dns_floating_ip_updater)
    include ::standard
    include ::base::firewall
    interface::add_ip6_mapped { 'main': }
}

node /labtestservices200[23]\.wikimedia\.org/ {
    role(wmcs::openstack::labtestn::services)
    include ::base::firewall
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

node /labweb100[12]\.wikimedia\.org/ {
    role(wmcs::openstack::main::web)
    include ::base::firewall
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

# Primary graphite machines
node 'graphite1001.eqiad.wmnet' {
    role(graphite::production, statsd, performance::site, graphite::alerts,
        restbase::alerts, graphite::alerts::reqstats, elasticsearch::alerts)
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    role(test::system)
}

# graphite additional machine, for additional space
node 'graphite1003.eqiad.wmnet' {
    role(graphite::production, statsd)
}

# Primary graphite machines
node 'graphite2001.codfw.wmnet' {
    role(graphite::production, statsd, performance::site)
}

# graphite additional machine, for additional space
node 'graphite2002.codfw.wmnet' {
    role(graphite::production, statsd)
}

# replaced carbon and install1001/install2001 (T132757, T84380, T156440)
node /^install[12]002\.wikimedia\.org$/ {
    role(installserver::tftp,
        installserver::dhcp,
        installserver::http,
        installserver::proxy,
        installserver::preseed,
        aptrepo::wikimedia)

    interface::add_ip6_mapped { 'main': }

    class { '::ganglia::monitor::aggregator':
        sites => $::site,
    }
}

# Phabricator
node /^(iridium\.eqiad|phab1001\.eqiad|phab2001\.codfw)\.wmnet$/ {
    role(phabricator_server)
    include ::ganglia
    interface::add_ip6_mapped { 'main': }
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Experimental Yubico two factor authentication bastion',
    }
    interface::add_ip6_mapped { 'main': }
    role(bastionhost::twofa, access_new_install)
}

# Analytics Kafka Brokers
node /kafka10(12|13|14|18|20|22)\.eqiad\.wmnet/ {
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    role(kafka::analytics::broker,
        # Mirror all other Kafka cluster data into the analytics Kafka cluster.
        kafka::analytics::mirror,
        ipsec)

    include ::standard
    include ::base::firewall
}

# Kafka Brokers - main-eqiad and main-codfw Kafka clusters.
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka[12]00[123]\.(eqiad|codfw)\.wmnet/ {
    role(kafka::main::broker,
        # Mirror eqiad.* topics from main-eqiad into main-codfw,
        # or mirror codfw.* topics from main-codfw into main-eqiad.
        kafka::main::mirror,
        eventbus::eventbus)

    include ::standard
}

# virtual machine for misc. PHP apps
node 'krypton.eqiad.wmnet' {
    # kafka::analytics::burrow is a Kafka consumer lag monitor.
    # Running this here because krypton is a 'misc' Jessie
    # <s>monitoring host</s> (not really, it's just misc apps)
    role(wikimania_scholarships, iegreview::app, grafana::production,
        kafka::analytics::burrow, racktables::server)
    include ::standard
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
    include ::base::firewall
    include ::standard
}

node 'labcontrol1001.wikimedia.org' {
    role(wmcs::openstack::main::control,
          labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters)

    include ::base::firewall
    include ::standard
    include ::ldap::role::client::labs
}

# labcontrol1002 is a hot spare for 1001.  Switching it on
#  involves uncommenting the dns role, below, and also
#  changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    role(wmcs::openstack::main::control,
          labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters)

    include ::base::firewall
    include ::standard
    include ::ldap::role::client::labs
}

# This is the testlab server that implements both:
#  - silver (wikitech.wikimedia.org), and
#  - californium (horizon.wikimedia.org)
node 'labtestweb2001.wikimedia.org' {
    role(wmcs::openstack::labtest::web,
          labs::openstack::nova::manager,
          mariadb::wikitech,
          horizon)
    include ::base::firewall
    include ::standard
    include ::openstack::horizon::puppetpanel
    include ::ldap::role::client::labs

    interface::add_ip6_mapped { 'main': }
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role(labs::graphite, grafana::labs)
    include ::standard
    include ::base::firewall
}

node 'labnet1001.eqiad.wmnet' {
    role(wmcs::openstack::main::net,
          labs::openstack::nova::api,
          labs::openstack::nova::network,
          labs::openstack::nova::fullstack)
    include ::standard
}

node /labnet1001[34]\.eqiad\.wmnet/ {
    include ::standard
    include ::base::firewall
}


node 'labnet1002.eqiad.wmnet' {
    role(wmcs::openstack::main::net_secondary,
          labs::openstack::nova::api)
    include ::standard
}

node 'labnodepool1001.eqiad.wmnet' {
    $nagios_contact_group = 'admins,contint'
    role(labs::openstack::nodepool)
    include ::standard
    include ::base::firewall
}

## labsdb dbs
node /labsdb100[13]\.eqiad\.wmnet/ {
    # this role is depecated and its nodes scheduled for decom
    role(mariadb::labs_deprecated)
}

node /labsdb10(09|10|11)\.eqiad\.wmnet/ {
    role(labs::db::replica)
}

node 'labsdb1004.eqiad.wmnet' {
    role(postgres::master, labs::db::slave)
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
}

node 'labstore1003.eqiad.wmnet' {
    role(labs::nfs::misc)
    include ::standard
}

node /labstore100[45]\.eqiad\.wmnet/ {
    role(labs::nfs::secondary)
    include ::standard
}

node /labstore200[1-2]\.codfw\.wmnet/ {
    include ::standard
}

node 'labstore2003.codfw.wmnet' {
    role(labs::nfs::secondary_backup::tools)
    include ::standard
}

node 'labstore2004.codfw.wmnet' {
    role(labs::nfs::secondary_backup::misc)
    include ::standard
}

node 'lithium.eqiad.wmnet' {
    role(syslog::centralserver)
}

node /^logstash100[1-2]\.eqiad\.wmnet$/ {
    role(logstash::collector, kibana, logstash::apifeatureusage)
    include ::lvs::realserver
}

node /^logstash1003\.eqiad\.wmnet$/ {
    role(logstash::collector, kibana, logstash::apifeatureusage, logstash::eventlogging)
    include ::lvs::realserver
}
node /^logstash100[4-6]\.eqiad\.wmnet$/ {
    role(logstash::elasticsearch)
}

node /lvs100[1-6]\.wikimedia\.org/ {

    # lvs100[25] are LVS balancers for the eqiad recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (chromium and hydrogen) with fallback to codfw
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]
    role(lvs::balancer)

    lvs::interface_tweaks {
        'eth0':;
        'eth1':;
        'eth2':;
        'eth3':;
    }
}

node /^lvs10(0[789]|10)\.eqiad\.wmnet$/ {

    # lvs1008,10 are LVS balancers for the eqiad recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (chromium and hydrogen) with fallback to codfw
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]

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
    # lvs200[25] are LVS balancers for the codfw recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (acamar and achernar) with fallback to eqiad
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.153.12', '208.80.153.42', '208.80.154.254' ]
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
    # lvs300[24] are LVS balancers for the esams recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (nescio and maerlant) with fallback to eqiad
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '91.198.174.106', '91.198.174.122', '208.80.154.254' ]

    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 20000;
    }
}

# ULSFO lvs servers
node /^lvs400[1-4]\.ulsfo\.wmnet$/ {
    # ns override for all lvs for now, see T103921
    $nameservers_override = [ '208.80.153.12', '208.80.153.42', '208.80.154.254' ]

    role(lvs::balancer)
    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000;
    }
}

node 'maerlant.wikimedia.org' {
    role(dnsrecursor, ntp)

    interface::add_ip6_mapped { 'main': }
}

node 'maps-test2001.codfw.wmnet' {
    role(maps::test::master)
}

node /^maps-test200[2-4]\.codfw\.wmnet/ {
    role(maps::test::slave)
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

node /^mc10(0[1-9]|1[0-8])\.eqiad\.wmnet/ {
    role(spare::system)
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
    include ::standard
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role(otrs)
}

# misc. test server, keep (T156208)
node 'multatuli.wikimedia.org' {
    role(test::system)

    interface::add_ip6_mapped { 'main': }
}

# also see dataset1001
node 'ms1001.wikimedia.org' {

    role(dataset::secondary, dumps::server)

    interface::add_ip6_mapped { 'main': }
}

node 'ms1002.eqiad.wmnet' {
    include ::standard
}

node /^ms-fe1005\.eqiad\.wmnet$/ {
    role(swift::proxy, swift::stats_reporter)
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

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    role(spare::system)
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    role(spare::system)
}

node /^ms-fe2005\.codfw\.wmnet$/ {
    role(swift::proxy, swift::stats_reporter)
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

# mwdebug servers are for mediawiki testing/debugging
# They replace mw1017 and mw1099
node /^mwdebug100[12]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
    include ::base::firewall
}

# mw1161-1167 are job runners
node /^mw116[1-7]\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
    include ::base::firewall
}

# mw1180-1188 are apaches
node /^mw118[0-8]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

# mw1189-1208 are api apaches
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

# mw1209-1216, 1218-1220 are apaches
node /^mw12(09|1[012345689]|20)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

#mw1221-mw1235 are api apaches
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

#mw1238-mw1258 are apaches
node /^mw12(3[8-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

#mw1259-60 are videoscalers
#mw1168-69 were previously jobrunners (T153488)
node /^mw1(16[89]|259|260)\.eqiad\.wmnet/ {
    role(mediawiki::videoscaler)
}

# ROW A eqiad appservers
#mw1261 - mw1275

node /^mw126[1-5]\.eqiad\.wmnet$/ {
    role(mediawiki::canary_appserver)
    include ::base::firewall
}

node /^mw12(6[6-9]|7[0-5])\.eqiad\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

# ROW A eqiad api appserver
# mw1276 - mw1290
node /^mw127[6-9]\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::canary_api)
    include ::base::firewall
}

node /^mw12(8[0-9]|90)\.eqiad\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

# ROW A eqiad imagescalers
node /^mw129[3-8]\.eqiad\.wmnet$/ {
    role(mediawiki::imagescaler)
}

# ROW A eqiad jobrunners
node /^mw1(299|30[0-6])\.eqiad\.wmnet$/ {
    role(mediawiki::jobrunner)
    include ::base::firewall
}

# ROW A codfw appservers: mw2017, mw2075-mw2079, and mw2215-2250

# mw2017/mw2099 are codfw test appservers
node /^mw20(17|99)\.codfw\.wmnet$/ {
    role(mediawiki::canary_appserver)
    include ::base::firewall
}

#mw2097, mw2100-mw2117 are appservers
node /^mw2(097|10[0-9]|11[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

#mw2120-2147 are api appservers
node /^mw21([2-3][0-9]|4[0-7])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
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
    include ::base::firewall
}

#mw2163-mw2199 are appservers
node /^mw21(6[3-9]|[6-9][0-9])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

#mw2200-2214 are api appservers
node /^mw22(0[0-9]|1[0-4])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

# New Appservers, in row A3/A4

#mw2215-2223 are api appservers
node /^mw22(1[5-9]|2[0123])\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

# mw2224-42 are appservers
node /^mw22(2[4-9]|3[0-9]|4[0-2])\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
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
    include ::base::firewall
}

#mw2251-2253 are api-appservers
node /^mw225[1-3]\.codfw\.wmnet$/ {
    role(mediawiki::appserver::api)
    include ::base::firewall
}

#mw2254-2258 are appservers
node /^mw225[4-8]\.codfw\.wmnet$/ {
    role(mediawiki::appserver)
    include ::base::firewall
}

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(xenon)

    include ::base::firewall
    include ::standard

    class { 'role::logging::mediawiki::udp2log':
        monitor => false,
    }
}

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(xenon)

    include ::base::firewall
    include ::standard

    class { 'role::logging::mediawiki::udp2log':
        monitor => false,
    }
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
    # Equivalent of stat1003
    role(paws_internal::jupyterhub, paws_internal::mysql_access)

    include ::standard
}
node 'notebook1002.eqiad.wmnet' {
    # Equivalent to stat1002
    role(paws_internal::jupyterhub, analytics_cluster::client)
    include ::standard
}

# cluster management (salt master, cumin master) + other management tools
node 'neodymium.eqiad.wmnet' {
    role(deployment::salt_masters, debdeploy::master, ipmi::mgmt,
      access_new_install, mgmt::drac_ilo, cluster::management)

    interface::add_ip6_mapped { 'main': }
}

node 'nescio.wikimedia.org' {
    role(dnsrecursor, ntp)

    interface::add_ip6_mapped { 'main': }
}

# network monitoring tools, stretch (T125020, T166180)
node /^netmon(1002|2001)\.wikimedia\.org$/ {
    role(network::monitor, librenms, rancid, smokeping)
    interface::add_ip6_mapped { 'main': }
}

# jessie VM for servermon until it supports stretch (T170653)
node 'netmon1003.wikimedia.org' {
    role(network::monitor, servermon::wmf)
    interface::add_ip6_mapped { 'main': }
}

node /^(nihal\.codfw|nitrogen\.eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
}

# Offline Content Generator
node /^ocg100[123]\.eqiad\.wmnet$/ {
    role(ocg)
}

node /^ores100[1-9]\.eqiad\.wmnet$/ {
    role(ores::stresstest)
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
    role(ores::redis)
    include ::standard
}

node /^oresrdb200[12]\.codfw\.wmnet$/ {
    role(ores::redis)
    include ::standard
}

# VisualEditor performance testing rig
node 'osmium.eqiad.wmnet' {
    role(ve)
    include ::standard
    include ::base::firewall
}

# oxygen runs a kafkatee instance that consumes webrequest from Kafka
# and writes to a couple of files for quick and easy ops debugging.,
node 'oxygen.eqiad.wmnet'
{
    role(logging::kafkatee::webrequest::ops)

    include ::base::firewall
    include ::standard
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
    role(planet_server)
    interface::add_ip6_mapped { 'main': }
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    role(openldap::corp)
    include ::standard
}

node /poolcounter[12]00[12]\.(codfw|eqiad)\.wmnet/ {
    role(poolcounter::server)
}

node /^prometheus200[34]\.codfw\.wmnet$/ {
    role(prometheus::ops, prometheus::global)

    include ::base::firewall
    include ::standard
    include ::lvs::realserver

    interface::add_ip6_mapped { 'main': }
}

node /^prometheus100[34]\.eqiad\.wmnet$/ {
    role(prometheus::ops, prometheus::global)

    include ::lvs::realserver

    interface::add_ip6_mapped { 'main': }
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(
        ipmi::mgmt, access_new_install,
        puppetmaster::frontend,
    )
    include ::standard
    interface::add_ip6_mapped { 'main': }
}

node /^puppetmaster[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
    interface::add_ip6_mapped { 'main': }
}


# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    role(pybaltest)
    include ::standard
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
node /^releases[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(releases)
    interface::add_ip6_mapped { 'main': }
}

node /^relforge100[1-2]\.eqiad\.wmnet/ {
    role(elasticsearch::relforge)
}

# restbase eqiad cluster
node /^restbase10[01][0-9]\.eqiad\.wmnet$/ {
    role(restbase::production)
}

# restbase codfw cluster
node /^restbase20[01][0-9]\.codfw\.wmnet$/ {
    role(restbase::production)
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
    role(pmacct)
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
    role(test::system,
        parsoid::testing, parsoid::rt_server, parsoid::rt_client,
        parsoid::vd_server, parsoid::vd_client, parsoid::diffserver)
}

# cluster management (salt master, cumin master)
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
    include ::standard
    include ::base::firewall
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    role(wmcs::openstack::main::wikitech,
          labs::openstack::nova::manager,
          mariadb::wikitech)
    include ::base::firewall
    include ::standard

    interface::add_ip6_mapped { 'main': }
}

node 'sodium.wikimedia.org' {
    role(mirrors)
    include ::standard

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
    role(statistics::web,
        analytics_cluster::druid::pivot,
        analytics_cluster::hue)


    include ::standard
    include ::base::firewall
}

# Failoid service (Ganeti VM)
node 'tureis.codfw.wmnet' {
    role(failoid)
}

# stat1002 is intended to be the private data analytics compute node.
# Users should not use it for app development.
# Data processing on this machine is fine.
# NOTE: This node is being deprecated and decomissioned as part of T152712.
node 'stat1002.eqiad.wmnet' {
    role(
        # This is also a Hadoop client, and should
        # have any special analytics system users on it
        # for interacting with HDFS.
        analytics_cluster::users,

        # Include Hadoop and other analytics cluster
        # clients so that analysts can access Hadoop
        # from here.
        analytics_cluster::client,

        # Include analytics/refinery deployment target.
        analytics_cluster::refinery,

        # Include analytics/refinery checks that send email about
        # webrequest partitions faultyness.
        # MOVED TO stat1005
        # analytics_cluster::refinery::job::data_check,

        # Include analytics/refinery/source guard checks
        # Disabled due to T166937
        # analytics_cluster::refinery::job::guard,

        # Deploy wikimedia/discovery/analytics repository
        # to this node.
        elasticsearch::analytics)

    include ::standard
}

# stat1003 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1003.eqiad.wmnet' {
    role(statistics::cruncher)
}

node 'stat1004.eqiad.wmnet' {
    # stat1004 contains all the tools and libraries to access
    # the Analytics Cluster services.

    role(analytics_cluster::client, analytics_cluster::refinery)

    include ::standard
}

# WIP: stat1002 replacement (T152712)
node 'stat1005.eqiad.wmnet' {
    role(statistics::private,
        # This is a Hadoop client, and should
        # have any special analytics system users on it
        # for interacting with HDFS.
        analytics_cluster::users,

        # Include Hadoop and other analytics cluster
        # clients so that analysts can access Hadoop
        # from here.
        analytics_cluster::client,

        # Include analytics/refinery deployment target.
        analytics_cluster::refinery,

        # Include analytics/refinery checks that send email about
        # webrequest partitions faultyness.
        analytics_cluster::refinery::job::data_check,

        # Include analytics/refinery/source guard checks
        # Disabled due to T166937
        # analytics_cluster::refinery::job::guard,

        # Set up a read only rsync module to allow access
        # to public data generated by the Analytics Cluster.
        analytics_cluster::rsyncd,

        # Deploy wikimedia/discovery/analytics repository
        # to this node.
        elasticsearch::analytics)
}

# stat1006 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
# WIP: stat1003 replacement (T152712)
node 'stat1006.eqiad.wmnet' {
    role(statistics::cruncher)
}


node /^snapshot1001\.eqiad\.wmnet/ {
    role(snapshot::testbed)
    include ::standard
}

node /^snapshot100[5-7]\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera/common.yaml:dataset_clients_snapshots,
    # hieradata/hosts/ with a file named after the host,
    # and modules/scap/files/dsh/group/mediawiki-installation
    role(snapshot::dumper, snapshot::monitor, snapshot::cronrunner)
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
    role(test::system, xhgui::app)
}

# replaced magnesium (RT) (T119112 T123713)
node 'ununpentium.wikimedia.org' {
    role(requesttracker_server)
    interface::add_ip6_mapped { 'main': }
}

# Ganglia Web UI
node 'uranium.wikimedia.org' {
    role(ganglia::web)
    interface::add_ip6_mapped { 'main': }
}

node /^labvirt100[0-9].eqiad.wmnet/ {
    openstack::nova::partition{ '/dev/sdb': }
    role(wmcs::openstack::main::virt,
          labs::openstack::nova::compute)
    include ::standard
}

# As of 2017-07, labvirt1016, 1017 and 1018
#  are puppetized and active but de-pooled
#  (as per novaconfig::scheduler_pool).
# They're kept empty as emergency fail-overs
#  and also as potential transitional hosts
#  during the upcoming neutron migration.
node /^labvirt101[0-8].eqiad.wmnet/ {
    role(wmcs::openstack::main::virt,
          labs::openstack::nova::compute)
    include ::standard
}

# Wikidata query service
node /^wdqs100[1-3]\.eqiad\.wmnet$/ {
    role(wdqs)
    include ::lvs::realserver
}

node /^wdqs200[1-3]\.codfw\.wmnet$/ {
    role(wdqs)
    include ::lvs::realserver
}

node 'wezen.codfw.wmnet' {
    role(syslog::centralserver)
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    role(parsoid)
}

node /^wtp20(0[1-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role(parsoid)
}

# T138650 - tools for the security team
node 'zosma.codfw.wmnet' {
    role(security::tools)
    interface::add_ip6_mapped { 'main': }
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
