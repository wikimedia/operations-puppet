# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first
import 'misc/*.pp'
import 'network.pp'
import 'role/*.pp'
import 'role/analytics/*.pp'

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
    role dnsrecursor
    include standard

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
    include base::firewall
}


# analytics1002 is the Hadoop standby NameNode.
node 'analytics1002.eqiad.wmnet' {
    role analytics::hadoop::standby

    include standard
    include base::firewall
}

# This node is being repurposed - otto 2015-09
node 'analytics1015.eqiad.wmnet' {
    role analytics::mysql::meta
    include standard
    include base::firewall
}

# analytics1028-analytics1057 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# templates/hadoop/net-topology.py.erb to make sure the
# hostname -> /datacenter/rack/row id is correct.  This is
# used for Hadoop network topology awareness.
node /analytics10(2[89]|3[0-9]|4[0-9]|5[0-7]).eqiad.wmnet/ {

    role analytics::hadoop::worker, analytics::impala::worker
    include base::firewall
    include standard
}

# This node was previously a Hadoop Worker, but is now waiting
# to be repurposed (likely as a stat* type box).
node 'analytics1017.eqiad.wmnet' {
    role spare
}

# This node was previously a kafka broker, but is now waiting
# to be repurposed (likely as a stat* type box).
node 'analytics1021.eqiad.wmnet' {
    role spare
}

# analytics1026 is the Impala master
# (llama, impala-state-store, impala-catalog)
# analytics1026 also runs misc udp2log for sqstat
node 'analytics1026.eqiad.wmnet' {

    include standard
    include role::analytics::clients
    include role::analytics::impala::master
    include role::logging::udp2log::misc
}

# analytics1027 hosts some frontend web interfaces to Hadoop
# (Hue, Oozie, Hive, etc.).  It also submits regularly scheduled
# batch Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {
    role analytics::hive::server, analytics::oozie::server, analytics::hue

    include standard
    include base::firewall

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
    role aqs
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
    role mw_rc_irc

    interface::add_ip6_mapped { 'main': }
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
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    $cluster = 'misc'
    $ganglia_aggregator = true
    role bastionhost::general
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

    role bastionhost::general, ipmi, installserver::tftp-server

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
    role bugzilla_static, annualreport, transparency
    include standard
}

# http://releases.wikimedia.org
node 'caesium.eqiad.wmnet' {
    role releases
    include standard
}

# T83044 cameras
node 'calcium.wikimedia.org' {
    $cluster = 'misc'
    role spare
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
    role installserver
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
    role dnsrecursor
    include standard

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
    role etcd, zookeeper::server
    include base::firewall
    include standard
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
    role cache::misc, ipsec
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
    role cache::misc, ipsec
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
    role cache::misc, ipsec
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
    role cache::mobile, ipsec
}

node 'dataset1001.wikimedia.org' {

    role dataset::primary, dumps
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

# s1 (enwiki) core production slave dbs on eqiad
node /^db10(51|55|57|66|72|73)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db1065\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's1',
        p_s   => 'on',
    }
}

# This mess will be eventually cleaned up and all
# servers will be on the following node:
node /^db10(53)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's1',
        p_s   => 'on',
    }
    include base::firewall
}

node /^db20(16|34|42|48|55|62|69|70)\.codfw\.wmnet/ {

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

node /^db20(17|35|41|49|56|63|64)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
    include base::firewall
}

# s3 (default) core production slave dbs on eqiad
node /^db10(15|27|35|44)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's3',
        p_s   => 'on',
    }
    include base::firewall
}

node /^db20(18|36|43|50|57)\.codfw\.wmnet/ {

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

node /^db20(19|37|44|51|58|65)\.codfw\.wmnet/ {

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

node /^db20(23|38|45|52|59|66)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
    include base::firewall
}

node /^db10(30|37|50|61)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's6',
    }
}

node /^db1022\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's6',
        p_s   => 'on',
    }
}

node /^db20(28|39|46|53|60)\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
    }
    include base::firewall
}

node /^db2067\.codfw\.wmnet/ {

    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
        p_s   => 'on',
        ssl   => 'on',
    }
    include base::firewall
}

node /^db10(28|34|39|41|62)\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 's7',
    }
}

node /^db20(29|40|47|54|61|68)\.codfw\.wmnet/ {

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
    include base::firewall
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
    # this slave has an m4 custom replication protocol
    role mariadb::analytics, mariadb::analytics::custom_repl_slave
}

