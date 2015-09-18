# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first
import 'misc/*.pp'
import 'network.pp'
import 'nfs.pp'
import 'role/*.pp'
import 'role/analytics/*.pp'

# Include stages last
import 'stages.pp'

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard(
    $has_default_mail_relay = true,
    $has_admin = true,
    $has_ganglia = true,
) {
    include base
    include role::ntp
    include role::diamond
    if $has_ganglia {
        include ::ganglia
    }
    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include role::mail::sender
    }
    # Some instances in production (ideally none) and labs do not use
    # the admin class
    if $has_admin {
        include ::admin
    }

}

# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node /^(acamar|achernar)\.wikimedia\.org$/ {
    include base::firewall
    include standard

    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}



# analytics1001 is the Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'analytics1001.eqiad.wmnet' {
    role analytics::hadoop::master

    include standard
}


# analytics1002 is the Hadoop standby NameNode.
node 'analytics1002.eqiad.wmnet' {
    role analytics::hadoop::standby

    include standard
}



# NOTE: analytics1003,1004 and 1010 are the remaining analytics Cicsos.
# They are being used for testing some realtime streaming frameworks.

# analytics1003 is being used for standalone Spark (Streaming).
# It is the Spark Standalone Master and also a worker.
node 'analytics1003.eqiad.wmnet' {
    role analytics::hadoop::client,
        analytics::hive::client,
        analytics::spark::standalone,
        analytics::spark::standalone::master,
        analytics::spark::standalone::worker

    include standard
}

# analytics1004 and analytics1010 are Spark Standalone workers
node /analytics10(04|10).eqiad.wmnet/ {
    role analytics::hadoop::client,
        analytics::hive::client,
        analytics::spark::standalone,
        analytics::spark::standalone::worker

    # Use analytics1010 for testing eventlogging kafka.
    if $::hostname == 'analytics1010' {
        include role::eventlogging
    }

    include standard
}

# This node is being repurposed - otto 2015-09
node 'analytics1015.eqiad.wmnet' {
    include standard
    include base::firewall
    include role::analytics::mysql::meta
}

# analytics1017
# analytics1028-analytics1057 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# templates/hadoop/net-topology.py.erb to make sure the
# hostname -> /datacenter/rack/row id is correct.  This is
# used for Hadoop network topology awareness.
node /analytics10(17|2[89]|3[0-9]|4[0-9]|5[0-7]).eqiad.wmnet/ {

    role analytics::hadoop::worker, analytics::impala::worker
    include base::firewall
    include standard
}

# This node was previously a kafka broker, but is now waiting
# to be repurposed (likely as a stat* type box).
node 'analytics1021.eqiad.wmnet' {
    include standard
    include base::firewall
}

# analytics1026 is the Impala master
# (llama, impala-state-store, impala-catalog)
# analytics1026 also runs misc udp2log for sqstat
node 'analytics1026.eqiad.wmnet' {

    include standard
    include role::analytics::clients
    include role::analytics::impala::master
    include role::logging::udp2log::misc
    include base::firewall
    include base::debdeploy
    salt::grain { 'debdeploy-analytics': value => 'true' }
}

# analytics1027 hosts some frontend web interfaces to Hadoop
# (Hue, Oozie, Hive, etc.).  It also submits regularly scheduled
# batch Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {

    include standard
    include base::firewall

    include role::analytics::hive::server
    include role::analytics::oozie::server
    include role::analytics::hue

    # Make sure refinery happens before analytics::clients,
    # so that the hive role can properly configure Hive's
    # auxpath to include refinery-hive.jar.
    Class['role::analytics::refinery'] -> Class['role::analytics::clients']

    # Include analytics/refinery deployment target.
    include role::analytics::refinery
    # Include analytics clients (Hadoop, Hive etc.)
    include role::analytics::clients


    # Add cron jobs to run Camus to import data into
    # HDFS from Kafka.
    include role::analytics::refinery::camus

    # Add cron job to delete old data in HDFS
    include role::analytics::refinery::data::drop

    # Oozie runs a monitor_done_flag job to make
    # sure the _SUCCESS done-flag is written
    # for each hourly webrequest import.  This
    # file is written only if the hourly import
    # reports a 0.0 percent_different in expected
    # vs actual number of sequence numbers per host.
    # These are passive checks, so if
    # icinga is not notified of a successful import
    # hourly, icinga should generate an alert.
    include role::analytics::refinery::data::check::icinga

    # Include a weekly cron job to run hdfs balancer.
    include role::analytics::hadoop::balancer
}

