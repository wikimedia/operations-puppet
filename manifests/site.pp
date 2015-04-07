# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first
import 'certs.pp'
import 'ganglia.pp'
import 'mail.pp'
import 'misc/*.pp'
import 'network.pp'
import 'nfs.pp'
import 'role/*.pp'
import 'role/analytics/*.pp'
import 'swift.pp'

# Include stages last
import 'stages.pp'

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard(
    $has_default_mail_relay = true,
) {
    include base
    include role::ntp
    include role::diamond
    if $::realm == 'production' {
        include ganglia # No ganglia in labs
    }
    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include role::mail::sender
    }
}

# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = 'misc'
}

# Node definitions (alphabetic order)

node /^(acamar|achernar)\.wikimedia\.org$/ {
    include admin
    include base::firewall
    include standard

    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# amssq31-62 are text varnish (and the only nodes with this legacy prefix)
node /^amssq[0-9]+\.esams\.(wmnet|wikimedia\.org)$/ {
    sysctl::parameters { 'vm dirty page flushes':
        values => {
            'vm.dirty_background_ratio' => 5,
        }
    }
    role cache::text
    interface::add_ip6_mapped { 'main': }
}


# analytics1003 is being used for testing kafkatee
# in preperation for replacing udp2log
node 'analytics1003.eqiad.wmnet' {
    role analytics

    include standard
    include admin

    # Disabling these for now.
    # analytics1003 is acting up since the Trusty upgrade. I halts with:
    #   BUG: unable to handle kernel NULL pointer dereference at 00000000000001be
    #
    # include role::analytics::kafkatee::webrequest::mobile
    # include role::analytics::kafkatee::webrequest::edits
    # include role::analytics::kafkatee::webrequest::5xx
    # include role::analytics::kafkatee::webrequest::api
    # include role::analytics::kafkatee::webrequest::glam_nara
}


# analytics1001 is the Hadoop master node:
# - primary active NameNode
# - YARN ResourceManager
node 'analytics1001.eqiad.wmnet' {
    role analytics::hadoop::master

    include standard
    include admin
}


# analytics1002 is the Hadoop standby NameNode.
node 'analytics1002.eqiad.wmnet' {
    role analytics::hadoop::standby

    include standard
    include admin
}

# analytics1004 was previously the Hadoop standby NameNode
# It is being deprecated.
node 'analytics1004.eqiad.wmnet' {
    include admin
    include standard
}

# analytics1010 was previously the Hadoop master.
# It is being deprecated.
node 'analytics1010.eqiad.wmnet' {
    include admin
    include standard
}

# analytics1011, analytics1013-analytics1017, analytics1019, analytics1020,
# analytics1028-analytics1041 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# templates/hadoop/net-topology.py.erb to make sure the
# hostname -> /datacenter/rack/row id is correct.  This is
# used for Hadoop network topology awareness.
node /analytics10(11|1[3-7]|19|2[089]|3[0-9]|4[01]).eqiad.wmnet/ {
    # analytics1013 is a Ganglia aggregator for Row A
    # analytics1014 is a Ganglia aggregator for Row C
    # analytics1019 is a Ganglia aggregator for Row D
    if $::hostname =~ /^analytics101[349]$/ {
        $ganglia_aggregator = true
    }
    role analytics::hadoop::worker
    include admin
    include standard
}

# analytics1012, analytics1018, analytics1021 and analytics1022 are Kafka Brokers.
node /analytics10(12|18|21|22)\.eqiad\.wmnet/ {
    # one ganglia aggregator per ganglia 'cluster' per row.
    if ($::hostname == 'analytics1012' or  # Row A
        $::hostname == 'analytics1018' or  # Row D
        $::hostname == 'analytics1022')    # Row C
    {
        $ganglia_aggregator = true
    }

    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }

    role analytics::kafka::server
    include role::analytics
    include standard
    include admin

}

# analytics1023-1025 are zookeeper server nodes
node /analytics102[345].eqiad.wmnet/ {
    role analytics
    include standard
    include admin
    include role::analytics::zookeeper::server
}

# analytics1026 runs misc udp2log for sqstat
node 'analytics1026.eqiad.wmnet' {

    include standard
    include admin
    include role::logging::udp2log::misc
}

# analytics1027 hosts some frontend web interfaces to Hadoop
# (Hue, Oozie, Hive, etc.).  It also submits regularly scheduled
# batch Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {

    include admin
    include standard

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
}



# git.wikimedia.org
node 'antimony.wikimedia.org' {
    role gitblit
    include admin
    include base::firewall
    include standard
    include role::subversion
}

# irc.wikimedia.org
node 'argon.wikimedia.org' {
    include admin
    include standard
    include role::mw-rc-irc
}

node 'baham.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include admin
    include role::authdns::server
}

node 'bast1001.wikimedia.org' {

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    $cluster = 'misc'
    $ganglia_aggregator = true
    role bastionhost

    include admin
    include standard
    include subversion::client
    include dsh
    include ssh::hostkeys-collect
    class { 'nfs::netapp::home':
        mountpoint => '/srv/home_pmtpa',
        mount_site => 'pmtpa',
    }
    include role::backup::host
    backup::set {'home': }
}

node 'bast2001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost
    include admin
    include standard

}

