# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first

# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node /^(acamar|achernar)\.wikimedia\.org$/ {
    role(dnsrecursor, ntp)
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# url-downloaders
node /^(alsafi|aluminium)\.wikimedia\.org$/ {
    role(url_downloader)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
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
# meta data associated with those services.
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
        analytics_cluster::oozie::server)

    include ::standard
    include ::base::firewall
}

# analytics1028-analytics1057 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# modules/role/templates/analytics_cluster/hadoop/net-topology.py.erb
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(2[89]|3[0-9]|4[0-9]|5[0-7]).eqiad.wmnet/ {
    role(analytics_cluster::hadoop::worker)

    include ::base::firewall
    include ::standard
}

# analytics1027 hosts hue.wikimedia.org, and is used for launching
# cron based Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {
    role(analytics_cluster::client,
        analytics_cluster::hue,

        # Include a weekly cron job to run hdfs balancer.
        analytics_cluster::hadoop::balancer,

        # Include analytics/refinery deployment target.
        analytics_cluster::refinery,

        # Add cron jobs to run Camus to import data into
        # HDFS from Kafka.
        analytics_cluster::refinery::camus,

        # Add cron job to delete old data in HDFS
        analytics_cluster::refinery::data::drop,

        # We need hive-site.xml in HDFS.  This can be included
        # on any node with a Hive client, but we really only
        # want to include it in one place.  analytics1027
        # is a little special and standalone, so we do it here.
        analytics_cluster::hive::site_hdfs)

    include ::standard
    include ::base::firewall
}

# Analytics Query Service
node /aqs100[456789]\.eqiad\.wmnet/ {
    role(aqs)
}

node 'auth1001.eqiad.wmnet' {
    role(yubiauth::server)
}

node 'auth2001.codfw.wmnet' {
    role(yubiauth::server)
}

node 'baham.wikimedia.org' {
    role(authdns::server)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include ::standard
}

# Bastion in Virginia
node 'bast1001.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
    $cluster = 'misc'
}

# Bastion in Texas
node 'bast2001.wikimedia.org' {
    role(bastionhost::general)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
    $cluster = 'misc'
}

# Bastion in the Netherlands
node 'bast3001.wikimedia.org' {
    role(bastionhost::general,
        prometheus::ops)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }

}

node 'bast3002.wikimedia.org' {
    role(bastionhost::general,
        installserver::tftp)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
    class { '::ganglia::monitor::aggregator': sites =>  'esams', }
}

# Bastion in California
node 'bast4001.wikimedia.org' {
    role(bastionhost::general,
        ipmi::mgmt,
        installserver::tftp,
        prometheus::ops)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }

    class { '::ganglia::monitor::aggregator':
        sites =>  'ulsfo',
    }
}

node 'bohrium.eqiad.wmnet' {
    role(piwik::server)
    include ::standard
}

# virtual machine for static misc. services
node 'bromine.eqiad.wmnet' {
    role(bugzilla::static, microsites::annualreport, microsites::transparency,
        microsites::releases, microsites::endowment)
    include ::standard
}

# Californium hosts openstack-dashboard AKA horizon
# and Tool Labs admin console AKA Striker
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    role(horizon, striker::web, labs::instance_info_dumper)
    include ::standard
    include ::base::firewall
    include ::openstack::horizon::puppetpanel
}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role(restbase::server, cassandra)
}

# DNS recursor
node 'chromium.wikimedia.org' {
    role(dnsrecursor, ntp)
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# New https://www.mediawiki.org/wiki/Gerrit (T147597)
node 'cobalt.wikimedia.org' {
    role(gerrit::server)
}

# conf100x are zookeeper and etcd discovery service nodes in eqiad
node /^conf100[123]\.eqiad\.wmnet$/ {
    role(etcd, zookeeper::server)
    include ::base::firewall
    include ::standard
    if ($::fqdn == 'conf1001.eqiad.wmnet') {
        include ::etcd::auth
        include ::etcd::auth::users
    }
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


    include ::standard
    interface::add_ip6_mapped { 'main': interface => 'eth0', }
    include ::contint::firewall
}

# Debian package/docker images building host in production
node 'copper.eqiad.wmnet' {
    role(builder)
}

# cp1008: prod-like SSL test host
node 'cp1008.wikimedia.org' {
    role(cache::text, authdns::testns)
    interface::add_ip6_mapped { 'main': }
}

node /^cp10(45|5[18]|61)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role(cache::maps, ipsec)
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
    interface::add_ip6_mapped { 'main': }
    role(cache::maps, ipsec)
}

node /^cp20(06|1[28]|25)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node /^cp300[3-6]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::maps, ipsec)
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

node /^cp400[1-4]\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::misc, ipsec)
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::upload, ipsec)
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::text, ipsec)
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role(cache::maps, ipsec)
}

node 'darmstadtium.eqiad.wmnet' {
    role(docker::registry)
}

node 'dataset1001.wikimedia.org' {

    role(dataset::primary, dumps::server)

    interface::add_ip6_mapped { 'eth2':
        interface => 'eth2',
    }
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1052.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's1',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(51|55|57|66|72|73|80|83|89)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's1',
    }
}