# Analytics Query Service (RESTBase & Cassandra)
node /aqs100[123]\.eqiad\.wmnet/ {
    include standard
    include base::firewall
}


# git.wikimedia.org
node 'antimony.wikimedia.org' {
    role gitblit
    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main': }
}

# irc.wikimedia.org
node 'argon.wikimedia.org' {
    include standard
    include role::mw-rc-irc
}

node 'baham.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include role::authdns::server
}

# Bastion in Virginia
node 'bast1001.wikimedia.org' {

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    $cluster = 'misc'
    $ganglia_aggregator = true
    role bastionhost

    include standard
    include subversion::client
    include dsh
    class { 'nfs::netapp::home':
        mountpoint => '/srv/home_pmtpa',
        mount_site => 'pmtpa',
    }
}

# Bastion in Texas
node 'bast2001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost
    include standard

}

# Bastion in California
node 'bast4001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    role bastionhost
    include standard
    include role::ipmi
    include role::installserver::tftp-server

    class { 'ganglia::monitor::aggregator':
        sites =>  'ulsfo',
    }
}

# IPsec testing
node /^(berkelium|curium)\.eqiad\.wmnet$/ {
    $cluster = 'misc'
    include standard
    interface::add_ip6_mapped { 'main': }
    rsyslog::conf { 'remote_logstash':
        content  => '*.* @logstash1002.eqiad.wmnet:10514',
        priority => 32,
    }
    role ipsec
}

# virtual machine for static misc. services
node 'bromine.eqiad.wmnet' {
    include standard
    include base::firewall
    include role::bugzilla_static
    include role::annualreport
    include role::transparency
}

# http://releases.wikimedia.org
node 'caesium.eqiad.wmnet' {
    role releases
    include base::firewall
    include standard
}

# T83044 cameras
node 'calcium.wikimedia.org' {
    $cluster = 'misc'

    include standard
    include base::firewall
}

# Californium hosts openstack-dashboard AKA horizon
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    include standard
    include role::horizon
    include base::firewall
}

# DHCP / TFTP
node 'carbon.wikimedia.org' {
    $cluster = 'misc'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include role::installserver

    class { 'ganglia::monitor::aggregator':
        sites =>  'eqiad',
    }

}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include base::firewall
    include standard
}

# cassandra multi-dc temporary test T111382
node /^restbase-test200[1-3]\.codfw\.wmnet$/ {
    role restbase, cassandra
    include base::firewall
    include standard
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
    include base::firewall
    include standard
    include role::dnsrecursor

    if $::hostname == 'chromium' {
        $url_downloader_ip = hiera('url_downloader_ip')
        interface::ip { 'url-downloader':
            interface => 'eth0',
            address   => $url_downloader_ip,
        }
        class { 'role::url_downloader':
            url_downloader_ip => $url_downloader_ip
        }
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# conf100x are zookeeper and etcd discovery service nodes
node /^conf100[123]\.eqiad\.wmnet$/ {
    role etcd
    include base::firewall
    include standard

    include role::zookeeper::server
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

node /^cp104[34]\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::maps
}

node 'cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role cache::parsoid
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role cache::mobile, ipsec
}

node /^cp10(4[89]|5[01]|6[1-4]|7[1-4]|99)\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node 'cp1056.eqiad.wmnet', 'cp1057.eqiad.wmnet', 'cp1069.eqiad.wmnet', 'cp1070.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role cache::misc
}

node /^cp20(0[147]|1[0369]|23)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp20(0[258]|1[147]|2[04])\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

node /^cp20(0[39]|15|21)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::mobile, ipsec
}

node /^cp20(06|1[28]|25)\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    # formerly codfw bits cluster
    include standard
}

node /^cp202[26]\.codfw\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::parsoid
}

node /^cp30(0[3-9]|1[0-4])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp301[5678]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::mobile, ipsec
}

node /^cp30(19|2[0-2])\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    # formerly esams bits cluster
    include standard
}

node /^cp30[34][01]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::text, ipsec
}

node /^cp30[34][2-9]\.esams\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::upload, ipsec
}

#
# ulsfo varnishes
#

node /^cp400[1-4]\.ulsfo\.wmnet$/ {
    interface::add_ip6_mapped { 'main': }
    # formerly ulsfo bits cluster
    include standard
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
    role cache::mobile, ipsec
}

node 'dataset1001.wikimedia.org' {

    role dataset::systemusers, dataset::primary, dumps
    include standard
    include base::firewall

    interface::add_ip6_mapped { 'eth2':
        interface => 'eth2',
    }
}