node 'bast4001.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    role bastionhost
    include admin
    include standard
    include role::ipmi
    include role::installserver::tftp-server
}

# IPsec testing
node /^(berkelium|curium)\.eqiad\.wmnet$/ {
    $cluster = 'misc'
    include standard
    include admin
    interface::add_ip6_mapped { 'main': }
    rsyslog::conf { 'remote_logstash':
        content  => "*.* @logstash1002.eqiad.wmnet:10514",
        priority => 32,
    }
    role ipsec
}

# http://releases.wikimedia.org
node 'caesium.eqiad.wmnet' {
    role releases
    include base::firewall
    include admin
    include standard
}

# T83044 cameras
node 'calcium.wikimedia.org' {
    $cluster = 'misc'

    include admin
    include standard

    include base::firewall
}

# Californium hosts openstack-dashboard AKA horizon
#  It's proxied by the misc-web varnishes
node 'californium.wikimedia.org' {
    include standard
    include admin
    include role::horizon

    class { 'base::firewall': }
}

# DHCP / TFTP
node 'carbon.wikimedia.org' {
    $cluster = 'misc'
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::installserver
}

# cerium, praseodymium and xenon are Cassandra test hosts
node /^(cerium|praseodymium|xenon)\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include base::firewall
    include standard
    include admin
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
    include admin
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

# cp1008: prod-like SSL test host
node 'cp1008.wikimedia.org' {
    role cache::text, ipsec
    interface::add_ip6_mapped { 'main': }
}

node /^cp104[34]\.eqiad\.wmnet$/ {
    $ganglia_aggregator = true
    interface::add_ip6_mapped { 'main': }
    role cache::misc
}

node 'cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet' {
    $ganglia_aggregator = true
    interface::add_ip6_mapped { 'main': }
    role cache::parsoid
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    if $::hostname =~ /^cp104[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::mobile
}

node /^cp10(4[89]|5[01]|6[1-4]|7[1-4])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^(cp1048|cp1061)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::upload
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^cp105[23]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::text
}

node 'cp1056.eqiad.wmnet', 'cp1057.eqiad.wmnet', 'cp1069.eqiad.wmnet', 'cp1070.eqiad.wmnet' {
    if $::hostname =~ /^cp105[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::bits
}

node /^cp30(0[3-9]|10|1[5-8])\.esams\.(wikimedia\.org|wmnet)$/ {
    if $::hostname =~ /^cp300[34]$/ {
        $ganglia_aggregator = true
    }
    $cluster = 'cache_upload'
    interface::add_ip6_mapped { 'main': }

    role cache::upload
}

node /^cp301[1234]\.esams\.(wikimedia\.org|wmnet)$/ {
    interface::add_ip6_mapped { 'main': }
    role cache::mobile
}

node /^cp(3019|302[0-2])\.esams\.(wikimedia\.org|wmnet)$/ {
    if $::hostname =~ /^cp(3019|3020)$/ {
        $ganglia_aggregator = true
    }
    interface::add_ip6_mapped { 'main': }
    role cache::bits
}

#
# ulsfo varnishes
#

node /^cp400[1-4]\.ulsfo\.wmnet$/ {
    # cp4001 and cp4003 are in different racks,
    # make them each ganglia aggregators.
    if $::hostname =~ /^cp(4001|4003)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::bits
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4005|4013)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::upload
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4008|4016)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }
    role cache::text
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp401[19]$/ {
        $ganglia_aggregator = true
    }
    interface::add_ip6_mapped { 'main': }
    role cache::mobile
}

node 'dataset1001.wikimedia.org' {

    include admin
    include standard
    include role::dataset::systemusers
    include role::dataset::primary
    include role::dumps

    interface::add_ip6_mapped { 'eth2':
        interface => 'eth2',
    }
}

# eqiad dbs

node /^db10(18)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s2':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(52)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s1':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(19|38)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s3':
        # Many more tables than other shards.
        # innodb_file_per_table=off to reduce file handles.
        innodb_file_per_table => false,
        mariadb               => true,
    }
}

node /^db10(40|53)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s4':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(21|26|45|58)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s5':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(22|23|30)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s6':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(33|34|41)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s7':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

# MariaDB 10

node /^db10(51|55|57|65|66|72|73)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db20(16|34)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db10(36|54|60|63|67)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
}

node /^db20(17|35)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
}

node /^db10(15|27|35|44)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's3',
    }
}

node /^db20(18|36)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's3',
    }
}

node /^db10(42|56|59|64|68|70)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's4',
    }
}

node /^db20(19|37)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's4',
    }
}

node /^db10(49|71)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
}

node /^db20(23|38)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
}

node /^db10(37|50|61)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
    }
}

node /^db20(28|39)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
    }
}

node /^db10(28|39|62)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's7',
    }
}

node /^db20(29|40)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's7',
    }
}

## x1 shard
node /^db10(29|31)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    include role::coredb::x1
}

node /^db20(09)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'x1',
    }
}

## m1 shard
node /^db10(01)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

node 'db1016.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc':
        shard  => 'm1',
        master => true,
    }
}

node /^db20(10|30)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc':
        shard => 'm1',
    }
}

## m2 shard
node /^db10(20)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc':
        shard => 'm2',
    }
}

