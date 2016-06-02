# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first
import 'misc/*.pp'
import 'role/*.pp'

# Base nodes

# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node /^(acamar|achernar)\.wikimedia\.org$/ {
    role dnsrecursor, ntp
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# url-downloader codfw
node 'alsafi.wikimedia.org' {
    role url_downloader
    include standard
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# analytics1001 is the Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'analytics1001.eqiad.wmnet' {
    role analytics_cluster::hadoop::master,
        analytics_cluster::users,
        # Need druid user and HDFS directories
        analytics_cluster::druid::hadoop

    include standard
    include base::firewall
}


# analytics1002 is the Hadoop standby NameNode and ResourceManager.
node 'analytics1002.eqiad.wmnet' {
    role analytics_cluster::hadoop::standby,
        analytics_cluster::users,
        # analytics1002 is usually inactive, and it has a
        # decent amount of disk space.  We use it to
        # store backups of the analytics_cluster::database::meta
        # (MySQL analytics-meta) instance.  If you move this,
        # make sure /srv/backup/mysql/analytics-meta has
        # enough space to store backups.
        analytics_cluster::database::meta::backup_dest,
        # Need druid user and HDFS directories
        analytics_cluster::druid::hadoop

    include standard
    include base::firewall
}

# This node hosts Oozie and Hive servers,
# as well as a MySQL instance that stores
# meta data associated with those services.
node 'analytics1003.eqiad.wmnet' {
    role analytics_cluster::client,
        analytics_cluster::database::meta,
        # Back up analytics-meta MySQL instance
        # to analytics1002. $dest is configured in
        # hieradata/role/eqiad/analytics_cluster/database/meta/backup.yaml
        analytics_cluster::database::meta::backup,
        analytics_cluster::hive::metastore::database,
        analytics_cluster::oozie::server::database,
        analytics_cluster::hive::metastore,
        analytics_cluster::hive::server,
        analytics_cluster::oozie::server

    include standard
    include base::firewall
}

# analytics1028-analytics1057 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# modules/role/templates/analytics_cluster/hadoop/net-topology.py.erb
# to make sure the hostname -> /datacenter/rack/row id is correct.
# This is used for Hadoop network topology awareness.
node /analytics10(2[89]|3[0-9]|4[0-9]|5[0-7]).eqiad.wmnet/ {
    role analytics_cluster::hadoop::worker

    include base::firewall
    include standard
}

# This is an OOW dell.
node 'analytics1015.eqiad.wmnet' {
    role spare
}


# analytics1026 is spare, for now is just an analytics client.
node 'analytics1026.eqiad.wmnet' {
    role analytics_cluster::client
    include standard
}

# analytics1027 hosts hue.wikimedia.org, and is used for launching
# cron based Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {
    role analytics_cluster::client,
        analytics_cluster::hue,

        # Include a weekly cron job to run hdfs balancer.
        analytics_cluster::hadoop::balancer,

        # Include analytics/refinery deployment target.
        analytics_cluster::refinery,

        # Add cron jobs to run Camus to import data into
        # HDFS from Kafka.
        analytics_cluster::refinery::camus,

        # Add cron job to delete old data in HDFS
        analytics_cluster::refinery::data::drop

    include standard
    include base::firewall
}

# Analytics Query Service (RESTBase & Cassandra)
node /aqs100[123]\.eqiad\.wmnet/ {
    role aqs
}

# Analytics Query Service - Testing
# These nodes are not part of the official AQS cluster now because we are
# currently testing Cassandra configurations on top of them. Hiera variables
# have been placed for each host to override the role's default values.
node /aqs100[456]\.eqiad\.wmnet/ {
    role aqs
}


# git.wikimedia.org
node 'antimony.wikimedia.org' {
    role gitblit
    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main': }
}

node 'auth1001.eqiad.wmnet' {
    role yubiauth::server
}

node 'auth2001.codfw.wmnet' {
    role yubiauth::server
}

node 'baham.wikimedia.org' {
    role authdns::server

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
}

# Bastion in Virginia
node 'bast1001.wikimedia.org' {

    role bastionhost::general

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    $cluster = 'misc'
}

# Bastion in Texas
node 'bast2001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost::general
}

# Bastion in California
node 'bast4001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    role bastionhost::general, ipmi, installserver::tftp_server

    class { 'ganglia::monitor::aggregator':
        sites =>  'ulsfo',
    }
}

node 'bohrium.eqiad.wmnet' {
    role piwik::server
    include standard
}

# virtual machine for static misc. services
node 'bromine.eqiad.wmnet' {
    role bugzilla::static, microsites::annualreport, microsites::transparency, microsites::releases, microsites::endowment
    include standard
}

# Californium hosts openstack-dashboard AKA horizon
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    role horizon
    include standard
    include base::firewall
}

# DHCP / TFTP
node 'carbon.wikimedia.org' {
    role installserver, aptrepo::wikimedia
    $cluster = 'misc'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard

    class { 'ganglia::monitor::aggregator':
        sites =>  'eqiad',
    }

}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include standard
}