# eqiad dbs

node /^db10(24)\.eqiad\.wmnet/ {
    class { 'role::coredb::s2':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(52)\.eqiad\.wmnet/ {
    class { 'role::coredb::s1':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(38)\.eqiad\.wmnet/ {
    class { 'role::coredb::s3':
        # Many more tables than other shards.
        # innodb_file_per_table=off to reduce file handles.
        innodb_file_per_table => false,
        mariadb               => true,
    }
}

node /^db10(40)\.eqiad\.wmnet/ {
    class { 'role::coredb::s4':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(58)\.eqiad\.wmnet/ {
    class { 'role::coredb::s5':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(23)\.eqiad\.wmnet/ {
    class { 'role::coredb::s6':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(33)\.eqiad\.wmnet/ {
    class { 'role::coredb::s7':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

# MariaDB 10

node /^db10(51|53|55|57|65|66|72|73)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db20(16|34|42|48)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's1',
    }
    include base::firewall
}

node /^db10(18|21|36|54|60|63|67)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's2',
    }
}

node /^db20(17|35|41|49)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
    include base::firewall
}

node /^db10(15|27|35|44)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's3',
    }
}

node /^db20(18|36|43|50)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's3',
    }
    include base::firewall
}

node /^db10(19|42|56|59|64|68)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's4',
    }
}

node /^db20(19|37|44|51)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's4',
    }
    include base::firewall
}

node /^db10(26|45|49|70|71)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's5',
    }
}

node /^db20(23|38|45|52)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
    include base::firewall
}

node /^db10(22|30|37|50|61)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's6',
    }
}

node /^db20(28|39|46|53)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
    }
    include base::firewall
}

node /^db10(28|34|39|41|62)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's7',
    }
}

node /^db20(29|40|47|54)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's7',
    }
    include base::firewall
}

## x1 shard
node /^db10(29|31)\.eqiad\.wmnet/ {
    include role::coredb::x1
}

node /^db20(09)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'x1',
    }
    include base::firewall
}

## m1 shard
node /^db10(01)\.eqiad\.wmnet/ {
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

node 'db1016.eqiad.wmnet' {
    class { 'role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
}

node /^db20(10|30)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::misc':
        shard => 'm1',
    }
}

## m2 shard
node /^db10(20)\.eqiad\.wmnet/ {
    class { 'role::mariadb::misc':
        shard => 'm2',
    }
}

node /^db20(11)\.codfw\.wmnet/ {

    $cluster = 'mysql'
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

node /^db20(12)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::misc::phabricator':
        shard => 'm3',
    }
    include base::firewall
}

# m4 shard
node 'db1046.eqiad.wmnet' {
    class { 'role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => true,
    }
}

# m5 shard
node 'db1009.eqiad.wmnet' {
    class { 'role::mariadb::misc':
        shard  => 'm5',
        master => true,
    }
}

## researchdb s1
node 'db1047.eqiad.wmnet' {
    include role::mariadb::analytics
}

node 'db1069.eqiad.wmnet' {
    include role::mariadb::sanitarium
    include base::firewall
}

node 'db1011.eqiad.wmnet' {
    include role::mariadb::tendril
}

# codfw db
node /^db20(5[5-9]|6[0-9]|70)\.codfw\.wmnet$/ {

    $cluster = 'mysql'
    include standard
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
}

node 'dbstore1002.eqiad.wmnet' {
    include role::mariadb::dbstore
}

node 'dbstore2001.codfw.wmnet' {
    $cluster = 'mysql'
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
    $cluster = 'mysql'
    include role::mariadb::dbstore
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

node 'eeden.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include role::authdns::server
}

node 'einsteinium.eqiad.wmnet' {
    include standard
    system::role { 'Titan test host': }
}

node /^elastic10[0-3][0-9]\.eqiad\.wmnet/ {
    role elasticsearch::server
    include base::firewall
    include standard
}

node /^elastic20[0-3][0-9]\.codfw\.wmnet/ {
    role elasticsearch::server
    include base::firewall
    class { 'standard':
        has_ganglia => false,
    }
}

# erbium is a webrequest udp2log host
node 'erbium.eqiad.wmnet' {
    include standard
    include role::logging

    # gadolinium hosts the separate nginx webrequest udp2log instance.
    include role::logging::udp2log::erbium

    # Include kafkatee fundraising outputs alongside of udp2log
    # while FR techs verify that they can use this output.
    include role::logging::kafkatee::webrequest::fundraising
}

# es1 databases
node /es100[1234]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es1',
    }
}