# row-based replication to sanitarium2 (T150960)
node 'db1065.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's1',
        binlog_format => 'ROW',
    }
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2016.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's1',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(34|42|48|55|62|69|70)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's1',
        binlog_format => 'ROW',
    }
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1018.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's2',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(21|24|36|54|60|63|67|74|76|90)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's2',
    }
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2017.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's2',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(35|41|49|56|63|64)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's2',
        binlog_format => 'ROW',
    }
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1075.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's3',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(15|35|38|77|78)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's3',
    }
}

# Testing row-based replication to sanitarium2 (T150802)
node 'db1044.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's3',
        binlog_format => 'ROW',
    }
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2018.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's3',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(36|43|50|57)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's3',
        binlog_format => 'ROW',
    }
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1040.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's4',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(53|56|59|68|81|84|91)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's4',
    }
}

# row-based replication to sanitarium2 (T150960)
node 'db1064.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's4',
        binlog_format => 'ROW',
    }
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2019.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's4',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(37|44|51|58|65)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's4',
        binlog_format => 'ROW',
    }
}

# s5 (wikidata/dewiki) core production dbs on eqiad
# eqiad master
node 'db1049.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's5',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(26|45|70|71|82|87|92)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's5',
    }
}

# s5 (wikidata/dewiki) core production dbs on codfw
# codfw master
node 'db2023.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's5',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(38|45|52|59|66)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's5',
        binlog_format => 'ROW',
    }
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1050.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's6',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(22|23|30|37|61|85|88|93)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's6',
    }
}

# s6 core production dbs on codfw
# codfw master
node 'db2028.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's6',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(39|46|53|60|67)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's6',
        binlog_format => 'ROW',
    }
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1041.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's7',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db10(28|33|34|39|62|79|86|94)\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 's7',
    }
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2029.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 's7',
        master        => true,
        binlog_format => 'STATEMENT',
    }
}

node /^db20(40|47|54|61|68)\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 's7',
        binlog_format => 'ROW',
    }
}

## x1 shard
# eqiad
node 'db1031.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'x1',
        master        => true,
        binlog_format => 'ROW',
    }
}

node 'db1029.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'x1',
        binlog_format => 'ROW',
    }
}

# codfw
node 'db2033.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'x1',
        master        => true,
        binlog_format => 'ROW',
    }
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
    role(mariadb::sanitarium2)
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
    role(mariadb::dbstore)
    include ::base::firewall
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
        # zookeeper_cluster_name is set in hiera
        # in hieradata/hosts/druid100*.yaml.  This
        # is a separate druid zookeeper cluster.
        zookeeper::server)

    include ::base::firewall
    include ::standard
}

node 'eeden.wikimedia.org' {
    role(authdns::server)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include ::standard
}

# icinga based monitoring host in eqiad
node 'einsteinium.wikimedia.org' {
    role(icinga, tendril, tcpircbot, certspotter)
}

node /^elastic101[7-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    include ::base::firewall
    include ::standard
}

node /^elastic10[2-4][0-9]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    include ::base::firewall
    include ::standard
}

node /^elastic105[0-2]\.eqiad\.wmnet/ {
    role(elasticsearch::cirrus)
    include ::base::firewall
    include ::standard
}

node /^elastic20[0-3][0-9]\.codfw\.wmnet/ {
    role(elasticsearch::cirrus)
    include ::base::firewall
    include ::standard
}

# External Storage, Shard 1 (es1) databases

## eqiad servers
node /^es101[268]\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard => 'es1',
    }
}

## codfw servers
node /^es201[123]\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 'es1',
        binlog_format => 'ROW',
    }
}

# External Storage, Shard 2 (es2) databases

## eqiad servers
node 'es1011.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'es2',
        master        => true,
        binlog_format => 'ROW',
    }
}

node /^es101[35]\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 'es2',
        binlog_format => 'ROW',
    }
}

## codfw servers
node 'es2016.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'es2',
        master        => true,
        binlog_format => 'ROW',
    }
}

node /^es201[45]\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 'es2',
        binlog_format => 'ROW',
    }
}

# External Storage, Shard 3 (es3) databases

## eqiad servers
node 'es1014.eqiad.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'es3',
        master        => true,
        binlog_format => 'ROW',
    }
}

node /^es101[79]\.eqiad\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 'es3',
        binlog_format => 'ROW',
    }
}

## codfw servers
node 'es2018.codfw.wmnet' {
    class { '::role::mariadb::core':
        shard         => 'es3',
        master        => true,
        binlog_format => 'ROW',
    }
}

node /^es201[79]\.codfw\.wmnet/ {
    class { '::role::mariadb::core':
        shard         => 'es3',
        binlog_format => 'ROW',
    }
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
node /^etcd100[123]\.eqiad\.wmnet$/ {
    role(etcd::kubernetes)
}

# kubernetes masters
node /^(argon|chlorine)\.eqiad\.wmnet$/ {
    role(kubernetes::master)
}

# Etcd cluster for "virtual" networking
node /^etcd100[456]\.eqiad\.wmnet$/ {
    role(etcd::networking)
}

# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    role(etherpad::server)
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
    interface::add_ip6_mapped { 'main': interface => 'eth0', }
}