# cassandra multi-dc temporary test T111382
node /^restbase-test200[1-3]\.codfw\.wmnet$/ {
    role restbase, cassandra
    include standard
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
    if $::hostname == 'chromium' {
        $url_downloader_ip = hiera('url_downloader_ip')
        interface::ip { 'url-downloader':
            interface => 'eth0',
            address   => $url_downloader_ip,
        }
    }
    role dnsrecursor, url_downloader, ntp
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# conf100x are zookeeper and etcd discovery service nodes in eqiad
node /^conf100[123]\.eqiad\.wmnet$/ {
    role etcd, zookeeper::server
    include base::firewall
    include standard
    if ($::fqdn == 'conf1001.eqiad.wmnet') {
        include etcd::auth
        include etcd::auth::users
    }
}

# conf200x are zookeeper service nodes in codfw
# Note: etcd is not running on these machines yet,
# but will be probably done on a later stage.
node /^conf200[123]\.codfw\.wmnet$/ {
    role zookeeper::server
    include standard
    include base::firewall
}

# Debian package building host in production
node 'copper.eqiad.wmnet' {
    role package::builder
    include standard
    include admin
}

# cp1008: prod-like SSL test host
node 'cp1008.wikimedia.org' {
    role cache::text, authdns::testns
    interface::add_ip6_mapped { 'main': }
}

# to be decommed shortly!
node /^cp104[34]\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role spare # to be decommed (T133614)
}

node /^cp10(45|5[18]|61)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::misc, ipsec
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role cache::maps, ipsec
}

node /^cp10(4[89]|50|6[234]|7[1-4]|99)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp20(0[147]|1[0369]|23)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp20(0[258]|1[147]|2[0246])\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::maps, ipsec
}

node /^cp20(06|1[28]|25)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::misc, ipsec
}

node /^cp300[3-6]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::maps, ipsec
}

node /^cp30(0[789]|10)\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::misc, ipsec
}

node /^cp301[1-4]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role spare # to be decommed (T130883)
}

node /^cp301[5678]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role spare # to be decommed (T130883)
}

node /^cp30(19|2[0-2])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role spare # to be decommed (T130883)
}

node /^cp30[34][0123]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp30[34][4-9]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

#
# ulsfo varnishes
#

node /^cp400[1-4]\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::misc, ipsec
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::maps, ipsec
}

node 'dataset1001.wikimedia.org' {

    role dataset::primary, dumps
    include standard
    include base::firewall

    interface::add_ip6_mapped { 'eth2':
        interface => 'eth2',
    }
}

# MariaDB 10

# s1 (enwiki) core production dbs on eqiad
# eqiad master
node 'db1057.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's1',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(51|52|53|55|65|66|72|73|80|83|89)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's1',
    }
    include base::firewall
}

# s1 (enwiki) core production dbs on codfw
# codfw master
node 'db2016.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's1',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(34|42|48|55|62|69|70)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's1',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s2 (large wikis) core production dbs on eqiad
# eqiad master
node 'db1018.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's2',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(21|24|36|54|60|63|67|74|76)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's2',
    }
    include base::firewall
}

# s2 (large wikis) core production dbs on codfw
# codfw master
node 'db2017.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's2',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(35|41|49|56|63|64)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's2',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s3 (default) core production dbs on eqiad
# Lots of tables!
# eqiad master
node 'db1075.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's3',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(15|35|38|44|77|78)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's3',
    }
    include base::firewall
}

# s3 (default) core production dbs on codfw
# codfw master
node 'db2018.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's3',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(36|43|50|57)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's3',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s4 (commons) core production dbs on eqiad
# eqiad master
node 'db1042.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's4',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(19|40|56|59|64|68)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's4',
    }
    include base::firewall
}

# s4 (commons) core production dbs on codfw
# codfw master
node 'db2019.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's4',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(37|44|51|58|65)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's4',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s5 (wikidata/dewiki) core production dbs on eqiad
# eqiad master
node 'db1049.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's5',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(26|45|70|71)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's5',
    }
    include base::firewall
}

# s5 (wikidata/dewiki) core production dbs on codfw
# codfw master
node 'db2023.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's5',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(38|45|52|59|66)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's5',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s6 core production dbs on eqiad
# eqiad master
node 'db1050.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's6',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(22|23|30|37|61)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's6',
    }
    include base::firewall
}

# s6 core production dbs on codfw
# codfw master
node 'db2028.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's6',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(39|46|53|60|67)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's6',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# s7 (centralauth, meta et al.) core production dbs on eqiad
# eqiad master
node 'db1041.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's7',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db10(28|33|34|39|62)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's7',
    }
    include base::firewall
}

# s7 (centralauth, meta et al.) core production dbs on codfw
# codfw master
node 'db2029.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 's7',
        master        => true,
        binlog_format => 'STATEMENT',
    }
    include base::firewall
}

node /^db20(40|47|54|61|68)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 's7',
        binlog_format => 'ROW',
    }
    include base::firewall
}

## x1 shard
# eqiad
node 'db1031.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'x1',
        master        => true,
        binlog_format => 'ROW',
    }
    include base::firewall
}

node /^db10(29)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'x1',
        binlog_format => 'ROW',
    }
    include base::firewall
}

# codfw
node 'db2033.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'x1',
        master        => true,
        binlog_format => 'ROW',
    }
    include base::firewall
}

node /^db20(08|09)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'x1',
        binlog_format => 'ROW',
    }
    include base::firewall
}