node /^db20(11)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc':
        shard => 'm2',
    }
}

## m3 shard
node 'db1043.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc::phabricator':
        shard  => 'm3',
        master => true,
    }
}

node 'db1048.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc::phabricator':
        shard    => 'm3',
        snapshot => true,
    }
}

node /^db20(12)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc::phabricator':
        shard => 'm3',
    }
}

# m4 shard
node 'db1046.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::misc::eventlogging':
        shard  => 'm4',
        master => true,
    }
}

## researchdb s1
node 'db1047.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    include role::mariadb::analytics
}

node 'db1069.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    $ganglia_aggregator = true
    include role::mariadb::sanitarium
}

node 'db1011.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    include role::mariadb::tendril
}

node 'dbstore1001.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    $ganglia_aggregator = true
    include role::mariadb::backup
    # 24h delay on all repl streams
    class { 'role::mariadb::dbstore':
        lag_warn => 90000,
        lag_crit => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
}

node 'dbstore1002.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    $ganglia_aggregator = true
    include role::mariadb::dbstore
}

node 'dbstore2001.codfw.wmnet' {
    include admin
    $cluster = 'mysql'
    # 24h delay on all repl streams
    class { 'role::mariadb::dbstore':
        lag_warn => 90000,
        lag_crit => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
}

node 'dbstore2002.codfw.wmnet' {
    include admin
    $cluster = 'mysql'
    include role::mariadb::dbstore
}

node 'dbproxy1001.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::proxy::master':
        shard          => 'm1',
        primary_name   => 'db1001',
        primary_addr   => '10.64.0.5',
        secondary_name => 'db1016',
        secondary_addr => '10.64.0.20',
    }
}

node 'dbproxy1002.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::proxy::master':
        shard          => 'm2',
        primary_name   => 'db1020',
        primary_addr   => '10.64.16.9',
        secondary_name => 'db2011',
        secondary_addr => '10.192.0.14',
    }
}

node 'dbproxy1003.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::proxy::master':
        shard          => 'm3',
        primary_name   => 'db1043',
        primary_addr   => '10.64.16.32',
        secondary_name => 'db1048',
        secondary_addr => '10.64.16.37',
    }
}

node 'dbproxy1004.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::proxy::master':
        shard          => 'm4',
        primary_name   => 'db1046',
        primary_addr   => '10.64.16.35',
        secondary_name => 'db1047',
        secondary_addr => '10.64.16.36',
    }
}

node 'dysprosium.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main': }
    role cache::text
}

node 'eeden.esams.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include admin
    include role::authdns::server
}

node 'einsteinium.eqiad.wmnet' {
    include standard
    include admin
    system::role { 'Titan test host': }
}

node /^elastic10[0-3][0-9]\.eqiad\.wmnet/ {
    if $::hostname =~ /^elastic10(0[17]|13)/ {
        $ganglia_aggregator = true
    }

    role elasticsearch::server
}

# erbium is a webrequest udp2log host
node 'erbium.eqiad.wmnet' inherits 'base_analytics_logging_node' {
    # gadolinium hosts the separate nginx webrequest udp2log instance.

    include admin
    include role::logging::udp2log::erbium
}

# es1 equad
node /es100[34]\.eqiad\.wmnet/ {
    include admin

    $cluster = 'mysql'
    class { 'role::coredb::es1':
        mariadb => true,
    }
}

node /es100[12]\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es1',
    }
}

node /es100[5]\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}

node /es100[67]\.eqiad\.wmnet/ {
    include admin
    $cluster = 'mysql'
    class { 'role::coredb::es2':
        mariadb => true,
    }
}

node /es200[1234]\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es1',
    }
}

node /es200[567]\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}

node /es100[9]\.eqiad\.wmnet/ {
    include admin
    $cluster = 'mysql'
    class { 'role::coredb::es3':
        mariadb => true,
    }
}

node /es10(08|10)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}

node /es20(08|09|10)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}

# Receives log data from varnishes (udp 8422) and Apaches (udp 8421),
# processes it, and broadcasts to internal subscribers.
node 'eventlog1001.eqiad.wmnet' {
    role eventlogging
    include admin
    include standard
    include role::ipython_notebook
    include role::logging::mediawiki::errors
}

node 'fluorine.eqiad.wmnet' {
    $cluster = 'misc'

    include admin
    include standard
    include ::role::xenon

    class { 'role::logging::mediawiki':
        monitor       => false,
        log_directory => '/a/mw-log',
    }

}

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node 'gadolinium.wikimedia.org' inherits 'base_analytics_logging_node' {
    include admin

    # relay the incoming webrequest log stream to multicast
    include role::logging::relay::webrequest-multicast
    # relay EventLogging traffic over to eventlog1001
    include role::logging::relay::eventlogging
}