node /es200[1234]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es1',
    }
    include base::firewall
}

## es1 new nodes
node /^es101[268]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es1',
    }
}


# es2 databases
node /es1006\.eqiad\.wmnet/ {
    class { 'role::coredb::es2':
        mariadb => true,
    }
}

node /es100[57]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}

node /es200[567]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es2',
    }
    include base::firewall
}

## es2 new nodes
node /^es101[135]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}


# es3 databases
node /es100[9]\.eqiad\.wmnet/ {
    class { 'role::coredb::es3':
        mariadb => true,
    }
}

node /es10(08|10)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}

node /es20(08|09|10)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es3',
    }
    include base::firewall
}

## es3 new nodes
node /^es101[479]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}


# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    include base::firewall
    include role::etherpad
}

# Receives log data from Kafka and Apaches (udp 8421),
# processes it, and broadcasts to Kafka Schema based topics.
node 'eventlog1001.eqiad.wmnet' {
    role eventlogging,
        eventlogging::forwarder,
        eventlogging::processor,
        eventlogging::consumer::mysql,
        eventlogging::consumer::files

    include standard
    include role::ipython_notebook
    include role::logging::mediawiki::errors
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role lists
    include standard
    include admin
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'fluorine.eqiad.wmnet' {
    $cluster = 'misc'

    include standard
    include ::role::xenon
    include role::dataset::publicdirs

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
    include base::firewall
}

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node 'gadolinium.wikimedia.org' {
    include standard
    include role::logging

    # relay the incoming webrequest log stream to multicast
    include role::logging::relay::webrequest-multicast
    # relay EventLogging traffic over to eventlog1001
    include role::logging::relay::eventlogging
}

# Continuous Integration
node 'gallium.wikimedia.org' {

    $cluster = 'misc'
    $nagios_contact_group = 'admins,contint'

    # T51846, let us sync VisualEditor in mediawiki/extensions.git
    sudo::user { 'jenkins-slave':
        privileges => [
            'ALL = (jenkins) NOPASSWD: /srv/deployment/integration/slave-scripts/bin/gerrit-sync-ve-push.sh',
        ]
    }

    include standard
    include contint::firewall
    include role::ci::master
    include role::ci::slave
    include role::ci::website
    include role::zuul::production

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
node 'hafnium.wikimedia.org' {
    role eventlogging

    include standard
    include base::firewall
    include role::webperf
}

# poolcounter - careful
node 'helium.eqiad.wmnet' {
    include standard
    include base::firewall
    include role::poolcounter
    include role::backup::director
    include role::backup::storage
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    include standard
    include role::backup::storage
    include base::firewall
}

# Holmium hosts openstack-designate, the labs DNS service.
node 'holmium.wikimedia.org' {
    include standard

    include base::firewall
    include role::labsdns
    include role::labsdnsrecursor
    include role::designate::server

    include ldap::role::client::labs
}

# bastion in the Netherlands
node 'hooft.esams.wikimedia.org' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost

    include standard
    include role::installserver::tftp-server

    class { 'ganglia::monitor::aggregator':
        sites =>  'esams',
    }
}

# Primary graphite machines, replacing tungsten
node 'graphite1001.eqiad.wmnet' {
    include standard
    include role::graphite::production
    include role::statsdlb
    include role::gdash
    include role::tessera
    include role::performance
    include role::graphite::production::alerts
    include role::restbase::alerts
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    include standard
}

# Primary graphite machines, replacing tungsten
node 'graphite2001.codfw.wmnet' {
    include standard
    include role::graphite::production
    include role::statsdlb
    include role::gdash
}

node 'install2001.wikimedia.org' {
    $cluster = 'misc'
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include role::installserver::tftp-server

    class { 'ganglia::monitor::aggregator':
        sites =>  'codfw',
    }
}

# ticket.wikimedia.org
node 'iodine.wikimedia.org' {
    include base::firewall
    role otrs

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Phabricator
node 'iridium.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include base::firewall
    role phabricator::main
    include standard
    include ganglia
    include role::ntp
    include role::diamond
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Operations Bastion',
    }
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost

    include standard
    include role::ipmi
    include role::access_new_install
}

# Analytics Kafka Brokers
node /kafka10(12|13|14|18|20|22)\.eqiad\.wmnet/ {
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    role analytics::kafka::server
    include role::analytics
    include standard
}

# virtual machine for misc. PHP apps
node 'krypton.eqiad.wmnet' {
    include standard
    include base::firewall
    include role::wikimania_scholarships
    include role::iegreview
    include role::grafana
}