## m1 shard
node 'db1001.eqiad.wmnet' {
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

node 'db1016.eqiad.wmnet' {
    class { 'role::mariadb::misc':
        shard  => 'm1',
    }
    include base::firewall
}

node 'db2010.codfw.wmnet' {
    class { 'role::mariadb::misc':
        shard => 'm1',
    }
    include base::firewall
}

## m2 shard
node 'db1020.eqiad.wmnet' {
    class { 'role::mariadb::misc':
        shard  => 'm2',
        master => true,
    }
}

node 'db2011.codfw.wmnet' {
    class { 'role::mariadb::misc':
        shard => 'm2',
    }
}

## m3 shard
node 'db1043.eqiad.wmnet' {
    class { 'role::mariadb::misc::phabricator':
        shard  => 'm3',
        master => true,
    }
    include base::firewall
}

node 'db1048.eqiad.wmnet' {
    class { 'role::mariadb::misc::phabricator':
        shard    => 'm3',
        snapshot => true,
    }
    include base::firewall
}

node 'db2012.codfw.wmnet' {
    class { 'role::mariadb::misc::phabricator':
        shard     => 'm3',
        mariadb10 => true,
        ssl       => 'on',
        p_s       => 'on',
    }
    include base::firewall
}

# m4 shard
node 'db1046.eqiad.wmnet' {
    class { 'role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => true,
    }
    include base::firewall
}
node 'db1047.eqiad.wmnet' {
    # this slave has an m4 custom replication protocol
    role mariadb::analytics::custom_repl_slave
    class { 'role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => false,
    }
    include base::firewall
}

# m5 shard
node 'db1009.eqiad.wmnet' {
    class { 'role::mariadb::misc':
        shard  => 'm5',
        master => true,
    }
}

node 'db2030.codfw.wmnet' {
    class { 'role::mariadb::misc':
        shard => 'm5',
    }
    include base::firewall
}

# sanitarium
node 'db1069.eqiad.wmnet' {
    role mariadb::sanitarium
    include base::firewall
}

# tendril db
node 'db1011.eqiad.wmnet' {
    role mariadb::tendril
    include base::firewall
}

node 'dbstore1001.eqiad.wmnet' {
    include role::mariadb::backup
    # 24h delay on all repl streams
    class { 'role::mariadb::dbstore':
        lag_warn     => 90000,
        lag_crit     => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
    include base::firewall
}

node 'dbstore1002.eqiad.wmnet' {
    # this slave has an m4 custom replication protocol
    role mariadb::dbstore, mariadb::analytics::custom_repl_slave
    include base::firewall
}

node 'dbstore2001.codfw.wmnet' {
    # 24h delay on all repl streams
    class { 'role::mariadb::dbstore':
        lag_warn     => 90000,
        lag_crit     => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
    include base::firewall
}

node 'dbstore2002.codfw.wmnet' {
    role mariadb::dbstore
    include base::firewall
}

node 'dbproxy1001.eqiad.wmnet' {
    class { 'role::mariadb::proxy::master':
        shard          => 'm1',
        primary_name   => 'db1001',
        primary_addr   => '10.64.0.5',
        secondary_name => 'db1016',
        secondary_addr => '10.64.0.20',
    }
}

node 'dbproxy1002.eqiad.wmnet' {
    class { 'role::mariadb::proxy::master':
        shard          => 'm2',
        primary_name   => 'db1020',
        primary_addr   => '10.64.16.9',
        secondary_name => 'db2011',
        secondary_addr => '10.192.0.14',
    }
}

node 'dbproxy1003.eqiad.wmnet' {
    class { 'role::mariadb::proxy::master':
        shard          => 'm3',
        primary_name   => 'db1043',
        primary_addr   => '10.64.16.32',
        secondary_name => 'db1048',
        secondary_addr => '10.64.16.37',
    }
}

node 'dbproxy1004.eqiad.wmnet' {
    class { 'role::mariadb::proxy::master':
        shard          => 'm4',
        primary_name   => 'db1046',
        primary_addr   => '10.64.16.35',
        secondary_name => 'db1047',
        secondary_addr => '10.64.16.36',
    }
}

node 'dbproxy1005.eqiad.wmnet' {
    class { 'role::mariadb::proxy::master':
        shard          => 'm5',
        primary_name   => 'db1009',
        primary_addr   => '10.64.0.13',
        secondary_name => 'db2030',
        secondary_addr => '10.192.16.18',
    }
}

# Analytics Druid servers.
# https://wikitech.wikimedia.org/wiki/Analytics/Data_Lake#Druid
node /^druid100[123].eqiad.wmnet$/ {
    role analytics_cluster::druid::worker,
        analytics_cluster::hadoop::client

    include base::firewall
    include standard
}

node 'eeden.wikimedia.org' {
    role authdns::server

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
}

# neon-like monitoring host in eqiad
node 'einsteinium.wikimedia.org' {
    include standard
    include base::firewall
}

node /^elastic10[0-2][0-9]\.eqiad\.wmnet/ {
    role elasticsearch::server
    include base::firewall
    include standard
}
node /^elastic103[0-1]\.eqiad\.wmnet/ {
    role elasticsearch::server
    include base::firewall
    include standard
}

node /^elastic20[0-3][0-9]\.codfw\.wmnet/ {
    role elasticsearch::server
    include base::firewall
    include standard
}

# External Storage, Shard 1 (es1) databases

## eqiad servers
node /^es101[268]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es1',
        ssl   => 'on'
    }
    include base::firewall
}

## codfw servers
node /^es201[123]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es1',
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

# External Storage, Shard 2 (es2) databases

## eqiad servers
node 'es1015.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'es2',
        master        => true,
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

node /^es101[13]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es2',
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

## codfw servers
node 'es2015.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'es2',
        master        => true,
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

node /^es201[46]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es2',
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

# External Storage, Shard 3 (es3) databases

## eqiad servers
node 'es1019.eqiad.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'es3',
        master        => true,
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

node /^es101[47]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es3',
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

## codfw servers
node 'es2018.codfw.wmnet' {
    class { 'role::mariadb::core':
        shard         => 'es3',
        master        => true,
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

node /^es201[79]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es3',
        binlog_format => 'ROW',
        ssl           => 'on',
    }
    include base::firewall
}

# Disaster recovery hosts for external storage
node /^es200[1234]\.codfw\.wmnet/ {
    include standard
    include base::firewall
}


# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    role etherpad
}