node 'gallium.wikimedia.org' {

    $cluster = 'misc'

    include admin

    # Bug 49846, let us sync VisualEditor in mediawiki/extensions.git
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

    # gallium received a SSD drive (RT #4916) mount it
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

node /^ganeti[12]00[0-9]\.(codfw|eqiad)\.wmnet$/ {
    include standard
    include admin
    include role::ganeti
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.wikimedia.org' {
    role eventlogging::graphite
    include standard
    include admin
    include base::firewall
    include role::webperf
}

node 'helium.eqiad.wmnet' {
    include admin
    include standard
    include role::poolcounter
    include role::backup::director
    include role::backup::storage
}

node 'heze.codfw.wmnet' {
    include admin
    include standard
    include role::backup::storage
}

# Holmium hosts openstack-designate, the labs DNS service.
node 'holmium.wikimedia.org' {
    include standard
    include admin

    include base::firewall
    include role::labsdns
    include role::designate::server
}

node 'hooft.esams.wikimedia.org' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    role bastionhost

    include admin
    include standard
    include role::installserver::tftp-server

    class { 'ganglia_new::monitor::aggregator':
        sites =>  'esams',
    }
}

# Primary graphite machines, replacing tungsten
node 'graphite1001.eqiad.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::statsdlb
    include role::gdash
    include role::performance
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1002.eqiad.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::txstatsd
    include role::gdash
}

# Primary graphite machines, replacing tungsten
node 'graphite2001.codfw.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::txstatsd
    include role::gdash
}

node 'install2001.wikimedia.org' {
    $cluster = 'misc'
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::installserver::tftp-server

    class { 'ganglia_new::monitor::aggregator':
        sites =>  'codfw',
    }
}

node 'iodine.wikimedia.org' {
    class { 'base::firewall': }
    role otrs

    include admin

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'iridium.eqiad.wmnet' {
    class { 'base::firewall': }

    # Broken as dupe exim class T92879
    # https://phabricator.wikimedia.org/rOPUP2f5cde0ed76bd61229aefd12221a87ff40a1d7c8
    # Duplicate declaration: Class[Exim4]
    # include standard
    role phabricator::main
    include base
    include admin
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

    include admin
    include standard
    include role::ipmi
    include role::access_new_install
    include role::backup::host
    backup::set {'home': }
}

node 'labcontrol2001.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    #$is_puppet_master      = true
    #$is_labs_puppet_master = true
    #$use_neutron           = false

    include standard
    include admin
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
    include admin
}

node 'labnet1001.eqiad.wmnet' {
    $cluster = 'virt'
    $use_neutron = false

    $ganglia_aggregator = true

    include standard
    include admin
    include role::nova::api

    if $use_neutron == true {
        include role::neutron::nethost
    } else {
        include role::nova::network
    }
}

## labsdb dbs
node 'labsdb1001.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    include role::mariadb::labs
}

node 'labsdb1002.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    include role::mariadb::labs
}

node 'labsdb1003.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    include role::mariadb::labs
}

node 'labsdb1004.eqiad.wmnet' {
    include admin
    $postgres_slave = 'labsdb1005.eqiad.wmnet'
    $postgres_slave_v4 = '10.64.37.9'

    include role::postgres::master
    # include role::labs::db::slave
}

node 'labsdb1005.eqiad.wmnet' {
    include admin
    $postgres_master = 'labsdb1004.eqiad.wmnet'

    include role::postgres::slave
    # include role::labs::db::master
}

node 'labsdb1006.eqiad.wmnet' {
    include admin
    $osm_slave = 'labsdb1007.eqiad.wmnet'
    $osm_slave_v4 = '10.64.37.12'

    include role::osm::master
    # include role::labs::db::slave
}

node 'labsdb1007.eqiad.wmnet' {
    include admin
    $osm_master = 'labsdb1006.eqiad.wmnet'

    include role::osm::slave
    # include role::labs::db::master
}

node /labstore100[12]\.eqiad\.wmnet/ {
    if $::hostname == 'labstore1001' {
        $ganglia_aggregator = true
    }
    $site = 'eqiad'
    $cluster = 'labsnfs'

    role labs::nfs::fileserver

}

node 'labstore1003.eqiad.wmnet' {
    $ganglia_aggregator = true
    $site = 'eqiad'
    $cluster = 'labsnfs'

    role labs::nfs::dumps
}

node /labstore200[12]\.codfw\.wmnet/ {

    $site = 'codfw'
    $cluster = 'labsnfs'

    role labs::nfs::fileserver

}