node 'db1069.eqiad.wmnet' {
    role mariadb::sanitarium
    include base::firewall
}

node 'db1011.eqiad.wmnet' {
    role mariadb::tendril
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
    # this slave has an m4 custom replication protocol
    role mariadb::dbstore, mariadb::analytics::custom_repl_slave
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

node 'eeden.wikimedia.org' {
    role authdns::server

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
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

# erbium was previously  a webrequest udp2log host.
# It is currently spare.
node 'erbium.eqiad.wmnet' {
    role spare

    include standard
}

# External Storage, Shard 1 (es1) databases

node /^es101[268]\.eqiad\.wmnet/ {
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

# External Storage, Shard 2 (es2) databases

# temporary extra role for rolling restart
node /^es101[1]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}

node /^es101[35]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es2',
        p_s           => 'on',
        binlog_format => 'ROW',
    }
    include base::firewall
}

node /es200[567]\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es2',
    }
    include base::firewall
}

# External Storage, Shard 3 (es3) databases

# temporary extra role for rolling restart
node /^es101[4]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}

node /^es101[79]\.eqiad\.wmnet/ {
    class { 'role::mariadb::core':
        shard         => 'es3',
        p_s           => 'on',
        binlog_format => 'ROW',
    }
    include base::firewall
}

node /es20(08|09|10)\.codfw\.wmnet/ {
    class { 'role::mariadb::core':
        shard => 'es3',
    }
    include base::firewall
}

# Etherpad (virtual machine)
node 'etherpad1001.eqiad.wmnet' {
    role etherpad
}

# Receives log data from Kafka and Apaches (udp 8421),
# processes it, and broadcasts to Kafka Schema based topics.
node 'eventlog1001.eqiad.wmnet', 'eventlog2001.codfw.wmnet' {
    role eventlogging,
        eventlogging::forwarder,
        eventlogging::processor,
        eventlogging::consumer::mysql,
        eventlogging::consumer::files,
        logging::mediawiki::errors

    include standard
}