# Receives log data from Kafka processes it, and broadcasts
# to Kafka Schema based topics.
node 'eventlog1001.eqiad.wmnet' {
    role eventlogging,
        eventlogging::forwarder,
        eventlogging::processor,
        eventlogging::consumer::mysql,
        eventlogging::consumer::files,
        logging::mediawiki::errors

    include standard
    include base::firewall
}

# EventLogging Analytics does not (yet?) run in codfw.
node 'eventlog2001.codfw.wmnet' {
    include standard
    include base::firewall
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role lists::server
    include standard
    include admin

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'fluorine.eqiad.wmnet' {
    role xenon
    $cluster = 'misc'

    include standard

    class { 'role::logging::mediawiki':
        monitor       => false,
        log_directory => '/a/mw-log',
    }
}

# ZIM dumps (https://en.wikipedia.org/wiki/ZIM_%28file_format%29)
node 'francium.eqiad.wmnet' {

    role dumps::zim
    include standard
    include admin
}

# git.wikimedia.org (until replaced by Diffusion)
node 'furud.codfw.wmnet' {
    role gitblit
    include standard
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Continuous Integration
node 'gallium.wikimedia.org' {
    role ci::master,
        ci::slave,
        ci::website,
        zuul::merger,
        zuul::server

    # T51846, let us sync VisualEditor in mediawiki/extensions.git
    sudo::user { 'jenkins-slave':
        privileges => [
            'ALL = (jenkins) NOPASSWD: /srv/deployment/integration/slave-scripts/bin/gerrit-sync-ve-push.sh',
        ]
    }

    include standard
    include contint::firewall

    # gallium received a SSD drive (T82401) mount it
    file { '/srv/ssd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }
    mount { '/srv/ssd':
        ensure  => mounted,
        device  => '/dev/sdb1',
        fstype  => 'xfs',
        options => 'noatime,nodiratime,nobarrier,logbufs=8',
        require => File['/srv/ssd'],
    }
}

# Virtualization hosts
node /^ganeti[12]00[0-9]\.(codfw|eqiad)\.wmnet$/ {
    role ganeti
    include standard
    include admin
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.eqiad.wmnet' {
    role webperf

    include standard
    include base::firewall
}

# debug_proxy hosts; Varnish backend for X-Wikimedia-Debug reqs
node /^(hassaleh|hassium)\.(codfw|eqiad)\.wmnet$/ {
    role debug_proxy
    include standard
    include base::firewall
}

# poolcounter - careful
node 'helium.eqiad.wmnet' {
    role poolcounter, backup::director, backup::storage

    include standard
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    role backup::storage
    include standard
}

# irc.wikimedia.org (replaced argon)
node 'kraz.wikimedia.org' {
    role mw_rc_irc

    interface::add_ip6_mapped { 'main': }
}

# labservices1001 hosts openstack-designate, the labs DNS service.
node 'labservices1001.wikimedia.org' {
    role labs::dns, labs::openstack::designate::server, labs::dnsrecursor
    include standard
    include base::firewall
    include ldap::role::client::labs
}

node 'labservices1002.wikimedia.org' {
    role labs::dns, labs::openstack::designate::server, labs::dnsrecursor
    include standard
    include base::firewall
    include ldap::role::client::labs
}

node 'labtestneutron2001.codfw.wmnet' {
    include standard
}

node 'labtestvirt2001.codfw.wmnet' {
    role labs::openstack::nova::compute
    include standard
}

node 'labtestnet2001.codfw.wmnet' {
    role labs::openstack::nova::api, labs::openstack::nova::network
    include standard
}

node 'labtestmetal2001.codfw.wmnet' {
    include standard
}

node 'labtestcontrol2001.wikimedia.org' {
    include standard
    include base::firewall
    role labs::openstack::nova::controller,
          labs::puppetmaster

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
    }
    create_resources (ferm::rule, $fwrules)

}

node 'labtestservices2001.wikimedia.org' {
    role labs::dns, labs::openstack::designate::server, labs::dnsrecursor, openldap::labtest
    include standard
    include base::firewall
}

# bastion in the Netherlands
node 'bast3001.wikimedia.org' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost::general, installserver::tftp_server

    class { 'ganglia::monitor::aggregator':
        sites =>  'esams',
    }
}

# Primary graphite machines
node 'graphite1001.eqiad.wmnet' {
    role graphite::production, statsd, performance::site, graphite::alerts, restbase::alerts, graphite::alerts::reqstats, elasticsearch::alerts
    include standard
    include base::firewall
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    role test::system
    include base::firewall
}

# graphite additional machine, for additional space
node 'graphite1003.eqiad.wmnet' {
    role graphite::production, statsd
    include standard
    include base::firewall
}

# Primary graphite machines
node 'graphite2001.codfw.wmnet' {
    role graphite::production, statsd
    include standard
    include base::firewall
}

# graphite additional machine, for additional space
node 'graphite2002.codfw.wmnet' {
    role graphite::production, statsd
    include standard
    include base::firewall
}

# partially replaces carbon (T132757)
node 'install1001.wikimedia.org' {
    role installserver::tftp_server, aptrepo::wikimedia
    $cluster = 'misc'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
}

node 'install2001.wikimedia.org' {
    role installserver::tftp_server
    $cluster = 'misc'
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard

    class { 'ganglia::monitor::aggregator':
        sites =>  'codfw',
    }
}

# Phabricator
node 'iridium.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role phabricator::main, backup::host
    include standard
    include ganglia
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Experimental Yubico 2fa bastion',
    }
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost::2fa
}