node 'lanthanum.eqiad.wmnet' {

    include standard
    include admin
    include role::ci::slave
    # lanthanum received a SSD drive just like gallium (RT #5178) mount it
    file { '/srv/ssd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }
    mount { '/srv/ssd':
        ensure  => 'mounted',
        device  => '/dev/sdb1',
        fstype  => 'xfs',
        options => 'noatime,nodiratime,nobarrier,logbufs=8',
        require => File['/srv/ssd'],
    }

}

node 'lead.wikimedia.org' {
    role mail::mx
    include standard
    include admin
    interface::add_ip6_mapped { 'main': }
}

node 'lithium.eqiad.wmnet' {

    include admin
    include standard
    include role::backup::host
    include role::syslog::centralserver
}

node /^logstash100[1-3]\.eqiad\.wmnet$/ {
    if $::hostname =~ /^logstash100[13]$/ {
        $ganglia_aggregator = true
    }
    role logstash, kibana, logstash::apifeatureusage
}

node /lvs100[1-6]\.wikimedia\.org/ {

    if $::hostname =~ /^lvs100[12]$/ {
        $ganglia_aggregator = true
    }

    # lvs100[25] are LVS balancers for the eqiad recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (chromium and hydrogen) with fallback to codfw
    if $::hostname =~ /^lvs100[25]$/ {
        $nameservers_override = [ '208.80.154.157', '208.80.154.50', '208.80.153.254' ]
    }

    role lvs::balancer
    include admin

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

# codfw lvs
node /lvs200[1-6]\.codfw\.wmnet/ {

    if $::hostname =~ /^lvs200[12]$/ {
        $ganglia_aggregator = true
    }

    # lvs200[25] are LVS balancers for the codfw recursive DNS IP,
    #   so they need to use the recursive DNS backends directly
    #   (acamar and achernar) with fallback to eqiad
    if $::hostname =~ /^lvs200[25]$/ {
        $nameservers_override = [ '208.80.153.12', '208.80.153.42', '208.80.154.239' ]
    }
    role lvs::balancer
    include admin

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
                v6_token       => true,
            }
            # Row B subnets on eth1
            interface::tagged { 'eth1.2002':
                base_interface => 'eth1',
                vlan_id        => '2002',
                address        => $ips['public1-b-codfw'][$::hostname],
                netmask        => '255.255.255.224',
                v6_token       => true,
            }
            interface::tagged { 'eth1.2018':
                base_interface => 'eth1',
                vlan_id        => '2018',
                address        => $ips['private1-b-codfw'][$::hostname],
                netmask        => '255.255.252.0',
                v6_token       => true,
            }
        }
        /^lvs200[4-6]$/: {
            # Row B subnets on eth0
            interface::tagged { 'eth0.2002':
                base_interface => 'eth0',
                vlan_id        => '2002',
                address        => $ips['public1-b-codfw'][$::hostname],
                netmask        => '255.255.255.224',
                v6_token       => true,
            }
            # Row A subnets on eth1
            interface::tagged { 'eth1.2001':
                base_interface => 'eth1',
                vlan_id        => '2001',
                address        => $ips['public1-a-codfw'][$::hostname],
                netmask        => '255.255.255.224',
                v6_token       => true,
            }
            interface::tagged { 'eth1.2017':
                base_interface => 'eth1',
                vlan_id        => '2017',
                address        => $ips['private1-a-codfw'][$::hostname],
                netmask        => '255.255.252.0',
                v6_token       => true,
            }
        }
    }

    # Row C subnets on eth2
    interface::tagged { 'eth2.2003':
        base_interface => 'eth2',
        vlan_id        => '2003',
        address        => $ips['public1-c-codfw'][$::hostname],
        netmask        => '255.255.255.224',
        v6_token       => true,
    }
    interface::tagged { 'eth2.2019':
        base_interface => 'eth2',
        vlan_id        => '2019',
        address        => $ips['private1-c-codfw'][$::hostname],
        netmask        => '255.255.252.0',
        v6_token       => true,
    }

    # Row D subnets on eth3
    interface::tagged { 'eth3.2004':
        base_interface => 'eth3',
        vlan_id        => '2004',
        address        => $ips['public1-d-codfw'][$::hostname],
        netmask        => '255.255.255.224',
        v6_token       => true,
    }
    interface::tagged { 'eth3.2020':
        base_interface => 'eth3',
        vlan_id        => '2020',
        address        => $ips['private1-d-codfw'][$::hostname],
        netmask        => '255.255.252.0',
        v6_token       => true,
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
    if $::hostname =~ /^lvs300[24]$/ {
        $nameservers_override = [ '91.198.174.106', '91.198.174.122', '208.80.154.239' ]
    }

    role lvs::balancer
    include admin

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
    # lvs4001 and lvs4003 are in different racks
    if $::hostname =~ /^lvs400[13]$/ {
        $ganglia_aggregator = true
    }

    role lvs::balancer
    include admin

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    lvs::interface-tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
    }
}

node 'maerlant.wikimedia.org' {
    include admin
    include standard
    include base::firewall
    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    class { 'base::firewall': }

    role racktables, requesttracker

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    if $::hostname =~ /^mc100[12]$/ {
        $ganglia_aggregator = true
    }

    role memcached
    include admin
    include passwords::redis

    file { '/a':
        ensure => 'directory',
    }

    include redis
    include redis::ganglia
}


node /^mc20[01][0-9]\.codfw\.wmnet/ {
    role memcached
    include admin
    include passwords::redis
    include redis
    include redis::ganglia
}