# virtual machine for mailman list server
node 'fermium.wikimedia.org' {
    role lists
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

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node 'gadolinium.wikimedia.org' {
    role logging, logging::relay::webrequest-multicast, logging::relay::eventlogging
    include standard
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

# poolcounter - careful
node 'helium.eqiad.wmnet' {
    role poolcounter, backup::director, backup::storage

    include standard
    include base::firewall
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Bacula storage
node 'heze.codfw.wmnet' {
    role backup::storage
    include standard
}

# Holmium will soon be renamed labservices1002
node 'holmium.wikimedia.org' {
    role labs::dns, labs::openstack::designate::server, labs::dnsrecursor
    include standard
    include base::firewall
    include ldap::role::client::labs
}

# labservices1001 hosts openstack-designate, the labs DNS service.
node 'labservices1001.wikimedia.org' {
    role labs::dns, labs::openstack::designate::server, labs::dnsrecursor
    include standard
    include base::firewall
    include ldap::role::client::labs
}

node 'labtestneutron2001.codfw.wmnet' {
    include standard
}

node 'labtestcontrol2001.wikimedia.org' {
    $is_puppet_master      = true
    $is_labs_puppet_master = true

    include standard
    role labs::openstack::nova::controller,
          labs::puppetmaster

    #role labs::openstack::nova::controller,
    #      salt::masters::labs,
    #      deployment::salt_masters,
    #      dns::ldap
    #include base::firewall
    #include ldap::role::client::labs
}

node 'labtestservices2001.wikimedia.org' {
    role labs::openstack::designate::server
    include standard
}

# bastion in the Netherlands
node 'hooft.esams.wikimedia.org' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost::general, installserver::tftp-server

    class { 'ganglia::monitor::aggregator':
        sites =>  'esams',
    }
}

# Primary graphite machines
node 'graphite1001.eqiad.wmnet' {
    role graphite::production, statsdlb, performance, graphite::alerts, restbase::alerts, graphite::alerts::reqstats
    include standard
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    role testsystem
}

# Primary graphite machines
node 'graphite2001.codfw.wmnet' {
    role graphite::production, statsdlb, gdash
    include standard
}

node 'install2001.wikimedia.org' {
    role installserver::tftp-server
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

# ticket.wikimedia.org
node 'iodine.wikimedia.org' {
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
    role phabricator::main, backup::host
    include standard
    include ganglia
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Operations Bastion',
    }
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost::opsonly, ipmi, access_new_install
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
    include base::firewall
}

# virtual machine for misc. PHP apps
node 'krypton.eqiad.wmnet' {
    # analytics::burrow is a Kafka consumer lag monitor.
    # Running this here because krypton is a 'misc' Jessie
    # <s>monitoring host</s> (not really, it's just misc apps)
    role wikimania_scholarships, iegreview, grafana, gdash, analytics::burrow, racktables, requesttracker
    include standard
}

node 'labcontrol1001.wikimedia.org' {
    $is_puppet_master      = true
    $is_labs_puppet_master = true

    role labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters,
          dns::ldap

    include base::firewall
    include standard
    include ldap::role::client::labs

    # Monitoring checks for toollabs that page
    include toollabs::monitoring::icinga
}

# labcontrol1002 is a hot spare for 1001.  Switching it on
#  involves uncommenting the dns role, below, and also
#  changing the keystone catalog to point to labcontrol1002:
#  basically repeated use of 'keystone endpoint-list,'
#  'keystone endpoint-create' and 'keystone endpoint-delete.'
node 'labcontrol1002.wikimedia.org' {
    $is_puppet_master      = true
    $is_labs_puppet_master = true

    role labs::openstack::nova::controller,
          labs::puppetmaster,
          salt::masters::labs,
          deployment::salt_masters,
          dns::ldap

    include base::firewall
    include standard
    include ldap::role::client::labs
}

node 'labcontrol2001.wikimedia.org' {
    #$ganglia_aggregator    = true
    #$is_puppet_master      = true
    #$is_labs_puppet_master = true


    include base::firewall
    include standard
    include ldap::role::client::labs

    # This box isn't doing anything these days... this change is pending
    #  decomission and rename
    #role dns::ldap, salt::masters::labs
    #include role::labs::openstack::nova::controller
    #include role::labs::openstack::nova::manager
    #include role::salt::masters::labs
    #include role::deployment::salt_masters
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    role labs::graphite
    include standard
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
node 'labsdb1001.eqiad.wmnet' {
    # this role is depecated and should be converted to labs::db::slave
    role mariadb::labs
}

node 'labsdb1002.eqiad.wmnet' {
    # this role is depecated and should be converted to labs::db::slave
    role mariadb::labs
}

node 'labsdb1003.eqiad.wmnet' {
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
    role labs::nfs::fileserver
}

node 'labstore1003.eqiad.wmnet' {
    role labs::nfs::extras
}

node /labstore200[12]\.codfw\.wmnet/ {
    $cluster = 'labsnfs'
    role labs::nfs::fileserver
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
    role dnsrecursor
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# RT and the other RT
node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    role requesttracker
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

}

node 'maps-test2001.codfw.wmnet' {
    role maps, maps::master
}

node /^maps-test200[2-4]\.codfw\.wmnet/ {
    role maps, maps::slave
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    role memcached
}

node /^mc20[01][0-9]\.codfw\.wmnet/ {
    role memcached
}

# OTRS evaluation upgrade
node 'mendelevium.eqiad.wmnet' {
    role otrs
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
    include base::firewall
}

# mw1114-mw1119 are canary api appservers
node /^mw111[4-9]\.eqiad\.wmnet$/ {
    role mediawiki::appserver::canary_api
    include base::firewall
}

# mw1120-1148 are api apaches
node /^mw11([23][0-9]|4[0-8])\.eqiad\.wmnet$/ {
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
    include role::noc
    include standard
    include ldap::role::client::labs
}


# mw1153-1160 are imagescalers (trusty)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {
    role mediawiki::imagescaler
}

# mw1161-1188 are apaches
node /^mw11(6[1-9]|7[0-9]|8[0-8])\.eqiad\.wmnet$/ {
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

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(nembus|neptunium)\.wikimedia\.org$/ {
    include standard
    include base::firewall
    include ldap::role::server::labs
    include ldap::role::client::labs
}

# secondary salt master
node 'neodymium.eqiad.wmnet' {
#    role salt::masters::production, deployment::salt_masters, debdeploy::master
    role salt::masters::production
    include standard
}

# Icinga
node 'neon.wikimedia.org' {
    role icinga, tendril, tcpircbot
}

node 'nescio.wikimedia.org' {
    role dnsrecursor
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

    interface::add_ip6_mapped { 'main': }

    class { 'ganglia::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }
}

node 'nitrogen.wikimedia.org' {
    role ipv6relay
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
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
    role ipmi, salt::masters::production, deployment::salt_masters, access_new_install, puppetmaster::frontend, pybal_config, debdeploy::master
    include standard
    include role::conftool::master
}

# parser cache databases
node /pc100[1-3]\.eqiad\.wmnet/ {
    role mariadb::parsercache
}

# virtual machine hosting https://wikitech.wikimedia.org/wiki/Planet.wikimedia.org
node 'planet1001.eqiad.wmnet' {
    role planet
}

# LDAP servers relied on by OIT for mail
node /(dubnium|pollux)\.wikimedia\.org/ {
    $cluster = 'openldap_corp_mirror'

    role openldap::corp
    include standard
}

# careful when moving poolcounters
node 'potassium.eqiad.wmnet' {
    role poolcounter
    include standard
}

# protactinium was being used as an emergency gadolinium replacement.
# Since gadolinium is back up, varnishncsa instances now send logs
# to gadolinium again.  protactinium is not being used.
node 'protactinium.wikimedia.org' {
    role spare
}

# pybal-test200X VMs are used for pybal testing/development
node /^pybal-test200[12]\.codfw\.wmnet$/ {
    role testsystem
}

# pybal-test2003 is used for pybal testing/development
# and for redis multi-instance testing/development
node 'pybal-test2003.codfw.wmnet' {
    role testsystem

    redis::instance { 6370: }
    redis::instance { 6371: }
}

# Tor relay
node 'radium.wikimedia.org' {
    role tor

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
}

node /^rdb100[1-9]\.eqiad\.wmnet/ {
    role jobqueue_redis
}

node /^rdb200[1-4]\.codfw\.wmnet/ {
    role jobqueue_redis
}

# restbase eqiad cluster
node /^restbase100[1-9]\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include standard
}

# restbase codfw cluster
node /^restbase200[1-6]\.codfw\.wmnet$/ {
    role restbase, cassandra
    include standard
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role pmacct
    include standard
}

node 'rubidium.wikimedia.org' {
    role spare

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'rutherfordium.eqiad.wmnet' {
    role peopleweb, backup::host
    include base::firewall
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
node 'ruthenium.eqiad.wmnet' {
    role testsystem
}

# T95046 install/deploy scandium as zuul merger (ci) server
node 'scandium.eqiad.wmnet' {
    # no role yet. Will use zuul::merger

    include standard
    include base::firewall
    role zuul::merger

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

node /^sca100[12]\.eqiad\.wmnet$/ {
    role sca
}

node /^scb100[12]\.eqiad\.wmnet$/ {
    role scb
}

# Codfw, eqiad ldap servers, aka ldap-$::site
node /^(seaborgium|serpens)\.wikimedia\.org$/ {
    role openldap::labs
    include standard
    include base::firewall
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    role labs::openstack::nova::manager, mariadb::wikitech
    include base::firewall
    include standard

    interface::add_ip6_mapped { 'main': }
}

node /^(strontium|rhodium).eqiad.wmnet/ {
    role puppetmaster::backend
    include standard
}

node 'stat1001.eqiad.wmnet' {
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

node /^snapshot100[124]\.eqiad\.wmnet/ {
    # NOTE: New snapshot hosts must also be manually added
    # to modules/dataset/files/exports. One must also manually
    # run `exportfs -r` on dataset1001. (T111586)
    role snapshot
    include standard
}

node /^snapshot1003\.eqiad\.wmnet/ {
    role snapshot, snapshot::cron::primary
    include standard
}

# codfw poolcounters
node /(subra|suhail)\.codfw\.wmnet/ {
    role poolcounter
    include standard
    include base::firewall
}

# https://wikitech.wikimedia.org/wiki/Terbium
node 'terbium.eqiad.wmnet' {
    role mariadb::maintenance, mediawiki::maintenance, backup::host

    include ldap::role::client::labs

    package { 'python-mysqldb':
        ensure => installed,
    }

    backup::set {'home': }

    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this but don't
    # run any daemons.  To use eventlogging code,
    # add /srv/deployment/eventlogging/eventlogging
    # to your PYTHONPATh or sys.path.
    include ::eventlogging::package
}

# deployment servers
node 'tin.eqiad.wmnet', 'mira.codfw.wmnet' {
    role deployment::server, labsdb::manager

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# titanium hosts archiva.wikimedia.org
node 'titanium.wikimedia.org' {
    $cluster = 'misc'
    # include firewall here, until it is on all hosts
    role archiva
    include standard
}

# test system for performance team (T117888)
node 'tungsten.eqiad.wmnet' {
    role testsystem
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