# Analytics Kafka Brokers
node /kafka10(12|13|14|18|20|22)\.eqiad\.wmnet/ {
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    role kafka::analytics::broker, ipsec

    include standard
    include base::firewall
}

# Kafka Brokers - main-eqiad
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka100[12]\.eqiad\.wmnet/ {
    role kafka::main::broker,
        eventbus::eventbus,
        # Temporarly test running kafka mirror maker here.
        # This currently mirrors from main-eqiad to analytics-eqiad.
        kafka::analytics::mirror

    include standard
    include base::firewall
}

# Kafka Brokers - main-codfw
# For now, eventlogging-service-eventbus is also colocated
# on these brokers.
node /kafka200[12]\.codfw\.wmnet/ {
    role kafka::main::broker,
        eventbus::eventbus
    include standard
    include base::firewall
}

# virtual machine for misc. PHP apps
node 'krypton.eqiad.wmnet' {
    # kafka::analytics::burrow is a Kafka consumer lag monitor.
    # Running this here because krypton is a 'misc' Jessie
    # <s>monitoring host</s> (not really, it's just misc apps)
    role wikimania_scholarships, iegreview, grafana, kafka::analytics::burrow, racktables::server
    include standard
}

node 'labcontrol1001.wikimedia.org' {
    role labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters

    include base::firewall
    include standard
    include ldap::role::client::labs
}

# labcontrol1002 is a hot spare for 1001.  Switching it on
#  involves uncommenting the dns role, below, and also
#  changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    role labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters

    include base::firewall
    include standard
    include ldap::role::client::labs
}

# like silver (wikitech.wikimedia.org)
node 'labtestweb2001.wikimedia.org' {
    role labs::openstack::nova::manager, mariadb::wikitech, horizon
    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main': }
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role labs::graphite
    include standard
    include base::firewall
}

node 'labnet1001.eqiad.wmnet' {
    role labs::openstack::nova::api
    include standard
}

node 'labnet1002.eqiad.wmnet' {
    role labs::openstack::nova::api, labs::openstack::nova::network
    include standard
}

node 'labnodepool1001.eqiad.wmnet' {
    $nagios_contact_group = 'admins,contint'
    role labs::openstack::nodepool
    include standard
    include base::firewall
}

## labsdb dbs
node /labsdb100[1238]\.eqiad\.wmnet/ {
    # this role is depecated and should be converted to labs::db::slave
    role mariadb::labs
}

node 'labsdb1004.eqiad.wmnet' {
    # Bug: T101233
    #$postgres_slave = 'labsdb1005.eqiad.wmnet'
    #$postgres_slave_v4 = '10.64.37.9'

    role postgres::master, labs::db::slave
}

node 'labsdb1005.eqiad.wmnet' {
    # Bug: T101233
    # $postgres_master = 'labsdb1004.eqiad.wmnet'
    # include role::postgres::slave
    role labs::db::master
}

node 'labsdb1006.eqiad.wmnet' {
    $osm_slave = 'labsdb1007.eqiad.wmnet'
    $osm_slave_v4 = '10.64.37.12'

    role osm::master
    # include role::labs::db::slave
}

node 'labsdb1007.eqiad.wmnet' {
    $osm_master = 'labsdb1006.eqiad.wmnet'

    role osm::slave
    # include role::labs::db::master
}

node /labstore100[12]\.eqiad\.wmnet/ {
    role labs::nfs::primary
    include standard
}

node 'labstore1003.eqiad.wmnet' {
    role labs::nfs::misc
    include standard
}

node /labstore200[1-2]\.codfw\.wmnet/ {
    role labs::nfs::backup
    include standard
}

node /labstore200[3-4]\.codfw\.wmnet/ {
    role labs::nfs::backup
    include standard
}

# New https://www.mediawiki.org/wiki/Gerrit
node 'lead.wikimedia.org' {
    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::configuration variable 'gerrit_server'
    include standard
    include base::firewall

    role gerrit::production::replicationdest
}

node 'lithium.eqiad.wmnet' {
    role backup::host, syslog::centralserver
    include standard
}

node /^logstash100[1-2]\.eqiad\.wmnet$/ {
    role logstash, kibana, logstash::apifeatureusage
    include base::firewall
}

node /^logstash1003\.eqiad\.wmnet$/ {
    role logstash, kibana, logstash::apifeatureusage, logstash::eventlogging
    include base::firewall
}
node /^logstash100[4-6]\.eqiad\.wmnet$/ {
    role logstash::elasticsearch
    include base::firewall
}

node /lvs100[1-6]\.wikimedia\.org/ {

    # lvs100[25] are LVS balancers for the eqiad recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (chromium and hydrogen) with fallback to codfw
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]

    role lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include lvs::configuration
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

    role lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include lvs::configuration
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

    if $::hostname =~ /^lvs200[12]$/ {
        $ganglia_aggregator = true
    }

    # lvs200[25] are LVS balancers for the codfw recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (acamar and achernar) with fallback to eqiad
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '208.80.153.12', '208.80.153.42', '208.80.154.239' ]
    role lvs::balancer

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    include lvs::configuration
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

    if $::hostname =~ /^lvs300[12]$/ {
        $ganglia_aggregator = true
    }

    # lvs300[24] are LVS balancers for the esams recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (nescio and maerlant) with fallback to eqiad
    # (doing this for all lvs for now, see T103921)
    $nameservers_override = [ '91.198.174.106', '91.198.174.122', '208.80.154.239' ]

    role lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include lvs::configuration
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

    role lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    lvs::interface_tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
    }
}