node 'multatuli.wikimedia.org' {
    include admin
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'ms1001.wikimedia.org' {
    $cluster = 'misc'

    include admin

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include role::dataset::systemusers
    include role::dataset::secondary
    include role::dumps
}

node 'ms1002.eqiad.wmnet' {
    include admin
    include standard
}

# Whenever adding a new node there, you have to ask MediaWiki to recognize the
# new server IP as a trusted proxy so X-Forwarded-For headers are trusted for
# rate limiting purposes (bug 64622)
node /^ms-fe100[1-4]\.eqiad\.wmnet$/ {
    if $::hostname =~ /^ms-fe100[12]$/ {
        $ganglia_aggregator = true
    }
    role swift::eqiad_prod::proxy
    if $::hostname == 'ms-fe1001' {
        include role::swift::eqiad_prod::ganglia_reporter
    }

    class { 'lvs::realserver': realserver_ips => [ '10.2.2.27' ] }

    include role::diamond
}

node /^ms-be10(0[0-9]|1[0-5])\.eqiad\.wmnet$/ {
    $all_drives = [
        '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh',
        '/dev/sdi', '/dev/sdj', '/dev/sdk', '/dev/sdl'
    ]

    role swift::eqiad_prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sdm3': }
    swift::label_filesystem{ '/dev/sdn3': }
    swift::mount_filesystem{ '/dev/sdm3': }
    swift::mount_filesystem{ '/dev/sdn3': }
}

# HP machines have different disk ordering T90922
node /^ms-be101[678]\.eqiad\.wmnet$/ {
    $all_drives = [
        '/dev/sdm', '/dev/sdn', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh',
        '/dev/sdi', '/dev/sdj', '/dev/sdk', '/dev/sdl'
    ]

    role swift::eqiad_prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sda3': }
    swift::label_filesystem{ '/dev/sdb3': }
    swift::mount_filesystem{ '/dev/sda3': }
    swift::mount_filesystem{ '/dev/sdb3': }
}

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    role swift::esams_prod::proxy
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    # 720xd *without* SSDs; sda & sdb serve both as root and as Swift disks
    $all_drives = [
        '/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf',
        '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj',
        '/dev/sdk', '/dev/sdl'
    ]

    role swift::esams_prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }

    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sda3': }
    swift::label_filesystem{ '/dev/sdb3': }
    swift::mount_filesystem{ '/dev/sda3': }
    swift::mount_filesystem{ '/dev/sdb3': }
}

node /^ms-fe200[1-4]\.codfw\.wmnet$/ {
    if $::hostname =~ /^ms-fe200[12]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'ms-fe2001' {
        include role::swift::stats_reporter
    }

    role swift::proxy
    include ::lvs::realserver
}

node /^ms-be20[0-9][0-9]\.codfw\.wmnet$/ {
    role swift::storage
}

# mw1001-1016 are jobrunners
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw100[12]$/ {
        $ganglia_aggregator = true
    }
    role mediawiki::jobrunner
}

# mw1017-mw1025 are canary appservers
node /^mw10(1[7-9]|2[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::canary_appserver
}

# mw1026-mw1113 are appservers
node /^mw1(02[6-9]|0[3-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw10(5[45])$/ {
        $ganglia_aggregator = true
    }

    role mediawiki::appserver
}

# mw1114-mw1119 are canary api appservers
node /^mw111[4-9]\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw111[45]$/ {
        $ganglia_aggregator = true
    }
    role mediawiki::appserver::canary_api
}

# mw1120-1148 are api apaches
node /^mw11([23][0-9]|4[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}


# mw1149-1151 are apaches
node /^mw11(49|5[0-1])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
}

# mw1152 is (temporarily) the HAT imagescaler
node 'mw1152.eqiad.wmnet' {
    role mediawiki::imagescaler
}


# mw1153-1160 are imagescalers (precise)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw115[34]$/ {
        $ganglia_aggregator = true
    }

    role mediawiki::imagescaler
}

# mw1161-1188 are apaches
node /^mw11(6[1-9]|7[0-9]|8[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
}

# mw1189-1208 are api apaches
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}

# mw1209-1220 are apaches
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {
    role mediawiki::appserver
}

#mw1221-mw1235 are api apaches
node /^mw12(2[1-9]|3[0-5])\.eqiad\.wmnet$/ {
    role mediawiki::appserver::api
}

#mw1236-mw1258 are apaches
node /^mw12(3[6-9]|4[0-9]|5[0-8])\.eqiad\.wmnet$/ {
    role mediawiki::appserver
}

# ROW A codfw appservers: mw2001-mw2079
#mw2001-mw2006 are jobrunners
node /^mw200[0-6]\.codfw\.wmnet$/ {
    if $::hostname == 'mw2001' {
        $ganglia_aggregator = true
    }
    role mediawiki::jobrunner
}

#mw2007 is a videoscaler
node 'mw2007.codfw.wmnet' {
    role mediawiki::videoscaler
}

#mw2008-mw2049 are appservers
node /^mw20(0[89]|[1-4][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
}

#mw2050-2079 are api appservers
node /^mw20[5-7][0-9]\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
}

# ROW B codfw appservers: mw2080-mw2147
#mw2080-mw2085 are jobrunners
node /^mw208[0-5]\.codfw\.wmnet$/ {
    if $::hostname == 'mw2080' {
        $ganglia_aggregator = true
    }
    role mediawiki::jobrunner
}

#mw2086-mw2089 are imagescalers
node /^mw208[6-9]\.codfw\.wmnet$/ {
    role mediawiki::imagescaler
}

#mw2090-mw2119 are appservers
node /^mw2(09[0-9]|1[0-1][0-9])\.codfw\.wmnet$/ {
    role mediawiki::appserver
}

#mw2120-2147 are api appservers
node /^mw21([2-3][0-9]|4[0-7])\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
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
}

#mw2200-2234 are api appservers
node /^mw22([0-2][0-9]|3[0-4])\.codfw\.wmnet$/ {
    role mediawiki::appserver::api
}

# Codfw ldap server, aka ldap-codfw
node 'nembus.wikimedia.org' {
    $cluster               = 'virt'

    include standard
    include admin
    include ldap::role::server::labs
    include ldap::role::client::labs
}