# EventLogging Analytics does not (yet?) run in codfw.
node 'eventlog2001.codfw.wmnet' {
    include ::standard
    include ::base::firewall
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role(lists::server)
    interface::add_ip6_mapped { 'main': interface => 'eth0' }
}

node 'fluorine.eqiad.wmnet' {
    role(xenon)
    $cluster = 'misc'

    include ::standard

    class { '::role::logging::mediawiki::udp2log':
        monitor       => false,
        log_directory => '/a/mw-log',
    }
}

# ZIM dumps (https://en.wikipedia.org/wiki/ZIM_%28file_format%29)
node 'francium.eqiad.wmnet' {

    role(dumps::zim)
    include ::standard
}

# Virtualization hosts
node /^ganeti[12]00[0-9]\.(codfw|eqiad)\.wmnet$/ {
    role(ganeti)
    include ::standard
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.eqiad.wmnet' {
    role(webperf)

    include ::standard
    include ::base::firewall
}

# debug_proxy hosts; Varnish backend for X-Wikimedia-Debug reqs
node /^(hassaleh|hassium)\.(codfw|eqiad)\.wmnet$/ {
    role(debug_proxy)
    include ::standard
    include ::base::firewall
}

node 'helium.eqiad.wmnet' {
    role(backup::director, backup::storage)

    include ::standard
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    role(backup::storage)
    include ::standard
}