node 'maerlant.wikimedia.org' {
    role dnsrecursor, ntp
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# RT and the other RT
node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    role requesttracker::server
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

}

node 'maps-test2001.codfw.wmnet' {
    role maps::server, maps::master
    include base::firewall
}

node /^maps-test200[2-4]\.codfw\.wmnet/ {
    role maps::server, maps::slave
    include base::firewall
}

node 'maps2001.codfw.wmnet' {
    role maps::server, maps::master
    include base::firewall
}

node /^maps200[2-4]\.codfw\.wmnet/ {
    role maps::server, maps::slave
    include base::firewall
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    role memcached
}

node /^mc20[01][0-9]\.codfw\.wmnet/ {
    role memcached
}

node 'meitnerium.wikimedia.org' {
    $cluster = 'misc'
    role archiva
    include standard
}

# OTRS - ticket.wikimedia.org
node 'mendelevium.eqiad.wmnet' {
    role otrs::webserver
}

node 'multatuli.wikimedia.org' {
    role spare

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# also see dataset1001
node 'ms1001.wikimedia.org' {
    $cluster = 'misc'

    role dataset::secondary, dumps
    include standard
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'ms1002.eqiad.wmnet' {
    include standard
}

# Whenever adding a new node there, you have to ask MediaWiki to recognize the
# new server IP as a trusted proxy so X-Forwarded-For headers are trusted for
# rate limiting purposes (T66622)
node /^ms-fe1001\.eqiad\.wmnet$/ {
    role swift::proxy, swift::stats_reporter
    include lvs::realserver
}

node /^ms-fe100[2-4]\.eqiad\.wmnet$/ {
    role swift::proxy
    include ::lvs::realserver
}

node /^ms-be10(0[0-9]|1[0-5])\.eqiad\.wmnet$/ {
    role swift::storage
}

# HP machines have different disk ordering T90922
node /^ms-be10(1[6-9]|2[0-1])\.eqiad\.wmnet$/ {
    role swift::storage
}

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    role swift::proxy
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    role swift::storage
}

node /^ms-fe2001\.codfw\.wmnet$/ {
    role swift::proxy, swift::stats_reporter
    $ganglia_aggregator = true
    include ::lvs::realserver
}

node /^ms-fe2002\.codfw\.wmnet$/ {
    role swift::proxy
    $ganglia_aggregator = true
    include ::lvs::realserver
}

node /^ms-fe200[3-4]\.codfw\.wmnet$/ {
    role swift::proxy
    include ::lvs::realserver
}

node /^ms-be20(0[0-9]|1[0-5])\.codfw\.wmnet$/ {
    role swift::storage
}

# HP machines have different disk ordering T90922
node /^ms-be20(1[6-9]|2[0-1])\.codfw\.wmnet$/ {
    role swift::storage
}

# mw1001-1016 are jobrunners
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {
    role mediawiki::jobrunner
    include base::firewall
}

# mw1017-mw1025 are canary appservers
node /^mw10(1[7-9]|2[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::canary_appserver
    include base::firewall
}

# mw1090-mw1113 are appservers
node /^mw1(09[0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# mw1114-mw1120 are canary api appservers
node /^mw11(1[4-9]|20)\.eqiad\.wmnet$/ {
    role mediawiki::appserver::canary_api
    include base::firewall
}

# mw1131-1148 are api apaches
node /^mw11(3[1-9]|4[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

# mw1149-1151 are apaches
node /^mw11(49|5[0-1])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# mw1152 is the experimental HAT script runner
node 'mw1152.eqiad.wmnet' {
    role mediawiki::maintenance, mariadb::maintenance, mediawiki::generic_monitoring
    include role::noc::site
    include standard
    include base::firewall
    include ldap::role::client::labs
}

# mw1153-1160 are imagescalers (trusty)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {
    role mediawiki::imagescaler
}

# mw1161-1169 are job runners
node /^mw116[1-9]\.eqiad\.wmnet$/ {
    role mediawiki::jobrunner
    include base::firewall
}

# mw1170-1188 are apaches
node /^mw11(7[0-9]|8[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# mw1189-1208 are api apaches
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

# mw1209-1220 are apaches
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw1221-mw1235 are api apaches
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

#mw1236-mw1258 are apaches
node /^mw12(3[6-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw1259-60 are videoscalers
node /^mw12(59|60)\.eqiad\.wmnet/ {
    role mediawiki::videoscaler
}

# ROW A eqiad appservers
#mw1261 - mw1275

node /^mw126[1-5]\.eqiad\.wmnet$/ {
    role mediawiki::canary_appserver
    include base::firewall
}

node /^mw12(6[6-9]|7[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# ROW A eqiad api appserver
# mw1276 - mw1290
node /^mw127[6-9]\.eqiad\.wmnet$/ {
    role mediawiki::appserver::canary_api
    include base::firewall
}

node /^mw12(8[0-9]|90)\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

# ROW A eqiad imagescalers
node /^mw129[1-8]\.eqiad\.wmnet$/ {
    role mediawiki::imagescaler
}

# ROW A eqiad jobrunners
node /^mw1(299|30[0-6])\.eqiad\.wmnet$/ {
    role mediawiki::jobrunner
    include base::firewall
}

# ROW A codfw appservers: mw2061-mw2079, plus mw2017

# mw2017.codfw.wmnet is a codfw test appserver
node 'mw2017.codfw.wmnet' {
    role mediawiki::appserver
    include base::firewall
}


#mw2061-2079 are api appservers
node /^mw20[6-7][0-9]\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}


# ROW B codfw appservers: mw2080-mw2147
#mw2080-mw2085 are jobrunners
node /^mw208[0-5]\.codfw\.wmnet$/ {
    if $::hostname == 'mw2080' {
        $ganglia_aggregator = true
    }
    role mediawiki::jobrunner
    include base::firewall
}

#mw2086-mw2089 are imagescalers
node /^mw208[6-9]\.codfw\.wmnet$/ {
    role mediawiki::imagescaler
}

#mw2090-mw2119 are appservers
node /^mw2(09[0-9]|1[0-1][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw2120-2147 are api appservers
node /^mw21([2-3][0-9]|4[0-7])\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

# ROW C codfw appservers: mw2148-mw2234

#mw2148-mw2151 are imagescalers
node /^mw21(4[89]|5[01])\.codfw\.wmnet$/ {
    role mediawiki::imagescaler
}

#mw2152 is a videoscaler
node 'mw2152.codfw.wmnet' {
    role mediawiki::videoscaler
}

#mw2153-62 are jobrunners
node /^mw21(5[3-9]|6[0-2])\.codfw\.wmnet$/ {
    role mediawiki::jobrunner
    include base::firewall
}

#mw2163-mw2199 are appservers
node /^mw21(6[3-9]|[6-9][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw2200-2234 are api appservers
node /^mw22([0-2][0-9]|3[0-4])\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

node 'mx1001.wikimedia.org' {
    role mail::mx
    include standard
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
    role mail::mx
    include standard
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
node /^notebook100[12]\.eqiad\.wmnet$/ {
    role notebook::server

    include standard
    include admin
}

# salt master
node 'neodymium.eqiad.wmnet' {
    role salt::masters::production, deployment::salt_masters,
      debdeploy::master, ipmi, access_new_install, mariadb::client
    include standard
    include base::firewall
}

# Icinga
node 'neon.wikimedia.org' {
    role icinga, tendril, tcpircbot
}

node 'nescio.wikimedia.org' {
    role dnsrecursor, ntp
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# network monitoring tool server
node 'netmon1001.wikimedia.org' {
    role rancid, librenms, servermon, torrus, smokeping
    include standard
    include passwords::network
    include ganglia::deprecated::collector
    include base::firewall

    interface::add_ip6_mapped { 'main': }

    class { 'ganglia::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }
}

# Test server for labs ElasticSearch replication
node 'nobelium.eqiad.wmnet' {
    role elasticsearch::server

    include elasticsearch::proxy
    include base::firewall
    include standard
}

# Offline Content Generator
node /^ocg100[123]\.eqiad\.wmnet$/ {
    role ocg
}

node /^oresrdb100[12]\.eqiad\.wmnet$/ {
    role ores::redis
    include ::standard
}

# VisualEditor performance testing rig
node 'osmium.eqiad.wmnet' {
    role ve
    include ::standard
}

# oxygen runs a kafkatee instance that consumes webrequest from Kafka
# and writes to a couple of files for quick and easy ops debugging.,
node 'oxygen.eqiad.wmnet'
{
    role logging::kafkatee::webrequest::ops

    include base::firewall
    include standard
}

# primary puppet master
node 'palladium.eqiad.wmnet' {
    role ipmi, access_new_install, puppetmaster::frontend, pybal_config
    include standard
    include role::conftool::master
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# parser cache databases
# eqiad
node 'pc1004.eqiad.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc1',
    }

    include base::firewall
}
node 'pc1005.eqiad.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc2',
    }

    include base::firewall
}
node 'pc1006.eqiad.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc3',
    }

    include base::firewall
}
# codfw
node 'pc2004.codfw.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc1',
    }

    include base::firewall
}
node 'pc2005.codfw.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc2',
    }

    include base::firewall
}
node 'pc2006.codfw.wmnet' {
    class { 'role::mariadb::parsercache':
        shard  => 'pc3',
    }

    include base::firewall
}

# virtual machines hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node /^planet[12]001\.(eqiad|codfw)\.wmnet$/ {
    role planet::venus
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    $cluster = 'openldap_corp_mirror'

    role openldap::corp, backup::host
    include standard
    backup::openldapset {'openldap_oit':}
}

# careful when moving poolcounters
node 'potassium.eqiad.wmnet' {
    role poolcounter
    include standard
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[12]\.codfw\.wmnet$/ {
    role test::system
}

# pybal-test2003 is used for pybal testing/development
# and for redis multi-instance testing/development
node 'pybal-test2003.codfw.wmnet' {
    role test::system

    redis::instance { 6370: }
    redis::instance { 6371: }
}

# Tor relay
node 'radium.wikimedia.org' {
    role tor::relay

    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'radon.wikimedia.org' {
    role authdns::server

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
}

# Live Recent Changes WebSocket stream
node 'rcs1001.eqiad.wmnet', 'rcs1002.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role rcstream
    include base::firewall
}

node /^rdb100[1-9]\.eqiad\.wmnet/ {
    role jobqueue_redis
    include base::firewall
}

node /^rdb200[1-6]\.codfw\.wmnet/ {
    role jobqueue_redis
    include base::firewall
}

# restbase eqiad cluster
node /^restbase10[01][0-9]\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include standard
}

# restbase codfw cluster
node /^restbase200[1-9]\.codfw\.wmnet$/ {
    role restbase, cassandra
    include standard
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role pmacct
    include standard
    include base::firewall
}

node 'rubidium.wikimedia.org' {
    role spare

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'rutherfordium.eqiad.wmnet' {
    role microsites::peopleweb, backup::host
    include base::firewall
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
# Right now, both rt-server and rt-clients run on the same node
# But, we are likely going to split them into different boxes soon.
node 'ruthenium.eqiad.wmnet' {
    role test::system,
        parsoid::testing, parsoid::rt_server, parsoid::rt_client,
        parsoid::vd_server, parsoid::vd_client

}

# salt master fallback
node 'sarin.codfw.wmnet' {
    role salt::masters::production, mariadb::client
    include standard
    include base::firewall
}

# T95046 install/deploy scandium as zuul merger (ci) server
node 'scandium.eqiad.wmnet' {
    role zuul::merger
    include standard
    include base::firewall

    file { '/srv/ssd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }
    mount { '/srv/ssd':
        ensure  => mounted,
        device  => '/dev/md2',
        fstype  => 'xfs',
        options => 'noatime,nodiratime,nobarrier,logbufs=8',
        require => File['/srv/ssd'],
    }

}

node /^sca[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role sca
}

node /^scb[12]00[12]\.(eqiad|codfw)\.wmnet$/ {
    role scb
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role openldap::labs, backup::host
    include standard
    include base::firewall

    if $::hostname == 'serpens' {
        backup::openldapset {'openldap_labs':}
    }
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    role labs::openstack::nova::manager, mariadb::wikitech
    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main': }
}

# mw logging host codfw - setup pending
node 'sinistra.codfw.wmnet' {

    include base::firewall
    include standard
}

node /^(strontium|rhodium).eqiad.wmnet/ {
    role puppetmaster::backend
    include standard
}

node 'stat1001.eqiad.wmnet' {
    # stat1001 is mainly used to host Analytics websites like:
    # - http://stats.wikimedia.org (Wikistats)
    # - http://datasets.wikimedia.org
    # - http://metrics.wikimedia.org
    #       or https://metrics.wmflabs.org/ (Wikimetrics)
    #
    # For a complete and up to date list please check the
    # related role/module.
    #
    # This node is not intended for data processing.
    role statistics::web
    include standard
    include base::firewall
}

node 'stat1002.eqiad.wmnet' {
    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    # Include classes needed for storing and crunching
    # private data on stat1002.
    role statistics::private,
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
        elasticsearch::analytics

    include standard

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    include passwords::mysql::research
    mysql::config::client { 'analytics-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'analytics-privatedata-users',
        mode  => '0440',
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
    role statistics::cruncher

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/research-client.cnf.
    mysql::config::client { 'research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'researchers',
        mode  => '0440',
    }
}

node 'stat1004.eqiad.wmnet' {
    # stat1004 contains all the tools and libraries to access
    # the Analytics Cluster services.

    role analytics_cluster::client, analytics_cluster::refinery, statistics::migration

    include standard
}

node /^snapshot100[1-2]\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera common.yaml dataset_clients_snapshots.

    role snapshot::producer, snapshot::cron
    include standard
}

node /^snapshot1004\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera common.yaml dataset_clients_snapshots.

    role snapshot::producer, snapshot::cron, snapshot::dumps::monitor
    include standard
}

node /^snapshot1003\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to hiera common.yaml dataset_clients_snapshots.

    role snapshot::producer, snapshot::cron::primary
    include standard
}

node /^snapshot100[5-7]\.eqiad\.wmnet/ {
    # start setup and rollout of new role on new hosts
    role snapshot::dumper
    include standard
    include base::firewall
}

# codfw poolcounters
node /(subra|suhail)\.codfw\.wmnet/ {
    role poolcounter
    include standard
}

# neon-like monitoring host in codfw
node 'tegmen.wikimedia.org' {
    include standard
    include base::firewall
}

# https://wikitech.wikimedia.org/wiki/Terbium
node 'terbium.eqiad.wmnet' {
    role mariadb::maintenance, mediawiki::maintenance

    include ldap::role::client::labs
    include base::firewall
}

# deployment servers
node 'tin.eqiad.wmnet', 'mira.codfw.wmnet' {
    role deployment::server, labsdb::manager
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# titanium hosts archiva.wikimedia.org
node 'titanium.wikimedia.org' {
    $cluster = 'misc'
    role archiva
    include standard
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role test::system, xhgui
    include base::firewall
}

# will replace magnesium (RT) (T123713)
node 'ununpentium.wikimedia.org' {
    role requesttracker::server

    include standard
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

}

node 'uranium.wikimedia.org' {
    $ganglia_aggregator = true

    role ganglia::web
    include standard
    include misc::monitoring::views
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^labvirt100[0-9].eqiad.wmnet/ {
    openstack::nova::partition{ '/dev/sdb': }
    role labs::openstack::nova::compute
    include standard
}

node /^labvirt101[0-1].eqiad.wmnet/ {
    role labs::openstack::nova::compute
    include standard
}

# mediawiki maintenance server (like terbium)
node 'wasat.codfw.wmnet' {
    role mariadb::maintenance, mediawiki::maintenance

    include ldap::role::client::labs
    include base::firewall
}

# Wikidata query service
node /^wdqs100[1-2]\.eqiad\.wmnet$/ {
    role wdqs

    $nagios_contact_group = 'admins,wdqs-admins'
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    role parsoid::production
}

# https://www.mediawiki.org/wiki/Parsoid
node /^wtp20(0[1-9]|1[0-9]|2[0-4])\.codfw\.wmnet$/ {
    role parsoid::production
    include standard
}

# https://www.mediawiki.org/wiki/Gerrit
node 'ytterbium.wikimedia.org' {
    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::configuration variable 'gerrit_server'
    role gerrit::production
    include standard

    interface::add_ip6_mapped { 'main': }
}

node default {
    if $::realm == 'production' {
        include standard
    } else {
        include role::labs::instance
    }
}