node 'neon.wikimedia.org' {
    class { 'base::firewall': }

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    include standard
    include admin
    include role::icinga
    include role::ishmael
    include role::tendril
    include role::tcpircbot
}

# Eqiad ldap server, aka ldap-eqiad
node 'neptunium.wikimedia.org' {
    $cluster               = 'virt'

    include standard
    include admin
    include ldap::role::server::labs
    include ldap::role::client::labs
}

node 'nescio.wikimedia.org' {
    include admin
    include standard
    include base::firewall
    include role::dnsrecursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'netmon1001.wikimedia.org' {
    include admin
    include standard
    include webserver::apache
    include role::rancid
    include smokeping
    include smokeping::web
    include role::librenms
    include passwords::network
    include ganglia::collector
    include role::servermon
    include role::torrus

    interface::add_ip6_mapped { 'main': }

    class { 'ganglia_new::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }


}

node 'nitrogen.wikimedia.org' {
    include standard
    include admin
    include role::ipv6relay

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^ocg100[123]\.eqiad\.wmnet$/ {
    # Mainrole: pdf!
    $ganglia_aggregator = hiera('ganglia_aggregator', false)
    role ocg
}

# VisualEditor performance testing rig
node 'osmium.eqiad.wmnet' {
    include ::standard
    role ve
}

# base_analytics_logging_node is defined in role/logging.pp
node 'oxygen.wikimedia.org' inherits 'base_analytics_logging_node' {

    include admin
    include role::dataset::systemusers

    # main oxygen udp2log handles mostly Wikipedia Zero webrequest logs
        include role::logging::udp2log::oxygen
}

node 'palladium.eqiad.wmnet' {
    include standard
    include admin
    include role::ipmi
    include role::salt::masters::production
    include role::deployment::salt_masters
    include role::access_new_install
    include role::puppetmaster::frontend
    include role::pybal_config
}

node /pc100[1-3]\.eqiad\.wmnet/ {
    $cluster = 'mysql'
    include admin
    include role::db::core
    include mysql_wmf::mysqluser
    include mysql_wmf::datadirs
    include mysql_wmf::pc::conf
    include mysql_wmf::packages

    system::role { 'mysql::pc::conf':
        description => 'parser cache mysql server',
    }
}

node /(plutonium|pollux)\.wikimedia\.org/ {
    $cluster = 'openldap_corp_mirror'
    $ganglia_aggregator = true

    include admin

    include standard
    include role::openldap::corp
    include base::firewall
}

node 'polonium.wikimedia.org' {
    role mail::mx
    include standard
    include admin

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

node 'potassium.eqiad.wmnet' {
    include admin
    include standard
    include role::poolcounter
}

# protactinium was being used as an emergency gadolinium replacement.
# Since gadolinium is back up, varnishncsa instances now send logs
# to gadolinium again.  protactinium is not being used.
node 'protactinium.wikimedia.org' {
    include admin
}

node 'radium.wikimedia.org' {
    class { 'base::firewall': }
    include admin
    include standard
    include role::tor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# Live Recent Changes WebSocket stream
node 'rcs1001.eqiad.wmnet', 'rcs1002.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    $ganglia_aggregator = ( $::hostname == 'rcs1001' )
    role rcstream
}

node /^rdb100[1-4]\.eqiad\.wmnet/ {
    $ganglia_aggregator = true
    role db::redis
    include admin
}

node /^rdb200[1-4]\.codfw\.wmnet/ {
    role db::redis
    include admin
}

# restbase eqiad cluster
node /^restbase100[1-6]\.eqiad\.wmnet$/ {
    role restbase, cassandra
    include base::firewall
    include standard
    include admin
}

# network insights (netflow/pmacct, etc.)
node 'rhenium.wikimedia.org' {
    role pmacct
    include standard
    include admin
}

node 'rubidium.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include admin
    include role::authdns::server
}

# ruthenium is a parsoid regression test server
# https://www.mediawiki.org/wiki/Parsoid/Round-trip_testing
node 'ruthenium.eqiad.wmnet' {
    include admin
    include standard
}

node /^sca100[12]\.eqiad\.wmnet$/ {
    $ganglia_aggregator = true
    role sca
}

# Silver is the new home of the wikitech web server.
node 'silver.wikimedia.org' {
    class { 'base::firewall': }

    include standard
    include admin
    include role::nova::manager
    include role::mariadb::wikitech
}

node 'sodium.wikimedia.org' {
    include admin
    include base
    include ganglia
    include role::ntp
    include role::mail::lists

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'strontium.eqiad.wmnet' {
    include standard
    include admin
    include role::puppetmaster::backend
}

node 'stat1001.eqiad.wmnet' {
    role statistics::web
    include admin
    include standard
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
    include admin

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
}

# stat1003 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1003.eqiad.wmnet' {
    role statistics::cruncher
    include standard
    include admin

    # NOTE: This will be moved to another class
    # someday, probably standard.
    class { 'base::firewall': }


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
    role snapshot::common
    include snapshot
    include snapshot::dumps
    if $::fqdn == 'snapshot1003.eqiad.wmnet' {
        include role::snapshot::cron::primary
    }
}

# codfw poolcounters
node /(subra|suhail)\.codfw\.wmnet/ {

    include admin
    include standard
    include base::firewall
    include role::poolcounter
}

node 'terbium.eqiad.wmnet' {
    include role::mediawiki::common
    include role::db::maintenance
    include role::peopleweb
    include misc::monitoring::jobqueue
    include scap::scripts
    include role::noc
    include role::mediawiki::searchmonitor

    include admin
    include ldap::role::client::labs

    include misc::maintenance::pagetriage
    include misc::maintenance::translationnotifications
    include misc::maintenance::updatetranslationstats
    include misc::maintenance::wikidata
    include misc::maintenance::echo_mail_batch
    include misc::maintenance::parsercachepurging
    include misc::maintenance::cleanup_upload_stash
    include misc::maintenance::tor_exit_node
    include misc::maintenance::update_flaggedrev_stats
    include misc::maintenance::refreshlinks
    include misc::maintenance::update_special_pages
    include misc::maintenance::update_article_count
    include misc::maintenance::purge_abusefilter
    include misc::maintenance::purge_checkuser

    # Revert of https://gerrit.wikimedia.org/r/74592 per request from James Alexander.
    class { '::misc::maintenance::purge_securepoll':
        ensure => absent,
    }

    # (bug 15434) Periodical run of currently disabled special pages
    # to be run against PMTPA slaves
    include misc::maintenance::updatequerypages

    package { 'python-mysqldb':
        ensure => installed,
    }

    include role::backup::host
    backup::set {'home': }
}

node 'tin.eqiad.wmnet' {
    $cluster = 'misc'

    include standard
    include role::deployment::server
    include mysql
    include role::labsdb::manager
    include ssh::hostkeys-collect
    include role::releases::upload
    include admin

    # for reedy RT #6322
    package { 'unzip':
        ensure => 'present',
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include role::backup::host
    backup::set {'home': }
}

# titanium hosts archiva.wikimedia.org
node 'titanium.wikimedia.org' {
    $cluster = 'misc'
    # include firewall here, until it is on all hosts
    class { 'base::firewall': }

    include standard
    include admin

    include role::archiva
}

# tmh1001/tmh1002 video encoding server (precise only)
node /^tmh100[1-2]\.eqiad\.wmnet/ {
    $ganglia_aggregator = true
    role mediawiki::videoscaler
}

# Primary Graphite, StatsD, and profiling data aggregation host.
node 'tungsten.eqiad.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::txstatsd
    include role::gdash
    include role::mwprof
}

node 'uranium.wikimedia.org' {
    $ganglia_aggregator = true

    include standard
    include admin
    include role::ganglia::web
    include misc::monitoring::views
    include base::firewall

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# This node will soon be deprecated.
node 'vanadium.eqiad.wmnet' {
    role eventlogging
    include admin
    include standard
    include role::ipython_notebook
    include role::logging::mediawiki::errors
}

node 'virt1000.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    $is_puppet_master      = true
    $is_labs_puppet_master = true
    $use_neutron           = false

    include standard
    include admin
    include role::dns::ldap
    include ldap::role::client::labs
    include role::nova::controller
    include role::salt::masters::labs
    include role::deployment::salt_masters
    if $use_neutron == true {
        include role::neutron::controller

    }
}

node /virt100[1-4].eqiad.wmnet/ {
    $use_neutron = false
    role nova::compute
    include admin
    include standard
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /virt100[6-9].eqiad.wmnet/ {
    $use_neutron = false
    role nova::compute
    include admin
    include standard
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /virt101[0-2].eqiad.wmnet/ {
    $use_neutron = false
    openstack::nova::partition{ '/dev/sdb': }
    role nova::compute
    include admin
    include standard

    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    if $::hostname == 'wtp1001' or $::hostname == 'wtp1002' {
        $ganglia_aggregator = true
    }
    role parsoid::production
}

node 'ytterbium.wikimedia.org' {
    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::production
    role gerrit::production
    include admin
    include base::firewall

}

node 'zirconium.wikimedia.org' {
    class { 'base::firewall': }

    include standard
    include admin
    include role::planet
    include role::contacts
    include role::etherpad
    include role::wikimania_scholarships
    include role::bugzilla
    include role::transparency
    include role::grafana
    include role::iegreview
    include role::annualreport
    include role::devportal

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node default {
    # Labs nodes include a different set of defaults via ldap.
    if $::realm == 'production' {
        include standard
        include admin
    }
}

# as of 2014-08-12 these fundraising servers use frack puppet
#
# aluminium.frack.eqiad.wmnet
# barium.frack.eqiad.wmnet
# boron.frack.eqiad.wmnet
# db1008.frack.eqiad.wmnet
# db1025.frack.eqiad.wmnet
# indium.frack.eqiad.wmnet
# lutetium.frack.eqiad.wmnet
# pay-lvs1001.frack.eqiad.wmnet
# pay-lvs1002.frack.eqiad.wmnet
# payments1001.frack.eqiad.wmnet
# payments1002.frack.eqiad.wmnet
# payments1003.frack.eqiad.wmnet
# payments1004.frack.eqiad.wmnet
# samarium.frack.eqiad.wmnet
# silicon.frack.eqiad.wmnet
# tellurium.frack.eqiad.wmnet
# thulium.frack.eqiad.wmnet