# DNS recursor
node 'hydrogen.wikimedia.org' {
    role(dnsrecursor, ntp)
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# irc.wikimedia.org (replaced argon)
node 'kraz.wikimedia.org' {
    role(mw_rc_irc)

    interface::add_ip6_mapped { 'main': }
}

# labservices1001 hosts openstack-designate, the labs DNS service.
node 'labservices1001.wikimedia.org' {
    role(labs::dns, labs::openstack::designate::server, labs::dnsrecursor,
        labs::dns_floating_ip_updater)
    include ::standard
    include ::base::firewall
    include ::ldap::role::client::labs
}

node 'labservices1002.wikimedia.org' {
    role(labs::dns, labs::openstack::designate::server, labs::dnsrecursor)
    include ::standard
    include ::base::firewall
    include ::ldap::role::client::labs
}

node 'labtestneutron2001.codfw.wmnet' {
    include ::standard
}

node 'labtestvirt2001.codfw.wmnet' {
    role(labs::openstack::nova::compute)
    include ::standard
}

node 'labtestnet2001.codfw.wmnet' {
    role(labs::openstack::nova::api, labs::openstack::nova::network)
    include ::standard
}

node 'labtestmetal2001.codfw.wmnet' {
    include ::standard
    include ::base::firewall
}

node 'labtestcontrol2001.wikimedia.org' {
    include ::standard
    include ::base::firewall
    role(labs::openstack::nova::controller, labs::puppetmaster)

    # Labtest is weird; the mysql server is on labtestcontrol2001.  So
    #  we need some special fw rules to allow that
    $designate = ipresolve(hiera('labs_designate_hostname'),4)
    $horizon = ipresolve(hiera('labs_horizon_host'),4)
    $wikitech = ipresolve(hiera('labs_osm_host'),4)
    $fwrules = {
        mysql_designate => {
            rule  => "saddr ${designate} proto tcp dport (3306) ACCEPT;",
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

node 'labtestservices2001.wikimedia.org' {
    role(labs::dns, labs::openstack::designate::server, labs::dnsrecursor, openldap::labtest,
        labs::dns_floating_ip_updater)
    include ::standard
    include ::base::firewall
}

# Primary graphite machines
node 'graphite1001.eqiad.wmnet' {
    role(graphite::production, statsd, performance::site, graphite::alerts,
        restbase::alerts, graphite::alerts::reqstats, elasticsearch::alerts)
    include ::standard
    include ::base::firewall
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    role(test::system)
    include ::base::firewall
}

# graphite additional machine, for additional space
node 'graphite1003.eqiad.wmnet' {
    role(graphite::production, statsd)
    include ::standard
    include ::base::firewall
}

# Primary graphite machines
node 'graphite2001.codfw.wmnet' {
    role(graphite::production, statsd, performance::site, graphite::alerts,
        restbase::alerts, graphite::alerts::reqstats, elasticsearch::alerts)
    include ::standard
    include ::base::firewall
}

# graphite additional machine, for additional space
node 'graphite2002.codfw.wmnet' {
    role(graphite::production, statsd)
    include ::standard
    include ::base::firewall
}

# replaced carbon and install1001 (T132757)
node 'install1002.wikimedia.org' {
    role(installserver::tftp,
        installserver::dhcp,
        installserver::http,
        installserver::proxy,
        installserver::preseed,
        aptrepo::wikimedia)

    $cluster = 'misc'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    class { '::ganglia::monitor::aggregator':
        sites =>  'eqiad',
    }
}

# replaced carbon and install2001 (T84380, T156440)
node 'install2002.wikimedia.org' {
    role(installserver::tftp,
        installserver::dhcp,
        installserver::http,
        installserver::proxy,
        installserver::preseed,
        aptrepo::wikimedia)

    $cluster = 'misc'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    class { '::ganglia::monitor::aggregator':
        sites =>  'codfw',
    }
}

# Phabricator
node /^(iridium\.eqiad|phab2001\.codfw)\.wmnet$/ {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role(phabricator::main, backup::host)
    include ::standard
    include ::ganglia
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Experimental Yubico two factor authentication bastion',
    }
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
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

node /kubernetes100[1-4].eqiad.wmnet/ {
    role(kubernetes::worker)
    include ::standard
}

node 'labcontrol1001.wikimedia.org' {
    role(labs::openstack::nova::controller,
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
    role(labs::openstack::nova::controller,
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
    role(labs::openstack::nova::manager, mariadb::wikitech, horizon)
    include ::base::firewall
    include ::standard
    include ::openstack::horizon::puppetpanel

    interface::add_ip6_mapped { 'main': }
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role(labs::graphite, grafana::labs)
    include ::standard
    include ::base::firewall
}

node 'labnet1001.eqiad.wmnet' {
    role(labs::openstack::nova::api,
        labs::openstack::nova::network,
        labs::openstack::nova::fullstack)
    include ::standard
}

node 'labnet1002.eqiad.wmnet' {
    role(labs::openstack::nova::api)
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
    role(mariadb::labs)
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
    role(osm::master)
    # include role::labs::db::slave
}

node 'labsdb1007.eqiad.wmnet' {
    $osm_master = 'labsdb1006.eqiad.wmnet'

    role(osm::slave)
    # include role::labs::db::master
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
    role(backup::host, syslog::centralserver)
    include ::standard
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

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include ::lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    # lint:ignore:case_without_default
    case $::hostname {
    # lint:endignore
        /^lvs100[1-3]$/: {
            # Row A subnets on eth0
            interface::tagged { 'eth0.1017':
                base_interface => 'eth0',
                vlan_id        => '1017',
                address        => $ips['private1-a-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
            # Row B subnets on eth1
            interface::tagged { 'eth1.1002':
                base_interface => 'eth1',
                vlan_id        => '1002',
                address        => $ips['public1-b-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            interface::tagged { 'eth1.1018':
                base_interface => 'eth1',
                vlan_id        => '1018',
                address        => $ips['private1-b-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
        /^lvs100[4-6]$/: {
            # Row B subnets on eth0
            interface::tagged { 'eth0.1018':
                base_interface => 'eth0',
                vlan_id        => '1018',
                address        => $ips['private1-b-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
            # Row A subnets on eth1
            interface::tagged { 'eth1.1001':
                base_interface => 'eth1',
                vlan_id        => '1001',
                address        => $ips['public1-a-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            interface::tagged { 'eth1.1017':
                base_interface => 'eth1',
                vlan_id        => '1017',
                address        => $ips['private1-a-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
    }
    # Row C subnets on eth2
    interface::tagged { 'eth2.1003':
        base_interface => 'eth2',
        vlan_id        => '1003',
        address        => $ips['public1-c-eqiad'][$::hostname],
        netmask        => '255.255.255.192',
    }
    interface::tagged { 'eth2.1019':
        base_interface => 'eth2',
        vlan_id        => '1019',
        address        => $ips['private1-c-eqiad'][$::hostname],
        netmask        => '255.255.252.0',
    }
    # Row D subnets on eth3
    interface::tagged { 'eth3.1004':
        base_interface => 'eth3',
        vlan_id        => '1004',
        address        => $ips['public1-d-eqiad'][$::hostname],
        netmask        => '255.255.255.224',
    }
    interface::tagged { 'eth3.1020':
        base_interface => 'eth3',
        vlan_id        => '1020',
        address        => $ips['private1-d-eqiad'][$::hostname],
        netmask        => '255.255.252.0',
    }

    lvs::interface_tweaks {
        'eth0': rss_pattern => 'eth0-%d';
        'eth1': rss_pattern => 'eth1-%d';
        'eth2': rss_pattern => 'eth2-%d';
        'eth3': rss_pattern => 'eth3-%d';
    }
}

node /^lvs10(0[789]|1[012])\.eqiad\.wmnet$/ {

    # lvs1008,11 are LVS balancers for the eqiad recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (chromium and hydrogen) with fallback to codfw
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]

    role(lvs::balancer)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include ::lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    # lint:ignore:case_without_default
    case $::hostname {
    # lint:endignore
        /^lvs100[789]$/: {
            # Row A subnets on eth0
            interface::tagged { 'eth0.1001':
                base_interface => 'eth0',
                vlan_id        => '1001',
                address        => $ips['public1-a-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            # Row C subnets on eth1
            interface::tagged { 'eth1.1003':
                base_interface => 'eth1',
                vlan_id        => '1003',
                address        => $ips['public1-c-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            interface::tagged { 'eth1.1019':
                base_interface => 'eth1',
                vlan_id        => '1019',
                address        => $ips['private1-c-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
        /^lvs101[012]$/: {
            # Row C subnets on eth0
            interface::tagged { 'eth0.1003':
                base_interface => 'eth0',
                vlan_id        => '1003',
                address        => $ips['public1-c-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            # Row A subnets on eth1
            interface::tagged { 'eth1.1001':
                base_interface => 'eth1',
                vlan_id        => '1001',
                address        => $ips['public1-a-eqiad'][$::hostname],
                netmask        => '255.255.255.192',
            }
            interface::tagged { 'eth1.1017':
                base_interface => 'eth1',
                vlan_id        => '1017',
                address        => $ips['private1-a-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
    }
    # Row B subnets on eth2
    interface::tagged { 'eth2.1002':
        base_interface => 'eth2',
        vlan_id        => '1002',
        address        => $ips['public1-b-eqiad'][$::hostname],
        netmask        => '255.255.255.192',
    }
    interface::tagged { 'eth2.1018':
        base_interface => 'eth2',
        vlan_id        => '1018',
        address        => $ips['private1-b-eqiad'][$::hostname],
        netmask        => '255.255.252.0',
    }
    # Row D subnets on eth3
    interface::tagged { 'eth3.1004':
        base_interface => 'eth3',
        vlan_id        => '1004',
        address        => $ips['public1-d-eqiad'][$::hostname],
        netmask        => '255.255.255.224',
    }
    interface::tagged { 'eth3.1020':
        base_interface => 'eth3',
        vlan_id        => '1020',
        address        => $ips['private1-d-eqiad'][$::hostname],
        netmask        => '255.255.252.0',
    }

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
        'eth1': bnx2x => true, txqlen => 10000, rss_pattern => 'eth1-fp-%d';
        'eth2': bnx2x => true, txqlen => 10000, rss_pattern => 'eth2-fp-%d';
        'eth3': bnx2x => true, txqlen => 10000, rss_pattern => 'eth3-fp-%d';
    }
}

# codfw lvs
node /lvs200[1-6]\.codfw\.wmnet/ {
    # lvs200[25] are LVS balancers for the codfw recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (acamar and achernar) with fallback to eqiad
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.153.12', '208.80.153.42', '208.80.154.254' ]
    role(lvs::balancer)

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    include ::lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    # lint:ignore:case_without_default
    case $::hostname {
    # lint:endignore
        /^lvs200[1-3]$/: {
            # Row A subnets on eth0
            interface::tagged { 'eth0.2001':
                base_interface => 'eth0',
                vlan_id        => '2001',
                address        => $ips['public1-a-codfw'][$::hostname],
                netmask        => '255.255.255.224',
            }
            # Row B subnets on eth1
            interface::tagged { 'eth1.2002':
                base_interface => 'eth1',
                vlan_id        => '2002',
                address        => $ips['public1-b-codfw'][$::hostname],
                netmask        => '255.255.255.224',
            }
            interface::tagged { 'eth1.2018':
                base_interface => 'eth1',
                vlan_id        => '2018',
                address        => $ips['private1-b-codfw'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
        /^lvs200[4-6]$/: {
            # Row B subnets on eth0
            interface::tagged { 'eth0.2002':
                base_interface => 'eth0',
                vlan_id        => '2002',
                address        => $ips['public1-b-codfw'][$::hostname],
                netmask        => '255.255.255.224',
            }
            # Row A subnets on eth1
            interface::tagged { 'eth1.2001':
                base_interface => 'eth1',
                vlan_id        => '2001',
                address        => $ips['public1-a-codfw'][$::hostname],
                netmask        => '255.255.255.224',
            }
            interface::tagged { 'eth1.2017':
                base_interface => 'eth1',
                vlan_id        => '2017',
                address        => $ips['private1-a-codfw'][$::hostname],
                netmask        => '255.255.252.0',
            }
        }
    }

    # Row C subnets on eth2
    interface::tagged { 'eth2.2003':
        base_interface => 'eth2',
        vlan_id        => '2003',
        address        => $ips['public1-c-codfw'][$::hostname],
        netmask        => '255.255.255.224',
    }
    interface::tagged { 'eth2.2019':
        base_interface => 'eth2',
        vlan_id        => '2019',
        address        => $ips['private1-c-codfw'][$::hostname],
        netmask        => '255.255.252.0',
    }

    # Row D subnets on eth3
    interface::tagged { 'eth3.2004':
        base_interface => 'eth3',
        vlan_id        => '2004',
        address        => $ips['public1-d-codfw'][$::hostname],
        netmask        => '255.255.255.224',
    }
    interface::tagged { 'eth3.2020':
        base_interface => 'eth3',
        vlan_id        => '2020',
        address        => $ips['private1-d-codfw'][$::hostname],
        netmask        => '255.255.252.0',
    }

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
        'eth1': bnx2x => true, txqlen => 10000, rss_pattern => 'eth1-fp-%d';
        'eth2': bnx2x => true, txqlen => 10000, rss_pattern => 'eth2-fp-%d';
        'eth3': bnx2x => true, txqlen => 10000, rss_pattern => 'eth3-fp-%d';
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

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include ::lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    interface::tagged { 'eth0.100':
        base_interface => 'eth0',
        vlan_id        => '100',
        address        => $ips['public1-esams'][$::hostname],
        netmask        => '255.255.255.128',
    }

    # txqueuelen 20K for 10Gbps LVS in esams:
    # Higher traffic than ulsfo. There is no perfect value based
    #  on hardware alone, but this seems to get rid of common
    #  spiky drops currently in esams.  The real answer is
    #  probably a red or codel variant within each multiqueue
    #  class, but we need a much newer kernel + driver to
    #  be able to do that (both to get good schedulers
    #  and driver updates for XPS).

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 20000, rss_pattern => 'eth0-fp-%d';
    }
}

# ULSFO lvs servers
node /^lvs400[1-4]\.ulsfo\.wmnet$/ {
    # ns override for all lvs for now, see T103921
    $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]

    role(lvs::balancer)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
    }
}

node 'maerlant.wikimedia.org' {
    role(dnsrecursor, ntp)
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'maps-test2001.codfw.wmnet' {
    role(maps::server, maps::master)
}

node /^maps-test200[2-4]\.codfw\.wmnet/ {
    role(maps::server, maps::slave)
}

node 'maps1001.eqiad.wmnet' {
    role(maps::server, maps::master)
}

node /^maps100[2-4]\.eqiad\.wmnet/ {
    role(maps::server, maps::slave)
}

node 'maps2001.codfw.wmnet' {
    role(maps::server, maps::master)
}

node /^maps200[2-4]\.codfw\.wmnet/ {
    role(maps::server, maps::slave)
}

node /^mc10(0[1-9]|1[0-8])\.eqiad\.wmnet/ {
    role(memcached)
}

# First of the new memcached/redis hosts
# that will replace mc1001->mc1018.
# Bug: T137345
node 'mc1019.eqiad.wmnet' {
    role(memcached)
}

# Decommissioned nodes
# T157675
node /^mc20(0[1-9]|1[0-6])\.codfw\.wmnet/ {
    role(spare::system)
}

# New hardware to replace mc2001->mc2016
# T155755
node /^mc20(19|2[0-9]|3[0-6])\.codfw\.wmnet/ {
    role(memcached)
}

# archiva.wikimedia.org
node 'meitnerium.wikimedia.org' {
    $cluster = 'misc'
    role(archiva)
    include ::standard
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role(otrs::webserver)
}

# misc. test server, keep (T156208)
node 'multatuli.wikimedia.org' {
    role(test::system)
    include ::base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# also see dataset1001
node 'ms1001.wikimedia.org' {
    $cluster = 'misc'

    role(dataset::secondary, dumps::server)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'ms1002.eqiad.wmnet' {
    include ::standard
}

# Whenever adding a new node there, you have to ask MediaWiki to recognize the
# new server IP as a trusted proxy so X-Forwarded-For headers are trusted for
# rate limiting purposes (T66622)
node /^ms-fe1001\.eqiad\.wmnet$/ {
    role(swift::proxy, swift::stats_reporter)
    include ::lvs::realserver
}

node /^ms-fe100[2-4]\.eqiad\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

node /^ms-be10(0[0-9]|1[0-5])\.eqiad\.wmnet$/ {
    role(swift::storage)
}

# HP machines have different disk ordering T90922
node /^ms-be10(1[6-9]|2[0-7])\.eqiad\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    role(swift::proxy)
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    role(swift::storage)
}

node /^ms-fe2001\.codfw\.wmnet$/ {
    role(swift::proxy, swift::stats_reporter)
    include ::lvs::realserver
}

node /^ms-fe200[2-8]\.codfw\.wmnet$/ {
    role(swift::proxy)
    include ::lvs::realserver
}

node /^ms-be20(0[0-9]|1[0-5])\.codfw\.wmnet$/ {
    role(swift::storage)
}

# HP machines have different disk ordering T90922
node /^ms-be20(1[6-9]|2[0-7])\.codfw\.wmnet$/ {
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

# mw1170-1188 are apaches
node /^mw11(7[0-9]|8[0-8])\.eqiad\.wmnet$/ {
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

#mw1236-mw1258 are apaches
node /^mw12(3[6-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
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

#mw2090-mw2098, mw2100-mw2117 are appservers
node /^mw2(09[0-8]|10[0-9]|11[0-7])\.codfw\.wmnet$/ {
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

# ROW C codfw appservers: mw2148-mw2234

#mw2148-mw2151 are imagescalers
node /^mw21(4[89]|5[01])\.codfw\.wmnet$/ {
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

# mw logging host codfw
node 'mwlog2001.codfw.wmnet' {
    role(xenon)
    $cluster = 'misc'

    include ::base::firewall
    include ::standard

    class { 'role::logging::mediawiki::udp2log':
        monitor => false,
    }
}

# mw logging host eqiad
node 'mwlog1001.eqiad.wmnet' {
    role(xenon)
    $cluster = 'misc'

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

    interface::ip { 'wiki-mail-eqiad.wikimedia.org_v4':
        interface => 'eth0',
        address   => '208.80.154.91',
        prefixlen => '32',
    }

    interface::ip { 'wiki-mail-eqiad.wikimedia.org_v6':
        interface => 'eth0',
        address   => '2620:0:861:3:208:80:154:91',
        prefixlen => '128',
        # mark as deprecated = never pick this address unless explicitly asked
        options   => 'preferred_lft 0',
    }
}

node 'mx2001.wikimedia.org' {
    role(mail::mx)
    include ::standard
    interface::add_ip6_mapped { 'main': }

    interface::ip { 'wiki-mail-codfw.wikimedia.org_v4':
        interface => 'eth0',
        address   => '208.80.153.46',
        prefixlen => '32',
    }

    interface::ip { 'wiki-mail-codfw.wikimedia.org_v6':
        interface => 'eth0',
        address   => '2620:0:860:2:208:80:153:46',
        prefixlen => '128',
        # mark as deprecated = never pick this address unless explicitly asked
        options   => 'preferred_lft 0',
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

    interface::add_ip6_mapped { 'main':
      interface => 'eth0',
    }
}

node 'nescio.wikimedia.org' {
    role(dnsrecursor, ntp)
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# network monitoring tool server
node 'netmon1001.wikimedia.org' {
    role(rancid::server, librenms, servermon::wmf, torrus, smokeping)
    include ::standard
    include ::passwords::network
    include ::base::firewall

    interface::add_ip6_mapped { 'main': }

    class { '::ganglia::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }
}

node /^(nihal\.codfw|nitrogen\.eqiad)\.wmnet$/ {
    role(puppetmaster::puppetdb)
}

# Offline Content Generator
node /^ocg100[123]\.eqiad\.wmnet$/ {
    role(ocg)
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
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

    include ::base::firewall
}
node 'pc1005.eqiad.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc2',
    }

    include ::base::firewall
}
node 'pc1006.eqiad.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc3',
    }

    include ::base::firewall
}
# codfw
node 'pc2004.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc1',
    }

    include ::base::firewall
}
node 'pc2005.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc2',
    }

    include ::base::firewall
}
node 'pc2006.codfw.wmnet' {
    class { '::role::mariadb::parsercache':
        shard  => 'pc3',
    }

    include ::base::firewall
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]001\.(eqiad|codfw)\.wmnet$/ {
    role(planet::venus)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    role(openldap::corp, backup::host)
    include ::standard
    backup::openldapset {'openldap_oit':}
}

node 'poolcounter1001.eqiad.wmnet' {
    role(poolcounter::server)
    include ::standard
}

node 'poolcounter1002.eqiad.wmnet' {
    role(poolcounter::server)
    include ::standard
}

node /^prometheus200[12]\.codfw\.wmnet$/ {
    role(prometheus::ops, prometheus::global)

    include ::base::firewall
    include ::standard
    include ::lvs::realserver

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^prometheus100[1234]\.eqiad\.wmnet$/ {
    role(prometheus::ops)

    include ::base::firewall
    include ::standard
    include ::lvs::realserver

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^puppetmaster[12]001\.(codfw|eqiad)\.wmnet$/ {
    role(
        ipmi::mgmt, access_new_install,
        puppetmaster::frontend,
        pybal_config
    )
    include ::standard
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^puppetmaster[12]002\.(codfw|eqiad)\.wmnet$/ {
    role(puppetmaster::backend)
    include ::standard
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}


# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[12]\.codfw\.wmnet$/ {
    role(pybaltest)
    include ::standard
}

# pybal-test2003 is used for pybal testing/development
# and for redis multi-instance testing/development
node 'pybal-test2003.codfw.wmnet' {
    role(pybaltest)
    include ::standard

    redis::instance { 6370: }
    redis::instance { 6371: }
}

# Tor relay
node 'radium.wikimedia.org' {
    role(tor::relay)

    include ::base::firewall
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'radon.wikimedia.org' {
    role(authdns::server)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include ::standard
}

# Live Recent Changes WebSocket stream
node 'rcs1001.eqiad.wmnet', 'rcs1002.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role(rcstream)
    include ::base::firewall
}

node /^rdb100[1-9]\.eqiad\.wmnet/ {
    role(jobqueue_redis)
    include ::base::firewall
}

node /^rdb200[1-6]\.codfw\.wmnet/ {
    role(jobqueue_redis)
    include ::base::firewall
}

node /^relforge100[1-2]\.eqiad\.wmnet/ {
    role(elasticsearch::relforge)
    include ::base::firewall
    include ::standard
}

# restbase eqiad cluster
node /^restbase10[01][0-9]\.eqiad\.wmnet$/ {
    role(restbase::server, cassandra)
}

# restbase codfw cluster
node /^restbase20[01][0-9]\.codfw\.wmnet$/ {
    role(restbase::server, cassandra)
}

# cassandra multi-dc temporary test T111382
node /^restbase-test200[1-3]\.codfw\.wmnet$/ {
    role(restbase::server, cassandra)
}

# cassandra/restbase dev cluster
node /^restbase-dev100[1-3]\.eqiad\.wmnet$/ {
    role(restbase::server, cassandra)
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role(pmacct)
}

# people.wikimedia.org, for all shell users
node 'rutherfordium.eqiad.wmnet' {
    role(microsites::peopleweb, backup::host)
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
# Right now, both rt-server and rt-clients run on the same node
# But, we are likely going to split them into different boxes soon.
node 'ruthenium.eqiad.wmnet' {
    role(test::system,
        parsoid::testing, parsoid::rt_server, parsoid::rt_client,
        parsoid::vd_server, parsoid::vd_client)

}

# cluster management (salt master, cumin master)
node 'sarin.codfw.wmnet' {
    role(cluster::management)

    interface::add_ip6_mapped { 'main':
      interface => 'eth0',
    }
}

# Services 'A'
node /^sca[12]00[1234]\.(eqiad|codfw)\.wmnet$/ {
    role(sca)

    interface::add_ip6_mapped { 'main': }
}

# Services 'B'
node /^scb[12]00[1234]\.(eqiad|codfw)\.wmnet$/ {
    role(scb)

    interface::add_ip6_mapped { 'main': }
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role(openldap::labs, backup::host)
    include ::standard
    include ::base::firewall
    backup::openldapset {'openldap_labs':}
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    role(labs::openstack::nova::manager, mariadb::wikitech)
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
    include ::standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}


node 'thorium.eqiad.wmnet' {
    # thorium is mainly used to host Analytics websites like:
    # - https://stats.wikimedia.org (Wikistats)
    # - https://datasets.wikimedia.org
    # - https://metrics.wikimedia.org (https://metrics.wmflabs.org/ (Wikimetrics))
    # - https://pivot.wikimedia.org (Imply's Pivot UI for Druid data)
    #
    # For a complete and up to date list please check the
    # related role/module.
    #
    # This node is not intended for data processing.
    role(statistics::web,
        analytics_cluster::druid::pivot)


    include ::standard
    include ::base::firewall
}

node 'stat1002.eqiad.wmnet' {
    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    # Include classes needed for storing and crunching
    # private data on stat1002.
    role(statistics::private,
        # stat1002 is also a Hadoop client, and should
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
        analytics_cluster::refinery::data::check,
        # Include analytics/refinery/source guard checks
        analytics_cluster::refinery::guard,

        # Set up a read only rsync module to allow access
        # to public data generated by the Analytics Cluster.
        analytics_cluster::rsyncd,

        # Deploy wikimedia/discovery/analytics repository
        # to this node.
        elasticsearch::analytics)

    include ::standard

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }

    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this on
    # stat1002, but don't run any daemons.
    include ::eventlogging
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

# codfw poolcounters
node /(subra|suhail)\.codfw\.wmnet/ {
    role(poolcounter::server)
    include ::standard
}

# icinga based monitoring host in codfw
node 'tegmen.wikimedia.org' {
    role(icinga, tendril, tcpircbot, certspotter)
}

# https://wikitech.wikimedia.org/wiki/Terbium
node 'terbium.eqiad.wmnet' {
    role(mariadb::maintenance, mediawiki::maintenance, openldap::management)
    include ::role::noc::site
    include ::ldap::role::client::labs
    include ::base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Thumbor servers for MediaWiki image scaling
node /^thumbor100[12].eqiad.wmnet/ {
    role(thumbor::mediawiki)

    include ::standard
    include ::base::firewall
}

# deployment servers
node 'tin.eqiad.wmnet', 'mira.codfw.wmnet' {
    role(deployment::server)
    include ::base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role(test::system, xhgui::app)
    include ::base::firewall
}

# replaced magnesium (RT) (T119112 T123713)
node 'ununpentium.wikimedia.org' {
    role(requesttracker::server)

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

}

# Ganglia Web UI
node 'uranium.wikimedia.org' {
    role(ganglia::web)
    include ::standard
    include ::base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^labvirt100[0-9].eqiad.wmnet/ {
    openstack::nova::partition{ '/dev/sdb': }
    role(labs::openstack::nova::compute)
    include ::standard
}

node /^labvirt101[0-4].eqiad.wmnet/ {
    role(labs::openstack::nova::compute)
    include ::standard
}

# mediawiki maintenance server (like terbium)
node 'wasat.codfw.wmnet' {
    role(mariadb::maintenance, mediawiki::maintenance)
    include ::role::noc::site
    include ::ldap::role::client::labs
    include ::base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
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
    role(backup::host, syslog::centralserver)
    include ::standard
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    role(parsoid)
    include ::standard
}

node /^wtp20(0[1-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role(parsoid)
    include ::standard
}

# T138650 - tools for the security team
node 'zosma.codfw.wmnet' {
    role(security::tools)

    interface::add_ip6_mapped { 'main': interface => 'eth0', }
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