node 'labcontrol1001.wikimedia.org' {
    $is_puppet_master      = true
    $is_labs_puppet_master = true
    $use_neutron           = false
    role nova::controller

    include standard
    include ldap::role::client::labs
    include role::salt::masters::labs
    include role::deployment::salt_masters
    include role::dns::ldap
    if $use_neutron == true {
        include role::neutron::controller

    }
}

# labcontrol1002 is a hot spare for 1001.  Switching it on
#  involves uncommenting the dns role, below, and also
#  changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    $is_puppet_master      = true
    $is_labs_puppet_master = true
    $use_neutron           = false

    include standard
    include ldap::role::client::labs
    include role::salt::masters::labs
    include role::deployment::salt_masters
    role nova::controller
    if $use_neutron == true {
        include role::neutron::controller
    }

    # The dns controller grabs an IP, so leave this disabled until/unless
    #  this server is the primary labs controller.
    #include role::dns::ldap
}

node 'labcontrol2001.wikimedia.org' {
    $ganglia_aggregator    = true
    #$is_puppet_master      = true
    #$is_labs_puppet_master = true
    #$use_neutron           = false

    include standard
    include base::firewall
    include role::dns::ldap
    include ldap::role::client::labs
    include role::salt::masters::labs

    #include role::nova::controller
    #include role::nova::manager
    #include role::salt::masters::labs
    #include role::deployment::salt_masters
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role labmon
    include standard
}

node 'labnet1001.eqiad.wmnet' {
    $use_neutron = false

    include standard
    include role::nova::api

    if $use_neutron == true {
        #include role::neutron::nethost
    } else {
        #include role::nova::network
    }
}

node 'labnet1002.eqiad.wmnet' {
    $use_neutron = false

    include standard
    include role::nova::api

    if $use_neutron == true {
        include role::neutron::nethost
    } else {
        include role::nova::network
    }
}

node 'labnodepool1001.eqiad.wmnet' {
    $nagios_contact_group = 'admins,contint'
    include standard
    include role::nodepool
    include base::firewall
}

## labsdb dbs
node 'labsdb1001.eqiad.wmnet' {
    # this role is depecated and should be converted to labs::db::slave
    include role::mariadb::labs
    include base::firewall
}

node 'labsdb1002.eqiad.wmnet' {
    # this role is depecated and should be converted to labs::db::slave
    include role::mariadb::labs
    include base::firewall
}

node 'labsdb1003.eqiad.wmnet' {
    # this role is depecated and should be converted to labs::db::slave
    include role::mariadb::labs
    include base::firewall
}

node 'labsdb1004.eqiad.wmnet' {
    # Bug: T101233
    #$postgres_slave = 'labsdb1005.eqiad.wmnet'
    #$postgres_slave_v4 = '10.64.37.9'

    include role::postgres::master
    # role labs::db::slave
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

    include role::osm::master
    # include role::labs::db::slave
}

node 'labsdb1007.eqiad.wmnet' {
    $osm_master = 'labsdb1006.eqiad.wmnet'

    include role::osm::slave
    # include role::labs::db::master
}

node /labstore100[12]\.eqiad\.wmnet/ {
    role labs::nfs::fileserver

}

node 'labstore1003.eqiad.wmnet' {
    role labs::nfs::extras
}

node /labstore200[12]\.codfw\.wmnet/ {
    $cluster = 'labsnfs'

    role labs::nfs::fileserver
}


# secondary mailserver
node 'lead.wikimedia.org' {
    role mail::mx
    include standard
    include base::firewall
    interface::add_ip6_mapped { 'main': }
}

node 'lithium.eqiad.wmnet' {

    include standard
    include role::backup::host
    include role::syslog::centralserver
    include base::firewall
}

node /^logstash100[1-3]\.eqiad\.wmnet$/ {
    role logstash, kibana, logstash::apifeatureusage
    include base::firewall
}
node /^logstash100[4-6]\.eqiad\.wmnet$/ {
    role logstash::elasticsearch
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

    lvs::interface-tweaks {
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

    # comment out for now, requires defining serviceip/traffic-class stuff...
    # role lvs::balancer
    include standard # in place of above!

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
            interface::tagged { 'eth0.1017':
                base_interface => 'eth0',
                vlan_id        => '1017',
                address        => $ips['public1-a-eqiad'][$::hostname],
                netmask        => '255.255.252.0',
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
            interface::tagged { 'eth0.1019':
                base_interface => 'eth0',
                vlan_id        => '1019',
                address        => $ips['public1-c-eqiad'][$::hostname],
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

    lvs::interface-tweaks {
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

    lvs::interface-tweaks {
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

    lvs::interface-tweaks {
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

    lvs::interface-tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
    }
}

node 'maerlant.wikimedia.org' {
    include standard
    include base::firewall
    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# RT and the other RT
node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    include base::firewall

    role racktables, requesttracker

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

}

node 'maps-test2001.codfw.wmnet' {
    role maps::master
}

node /^maps-test200[2-4]\.codfw\.wmnet/ {
    role maps::slave
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {

    role memcached
    include passwords::redis

    file { '/a':
        ensure => 'directory',
    }

    include base::firewall
    include redis
    include redis::ganglia
}

node /^mc20[01][0-9]\.codfw\.wmnet/ {
    role memcached
    include passwords::redis
    include redis
    include redis::ganglia
    include base::debdeploy
    include base::firewall
    salt::grain { 'debdeploy-memcached': value => 'true' }
}

# OTRS evaluation upgrade
node 'mendelevium.eqiad.wmnet' {
    include base::firewall
    role otrs
}

# codfw deployment host (pending set up)
node 'mira.codfw.wmnet' {

    role deployment::server
    include standard
    include base::firewall
    include role::labsdb::manager
    include role::releases::upload

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'multatuli.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include base::firewall
}

# also see dataset1001
node 'ms1001.wikimedia.org' {
    $cluster = 'misc'

    role dataset::systemusers, dataset::secondary, dumps
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
node /^ms-fe100[1-4]\.eqiad\.wmnet$/ {
    role swift::proxy

    if $::hostname == 'ms-fe1001' {
        include role::swift::stats_reporter
    }

    include role::diamond
    include ::lvs::realserver
}

node /^ms-be10(0[0-9]|1[0-5])\.eqiad\.wmnet$/ {
    role swift::storage
}

# HP machines have different disk ordering T90922
node /^ms-be101[678]\.eqiad\.wmnet$/ {
    role swift::storage
}

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    role swift::proxy
    include base::debdeploy
    salt::grain { 'debdeploy-swift-proxy': value => 'true' }
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    role swift::storage
    include base::debdeploy
    salt::grain { 'debdeploy-swift-storage': value => 'true' }
}

node /^ms-fe200[1-4]\.codfw\.wmnet$/ {
    role swift::proxy

    if $::hostname =~ /^ms-fe200[12]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'ms-fe2001' {
        include role::swift::stats_reporter
    }

    include ::lvs::realserver
}

node /^ms-be20[0-9][0-9]\.codfw\.wmnet$/ {
    role swift::storage
}

# mw1001-1016 are jobrunners
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {
    role mediawiki::jobrunner

    if $::hostname == 'mw1010' {
        include base::firewall
    }
}

# mw1017-mw1025 are canary appservers
node /^mw10(1[7-9]|2[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::canary_appserver
    include base::firewall
}

# mw1026-mw1113 are appservers
node /^mw1(02[6-9]|0[3-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {
    role mediawiki::appserver

    if $::hostname =~ /^mw10([3-9][0-9])$/ {
        include base::firewall
    }
}

# mw1114-mw1119 are canary api appservers
node /^mw111[4-9]\.eqiad\.wmnet$/ {
    role mediawiki::appserver::canary_api
    include base::firewall
}

# mw1120-1148 are api apaches
node /^mw11([23][0-9]|4[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}


# mw1149-1151 are apaches
node /^mw11(49|5[0-1])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# mw1152 is the experimental HAT videoscaler
node 'mw1152.eqiad.wmnet' {
    role mediawiki::videoscaler
}


# mw1153-1160 are imagescalers (trusty)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {
    role mediawiki::imagescaler

    if $::hostname == 'mw1153' {
        include base::firewall
    }
}

# mw1161-1188 are apaches
node /^mw11(6[1-9]|7[0-9]|8[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

# mw1189-1208 are api apaches
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}

# mw1209-1220 are apaches
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw1221-mw1235 are api apaches
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}

#mw1236-mw1258 are apaches
node /^mw12(3[6-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw1259 is a videoscaler
node 'mw1259.eqiad.wmnet' {
    role mediawiki::videoscaler
}

# ROW A codfw appservers: mw2001-mw2079
#mw2001-mw2006 are jobrunners
node /^mw200[0-6]\.codfw\.wmnet$/ {
    if $::hostname == 'mw2001' {
        $ganglia_aggregator = true
    }
    role mediawiki::jobrunner
    include base::firewall
}

#mw2007 is a videoscaler
node 'mw2007.codfw.wmnet' {
    role mediawiki::videoscaler
    include base::firewall
}

#mw2008-mw2049 are appservers
node /^mw20(0[89]|[1-4][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw2050-2079 are api appservers
node /^mw20[5-7][0-9]\.codfw\.wmnet$/ {
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
    include base::firewall
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
    include base::firewall
}

#mw2152 is a videoscaler
node 'mw2152.codfw.wmnet' {
    role mediawiki::videoscaler
    include base::firewall
}

#mw2153-mw2199 are appservers
node /^mw21(5[3-9]|[6-9][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
    include base::firewall
}

#mw2200-2234 are api appservers
node /^mw22([0-2][0-9]|3[0-4])\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
    include base::firewall
}

# Codfw ldap server, aka ldap-codfw
node 'nembus.wikimedia.org' {
    include standard
    include base::firewall
    include ldap::role::server::labs
    include ldap::role::client::labs
}

# Icinga
node 'neon.wikimedia.org' {
    include base::firewall

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    include standard
    include role::icinga
    include role::ishmael
    include role::tendril
    include role::tcpircbot
}

# Eqiad ldap server, aka ldap-eqiad
node 'neptunium.wikimedia.org' {
    include standard
    include base::firewall
    include ldap::role::server::labs
    include ldap::role::client::labs
}

node 'nescio.wikimedia.org' {
    include standard
    include base::firewall
    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# network monitoring tool server
node 'netmon1001.wikimedia.org' {
    include standard
    include webserver::apache
    include role::rancid
    include smokeping
    include smokeping::web
    include role::librenms
    include passwords::network
    include ganglia::deprecated::collector
    include role::servermon
    include role::torrus

    interface::add_ip6_mapped { 'main': }

    class { 'ganglia::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }


}

node 'nitrogen.wikimedia.org' {
    include standard
    include role::ipv6relay

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Offline Content Generator
node /^ocg100[123]\.eqiad\.wmnet$/ {
    role ocg
}

# VisualEditor performance testing rig
node 'osmium.eqiad.wmnet' {
    role ve
    include ::standard
    include base::debdeploy
    salt::grain { 'debdeploy-misc-servers': value => 'true' }
}


# oxygen runs a kafkatee instance that consumes webrequest from Kafka
# and writes to a couple of files for quick and easy ops debugging.,
node 'oxygen.eqiad.wmnet'
{
    role logging::kafkatee::webrequest::ops

    include standard
}

# primary puppet master
node 'palladium.eqiad.wmnet' {
    include standard
    include role::ipmi
    include role::salt::masters::production
    include role::deployment::salt_masters
    include role::access_new_install
    include role::puppetmaster::frontend
    include role::pybal_config
    include role::conftool::master
    include role::debdeploymaster
}

# parser cache databases
node /pc100[1-3]\.eqiad\.wmnet/ {
    include role::mariadb::parsercache
}

# virtual machine hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node 'planet1001.eqiad.wmnet' {
    include base::firewall
    include role::planet
}

# LDAP servers relied on by OIT for mail
node /(plutonium|pollux)\.wikimedia\.org/ {
    $cluster = 'openldap_corp_mirror'

    include standard
    include role::openldap::corp
    include base::firewall
}

# primary mail server
node 'polonium.wikimedia.org' {
    role mail::mx
    include standard
    include base::firewall

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
    }
}

# careful when moving poolcounters
node 'potassium.eqiad.wmnet' {
    include standard
    include role::poolcounter
}

# protactinium was being used as an emergency gadolinium replacement.
# Since gadolinium is back up, varnishncsa instances now send logs
# to gadolinium again.  protactinium is not being used.
node 'protactinium.wikimedia.org' {
    include standard
    include base::firewall
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[123]\.codfw\.wmnet$/ {
    include standard
}

# Tor relay
node 'radium.wikimedia.org' {
    include base::firewall
    include standard
    include base::debdeploy
    include role::tor
    salt::grain { 'debdeploy-misc-servers': value => 'true' }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'radon.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include role::authdns::server
}

# Live Recent Changes WebSocket stream
node 'rcs1001.eqiad.wmnet', 'rcs1002.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role rcstream
}

node /^rdb100[1-4]\.eqiad\.wmnet/ {
    role db::redis
}

node /^rdb200[1-4]\.codfw\.wmnet/ {
    role db::redis
}

# restbase eqiad cluster
node /^restbase100[1-9]\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include base::firewall
    include standard
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role pmacct
    include standard
}

node 'rubidium.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
node 'ruthenium.eqiad.wmnet' {
    include standard
}

node /^sca100[12]\.eqiad\.wmnet$/ {
    role sca
}

node /^scb100[12]\.eqiad\.wmnet$/ {
    role scb
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    include base::firewall

    include standard
    include role::nova::manager
    include role::mariadb::wikitech

    interface::add_ip6_mapped { 'main': }
}

node 'sodium.wikimedia.org' {
    role lists
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^(strontium|rhodium).eqiad.wmnet/ {
    include standard
    include role::puppetmaster::backend
}

node 'stat1001.eqiad.wmnet' {
    role statistics::web
    include standard
    include base::firewall
    include role::abacist
}

node 'stat1002.eqiad.wmnet' {
    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    # Include classes needed for storing and crunching
    # private data on stat1002.
    role statistics::private

    include standard

    # Make sure refinery happens before analytics::clients,
    # so that the hive role can properly configure Hive's
    # auxpath to include refinery-hive.jar.
    Class['role::analytics::refinery'] -> Class['role::analytics::clients']

    # Include analytics/refinery deployment target.
    include role::analytics::refinery
    # Include Hadoop and other analytics cluster
    # clients so that analysts can access Hadoop
    # from here.
    include role::analytics::clients

    # Set up a read only rsync module to allow access
    # to public data generated by the Analytics Cluster.
    include role::analytics::rsyncd

    # Include analytics/refinery checks that send email about
    # webrequest partitions faultyness.
    include role::analytics::refinery::data::check::email

    # Include analytics/refinery/source guard checks
    include role::analytics::refinery::guard

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    include role::analytics::password::research

    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this on
    # stat1002, but don't run any daemons.
    include ::eventlogging::package
}

# stat1003 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1003.eqiad.wmnet' {
    role statistics::cruncher
    include standard
    include base::firewall

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

node /^snapshot100[1-4]\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to modules/dataset/files/exports. One must also manually
    # run `exportfs -r` on dataset1001. (T111586)
    role snapshot::common
    include snapshot
    include snapshot::dumps
    if $::fqdn == 'snapshot1003.eqiad.wmnet' {
        include role::snapshot::cron::primary
    }
}

# codfw poolcounters
node /(subra|suhail)\.codfw\.wmnet/ {

    include standard
    include base::firewall
    include role::poolcounter
}

# https://wikitech.wikimedia.org/wiki/Terbium
node 'terbium.eqiad.wmnet' {
    include role::mediawiki::common
    include role::db::maintenance
    include role::peopleweb
    include misc::monitoring::jobqueue
    include scap::scripts
    include role::noc
    include role::mediawiki::searchmonitor
    include role::mediawiki::maintenance
    include ldap::role::client::labs

    package { 'python-mysqldb':
        ensure => installed,
    }

    include role::backup::host
    backup::set {'home': }
}

node 'tin.eqiad.wmnet' {

    role deployment::server
    include standard
    include role::labsdb::manager

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# titanium hosts archiva.wikimedia.org
node 'titanium.wikimedia.org' {
    $cluster = 'misc'
    # include firewall here, until it is on all hosts
    include base::firewall
    include standard
    include role::archiva
}

# tmh1001/tmh1002 video encoding server (precise only)
node /^tmh100[1-2]\.eqiad\.wmnet/ {
    role mediawiki::videoscaler
}

node 'uranium.wikimedia.org' {
    $ganglia_aggregator = true

    include standard
    include role::ganglia::web
    include misc::monitoring::views
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^virt100[5-7].eqiad.wmnet/ {
    # We're doing some ceph testing on these
    #  boxes.
    include standard
}

node /^virt100[1-4].eqiad.wmnet/ {
    $use_neutron = false
    role nova::compute
    include standard
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /^virt100[8-9].eqiad.wmnet/ {
    $use_neutron = false
    role nova::compute
    include standard
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /^labvirt100[0-9].eqiad.wmnet/ {
    $use_neutron = false
    openstack::nova::partition{ '/dev/sdb': }
    role nova::compute
    include standard

    if $use_neutron == true {
        include role::neutron::computenode
    }
}

# Wikidata query service
node /^wdqs100[1-2]\.eqiad\.wmnet$/ {
    role wdqs
    include standard

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
    # to update the role::zuul::production
    role gerrit::production
    include standard
    include base::firewall

}

node default {
    # Labs nodes include a different set of defaults via ldap.
    if $::realm == 'production' {
        include standard
    }
}
