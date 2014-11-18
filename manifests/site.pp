# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# site.pp

import 'realm.pp' # These ones first
import 'certs.pp'
import 'dns.pp'
import 'facilities.pp'
import 'ganglia.pp'
import 'iptables.pp'
import 'mail.pp'
import 'misc/*.pp'
import 'network.pp'
import 'nfs.pp'
import 'role/*.pp'
import 'role/analytics/*.pp'
import 'search.pp'
import 'swift.pp'

# Include stages last
import 'stages.pp'

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard {
    include base
    include role::ntp
    include role::mail::sender
    include role::diamond
    if $::realm == 'production' {
        include ganglia # No ganglia in labs
    }
}

class standard-noexim {
    include base
    include ganglia
    include role::ntp
    include role::diamond
}


# Default variables. this way, they work with an ENC (as in labs) as well.
if $cluster == undef {
    $cluster = hiera('cluster', 'misc')
}

# Node definitions (alphabetic order)

node /^(acamar|achernar)\.wikimedia\.org$/ {
    include admin
    include base::firewall
    include standard

    include role::dns::recursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# To be decommissioned/reused, not presently serving traffic
node /^amslvs[1-4]\.esams\.wikimedia\.org$/ {
    include admin
    include standard

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# amssq31-62 are text varnish (and the only nodes with this legacy prefix)
node /^amssq[0-9]+\.esams\.(wmnet|wikimedia\.org)$/ {
    include admin

    sysctl::parameters { 'vm dirty page flushes':
        values => {
            'vm.dirty_background_ratio' => 5,
        }
    }

    $cluster = 'cache_text'
    include role::cache::text

    interface::add_ip6_mapped { 'main': }
}

# analytics1003 is being used for testing kafkatee
# in preperation for replacing udp2log
node 'analytics1003.eqiad.wmnet' {
    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics
    include role::analytics::kafkatee::webrequest::mobile
    include role::analytics::kafkatee::webrequest::edits
    include role::analytics::kafkatee::webrequest::5xx
    include role::analytics::kafkatee::webrequest::api
    include role::analytics::kafkatee::webrequest::glam_nara
    include role::analytics::kafkatee::webrequest::webstatscollector
}

# analytics1009 used to be the standby NameNode,
# but during cluster reinstall in 2014-07, it
# had an error when booting.  analytics1004
# has been repurposed as analytics standby NameNode.
node 'analytics1009.eqiad.wmnet' {
    # analytics1009 is analytics Ganglia aggregator for Row A
    # $ganglia_aggregator = true

    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    # include role::analytics::hadoop::standby
}




# analytics1004 is the Hadoop standby NameNode
# TODO: either fix analytics1009, or move this
# node to Row A.
node 'analytics1004.eqiad.wmnet' {

    class { 'admin':
        groups => [
            'analytics-users',
            'analytics-privatedata-users',
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics::hadoop::standby
}

# analytics1010 is the Hadoop master node
# (primary NameNode, ResourceManager, etc.)
node 'analytics1010.eqiad.wmnet' {
    # analytics1010 is analytics Ganglia aggregator for Row B
    $ganglia_aggregator = true

    class { 'admin':
        groups => [
            'analytics-users',
            'analytics-privatedata-users',
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics::hadoop::master
}

# analytics1011, analytics1013-analytics1017, analytics1019, analytics1020,
# analytics1028-analytics1041 are Hadoop worker nodes.
#
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# templates/hadoop/net-topology.py.erb to make sure the
# hostname -> /datacenter/rack/row id is correct.  This is
# used for Hadoop network topology awareness.
node /analytics10(11|1[3-7]|19|2[089]|3[0-9]|4[01]).eqiad.wmnet/ {
    # analytics1014 is analytics Ganglia aggregator for Row C
    if $::hostname == 'analytics1014' {
        $ganglia_aggregator = true
    }
    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics::hadoop::worker
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

    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics
    include role::analytics::kafka::server
}

# analytics1023-1025 are zookeeper server nodes
node /analytics102[345].eqiad.wmnet/ {

    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard

    include role::analytics
    include role::analytics::zookeeper::server
}

# analytics1026 does not currently have a role
node 'analytics1026.eqiad.wmnet' {

    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
    include standard


    # run misc udp2log here for sqstat
    include role::logging::udp2log::misc
}

# analytics1027 hosts some frontend web interfaces to Hadoop
# (Hue, Oozie, Hive, etc.).  It also submits regularly scheduled
# batch Hadoop jobs.
node 'analytics1027.eqiad.wmnet' {

    class { 'admin':
        groups => [
            'analytics-roots',
            'analytics-admins',
        ],
    }
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
    include role::analytics::refinery::data::check
}



# git.wikimedia.org
node 'antimony.wikimedia.org' {

    class { 'admin': groups => ['gerrit-root', 'gerrit-admin'] }

    class { 'base::firewall': }

    include standard
    include role::gitblit
    include role::subversion
}

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
    $cluster = 'misc'
    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
        'codfw.wmnet',
        'ulsfo.wmnet',
        'esams.wikimedia.org'
    ]

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include subversion::client

    class { 'admin':
        groups => [
            'deployment',
            'restricted',
            'parsoid-admin',
            'ocg-render-admins',
            'bastiononly',
        ],
    }


    include role::bastionhost
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
    $cluster = 'misc'
    $domain_search = [
        'wikimedia.org',
        'codfw.wmnet',
        'eqiad.wmnet',
        'ulsfo.wmnet',
        'esams.wikimedia.org'
    ]

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::bastionhost
}

node 'bast4001.wikimedia.org' {
    $cluster = 'misc'
    $domain_search = [
        'wikimedia.org',
        'ulsfo.wmnet',
        'eqiad.wmnet',
        'codfw.wmnet',
        'esams.wikimedia.org'
    ]

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::bastionhost
    include role::ipmi
    include role::installserver::tftp-server
}

node 'beryllium.wikimedia.org' {
    include admin
    include standard-noexim
}

node 'calcium.wikimedia.org' {
    $cluster = 'misc'

    include admin
    include standard
}

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

node 'caesium.eqiad.wmnet' {
    $cluster = 'misc'

    class { 'admin': groups => ['releasers-mediawiki',
                                'releasers-mobile'] }
    class { 'base::firewall': }

    include admin
    include standard
    include role::releases
}

# cerium,praseodymium, ruthenium and xenon are cassandra test host
node /^(cerium|praseodymium|ruthenium|xenon)\.eqiad\.wmnet$/ {

    class { 'admin': groups => ['cassandra-roots'] }

    system::role { 'role::cassandra-test':
        description => 'Cassandra test server',
    }

    include standard

    # XXX: to be moved into the puppet class
    sysctl::parameters { 'cassandra':
        values => {
            'vm.max_map_count' => 1048575,
        },
    }
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
    include admin
    include base::firewall
    include standard
    include role::dns::recursor

    if $::hostname == 'chromium' {
        interface::ip { 'url-downloader':
            interface => 'eth0',
            address   => '208.80.154.156',
        }
        $url_downloader_ip = '208.80.154.156'
        include role::url_downloader
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

# cp1008: temporary test host for SNI SSL
node 'cp1008.wikimedia.org' {
    include admin
    interface::add_ip6_mapped { 'main': }
    $cluster = 'cache_text'
    include role::cache::text
    include role::cache::ssl::sni
    include role::authdns::testns # test dns stuff too
}

node /^cp10(3[7-9]|40)\.eqiad\.wmnet$/ {
    include admin
    if $::hostname =~ /^cp103[78]$/ {
        $ganglia_aggregator = true
    }
    interface::add_ip6_mapped { 'main': }
    $cluster = 'cache_text'
    include role::cache::text
}

node /^cp104[34]\.eqiad\.wmnet$/ {
    include admin
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_misc'
    include role::cache::misc
}

node 'cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet' {
    class { 'admin': groups => ['parsoid-roots',
                                'parsoid-admin'] }

    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_parsoid'
    include role::cache::parsoid
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    include admin
    if $::hostname =~ /^cp104[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_mobile'
    include role::cache::mobile
}

node /^cp10(4[89]|5[01]|6[1-4])\.eqiad\.wmnet$/ {
    include admin
    if $::hostname =~ /^(cp1048|cp1061)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_upload'
    include role::cache::upload
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {

    include admin
    if $::hostname =~ /^cp105[23]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_text'
    include role::cache::text
}

node 'cp1056.eqiad.wmnet', 'cp1057.eqiad.wmnet', 'cp1069.eqiad.wmnet', 'cp1070.eqiad.wmnet' {

    include admin
    if $::hostname =~ /^cp105[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_bits'
    include role::cache::bits
}

node /^cp30(0[3-9]|10|1[5-8])\.esams\.(wikimedia\.org|wmnet)$/ {

    include admin
    if $::hostname =~ /^cp300[34]$/ {
        $ganglia_aggregator = true
    }
    $cluster = 'cache_upload'
    interface::add_ip6_mapped { 'main': }

    include role::cache::upload
}

node /^cp301[1-4]\.esams\.(wikimedia\.org|wmnet)$/ {

    include admin
    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_mobile'
    include role::cache::mobile
}

node /^cp(3019|302[0-2])\.esams\.wikimedia\.org$/ {

    include admin
    if $::hostname =~ /^cp(3019|3020)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_bits'
    include role::cache::bits
}

#
# ulsfo varnishes
#

node /^cp400[1-4]\.ulsfo\.wmnet$/ {

    include admin
    # cp4001 and cp4003 are in different racks,
    # make them each ganglia aggregators.
    if $::hostname =~ /^cp(4001|4003)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_bits'
    include role::cache::bits
    include role::cache::ssl::unified
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {

    include admin
    if $::hostname =~ /^cp(4005|4013)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_upload'
    include role::cache::upload
    include role::cache::ssl::unified
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {

    include admin
    if $::hostname =~ /^cp(4008|4016)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_text'
    include role::cache::text
    include role::cache::ssl::unified
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {

    include admin
    if $::hostname =~ /^cp401[19]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    $cluster = 'cache_mobile'
    include role::cache::mobile
    include role::cache::ssl::unified
}

node 'dataset1001.wikimedia.org' {
    $cluster = 'misc'

    class { 'admin': groups => [dataset-admins] }

    include standard
    include role::diamond
    include role::dataset::systemusers
    include role::dataset::primary
#    include role::download::secondary
    include role::download::wikimedia
}

# eqiad dbs
node /^db10(51|52|55|61|65|66)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s1':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(02|09|18|54|60)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s2':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(03|19|38)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s3':
        # Many more tables than other shards.
        # innodb_file_per_table=off to reduce file handles.
        innodb_file_per_table => false,
        mariadb               => true,
    }
}

node /^db10(40|53|56|59|64)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s4':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(05|21|26|37|45|49|58)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s5':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(06|10|15|22|23|30)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s6':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(07|28|33|34|39|41)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::s7':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

# MariaDB 10
node /^db10(62|72|73)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db20(16)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's1',
    }
}

node /^db10(36|63|67)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
}

node /^db20(17)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's2',
    }
}

node /^db10(35|44)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's3',
    }
}

node /^db20(18)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's3',
    }
}

node /^db10(42|68|70)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's4',
    }
}

node /^db20(19)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's4',
    }
}

node /^db10(71)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
}

node /^db20(23)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's5',
    }
}

node /^db20(28)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 's6',
    }
}

node /^db20(29)\.codfw\.wmnet/ {

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
node /^db10(01|16)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

node /^db20(10)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
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

node /^db10(46)\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'm2',
    }
}

node /^db20(11)\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
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

## researchdb s1
node 'db1047.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    include role::mariadb::analytics
}

## SANITARIUM

node 'db1057.eqiad.wmnet' {

    include admin
    $cluster = 'mysql'
    $ganglia_aggregator = true
    class { 'role::db::sanitarium':
        instances => {
            's3' => {
                'port'                    => '3306',
                'innodb_log_file_size'    => '500M',
                'ram'                     => '24G',
                'repl_ignore_dbs'         => $::private_wikis,
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
            's6' => {
                'port'                    => '3307',
                'innodb_log_file_size'    => '500M',
                'ram'                     => '24G',
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
            's7' => {
                'port'                    => '3308',
                'innodb_log_file_size'    => '500M',
                'ram'                     => '24G',
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
        }
    }
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

node /^dbstore1001\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    $ganglia_aggregator = true
    $mariadb_backups_folder = '/a/backups'
    include role::mariadb::backup
    # 24h pt-slave-delay on all repl streams
    class { 'role::mariadb::dbstore':
        lag_warn => 90000,
        lag_crit => 180000,
        # Delayed slaves legitimately and cleanly (errno = 0) stop the SQL thread, so
        # don't spam Icinga with warnings. This will not block properly critical alerts.
        warn_stopped => false,
    }
}

node /^dbstore1002\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    # Analytics traffic & eventlogging spikes
    class { 'role::mariadb::dbstore':
        lag_warn => 1800,
        lag_crit => 3600,
    }
}

# springle using for codfw preparation
node 'db1004.eqiad.wmnet' {

    include admin
    include standard
}

node 'dbproxy1002.eqiad.wmnet' {
    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::proxy::master':
        shard          => 'm2',
        primary_name   => 'db1020',
        primary_addr   => '10.64.16.9',
        secondary_name => 'db1046',
        secondary_addr => '10.64.16.35',
    }
}

node 'dysprosium.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
}

node 'eeden.esams.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include admin
    include role::authdns::server
}

# erbium is a webrequest udp2log host
node 'erbium.eqiad.wmnet' inherits 'base_analytics_logging_node' {
    # gadolinium hosts the separate nginx webrequest udp2log instance.

    class { 'admin':
        groups => [
            'udp2log-users',
            'restricted',
        ],
    }

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

node /es200[1]\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es1',
    }
}

node /es100[67]\.eqiad\.wmnet/ {
    include admin
    $cluster = 'mysql'
    class { 'role::coredb::es2':
        mariadb => true,
    }
}

node /es100[5]\.eqiad\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es2',
    }
}

node /es200[6]\.codfw\.wmnet/ {

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

node /es200[8]\.codfw\.wmnet/ {

    include admin
    $cluster = 'mysql'
    class { 'role::mariadb::core':
        shard => 'es3',
    }
}

node 'fluorine.eqiad.wmnet' {
    $cluster = 'misc'

    include standard
    include misc::deployment::fatalmonitor

    class { 'admin':
        groups => [
            'deployment',
            'restricted',
        ],
    }

    class { 'role::logging::mediawiki':
        monitor       => false,
        log_directory => '/a/mw-log',
    }

}

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node 'gadolinium.wikimedia.org' inherits 'base_analytics_logging_node' {

    class { 'admin': groups => ['udp2log-users'] }

    # relay the incoming webrequest log stream to multicast
    include role::logging::relay::webrequest-multicast
    # relay EventLogging traffic over to vanadium
    include role::logging::relay::eventlogging

    # gadolinium hosts the separate nginx webrequest udp2log instance.
    include role::logging::udp2log::nginx

    # gadolinium runs Domas' webstatscollector.
    # udp2log runs the 'filter' binary (on oxygen)
    # which sends logs over to the 'collector' (on gadolinium)
    # service, which writes dump files in /a/webstats/dumps.
    include role::logging::webstatscollector
}

node 'gallium.wikimedia.org' {

    $cluster = 'misc'

    class { 'admin': groups => ['contint-users', 'contint-admins', 'contint-roots'] }

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

node 'helium.eqiad.wmnet' {
    include admin
    include standard
    include role::poolcounter
    include role::backup::director
    include role::backup::storage
}

node 'holmium.wikimedia.org' {

    include admin
    include base::firewall

    include standard

}

node 'hooft.esams.wikimedia.org' {
    $ganglia_aggregator = true
    $domain_search = [
        'esams.wikimedia.org',
        'wikimedia.org',
        'esams.wmnet'
    ]

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    class { 'admin':
        groups => [
            'deployment',
            'restricted',
        ],
    }

    include standard
    include role::bastionhost
    include role::installserver::tftp-server

    # TODO: 2013-12-13. rsync is an unpuppetized service on hooft. Ferm is
    # applied through role::installserver::tftp-server and policy is DROP.
    # Temporarily opening access. Must puppetize properly
    ferm::service { 'rsync':
        proto => 'tcp',
        port  => '873',
    }
    # TODO: Same for udpmcast
    ferm::service { 'udpmcast':
        proto => 'udp',
        port  => '4827',
    }

    class { 'ganglia_new::monitor::aggregator':
        sites =>  'esams',
    }
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

node 'iridium.eqiad.wmnet' {
    class { 'base::firewall': }
    include admin
    include standard-noexim
    include role::phabricator::main
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Operations Bastion',
    }
    $cluster = 'misc'
    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
        'codfw.wmnet',
        'ulsfo.wmnet',
        'esams.wikimedia.org',
        'esams.wmnet',
    ]

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::bastionhost
    include role::ipmi
    include role::access_new_install

    include role::backup::host
    backup::set {'home': }
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

    $site = 'eqiad'
    $cluster = 'labsnfs'
    $domain_search = ['wikimedia.org', 'eqiad.wmnet']
    $ldapincludes = ['openldap', 'nss', 'utils']

    $ganglia_aggregator = true

    # Commented out pending some troubleshooting
    # interface::aggregate { 'bond0':
        # orig_interface => 'eth0',
        # members        => [ 'eth0', 'eth1' ],
    # }

    # need to solve using admin on ldap boxes
    # RT 7732
    # include admin
    include standard
    include openstack::project-nfs-storage-service
    include rsync::server

    rsync::server::module {
        'pagecounts':
            path        => '/srv/dumps/pagecounts',
            read_only   => 'no',
            hosts_allow => ['208.80.154.11', '208.80.152.185'];
    }

    class { 'ldap::role::client::labs': ldapincludes => $ldapincludes }
}

node 'labstore1003.eqiad.wmnet' {
    $site = 'eqiad'
    $cluster = 'labsnfs'
    $domain_search = ['wikimedia.org', 'eqiad.wmnet']

    $ganglia_aggregator = true

    include standard
}

node 'lanthanum.eqiad.wmnet' {

    class { 'admin': groups => ['contint-users', 'contint-admins', 'contint-roots'] }

    include standard
    include role::ci::slave  # RT #5074

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

node 'lithium.eqiad.wmnet' {
    $cluster = 'misc'

    include admin
    include standard
    include role::backup::host
    include role::syslog::centralserver
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
    $cluster = 'lvs'
    include admin
    include role::lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    case $::hostname {
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
    $cluster = 'lvs'
    include admin
    include role::lvs::balancer

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    include lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    case $::hostname {
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

    $cluster = 'lvs'
    include admin
    include role::lvs::balancer

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

    $cluster = 'lvs'
    # lvs4001 and lvs4003 are in different racks
    if $::hostname =~ /^lvs400[13]$/ {
        $ganglia_aggregator = true
    }

    include admin
    include role::lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    lvs::interface-tweaks {
        'eth0': bnx2x => true, txqlen => 10000, rss_pattern => 'eth0-fp-%d';
    }
}

node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    class { 'base::firewall': }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include role::diamond
    include role::racktables
    include role::requesttracker
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    $cluster = 'memcached'
    if $::hostname =~ /^mc100[12]$/ {
        $ganglia_aggregator = true
    }

    include admin
    include role::memcached
    include passwords::redis

    file { '/a':
        ensure => 'directory',
    }

    class { 'redis':
        maxmemory => '500Mb',
        dir       => '/a/redis',
        password  => $passwords::redis::main_password,
    }
    include redis::ganglia
}

node /^rdb100[1-4]\.eqiad\.wmnet/ {

    include admin

    $cluster = 'redis'
    $ganglia_aggregator = true

    $redis_replication = {
        'rdb1002' => 'rdb1001',
        'rdb1004' => 'rdb1003',
    }

    class { 'role::db::redis':
        redis_replication => $redis_replication,
        dir               => '/a/redis',
    }
}

node /^rbf100[1-2]\.eqiad\.wmnet/ {
    $cluster = 'redis'

    include admin

    class { 'role::db::redis':
        redis_replication => { 'rbf1002' => 'rbf1001' },
    }

    # Background save may fail under low memory condition unless
    # vm.overcommit_memory is 1.
    sysctl::parameters { 'vm.overcommit_memory':
        values => { 'vm.overcommit_memory' => 1, },
    }
}

node 'rubidium.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include standard
    include admin
    include role::authdns::server
}

node 'ms1001.wikimedia.org' {
    $cluster = 'misc'

    class { 'admin': groups => [dataset-admins] }
    include standard
    include role::dataset::systemusers
    include role::dataset::secondary
    include role::download::wikimedia
#    include role::mirror::media
}

node 'ms1002.eqiad.wmnet' {
    include admin
    include standard
}

node /ms100[4]\.eqiad\.wmnet/ {
    $cluster = 'misc'
    $ganglia_aggregator = true

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
    if $::hostname == 'ms-fe1001' {
        include role::swift::eqiad-prod::ganglia_reporter
    }

    class { 'lvs::realserver': realserver_ips => [ '10.2.2.27' ] }

    include admin
    include role::swift::eqiad-prod::proxy
    include role::diamond
}

node /^ms-be10[0-9][0-9]\.eqiad\.wmnet$/ {
    $all_drives = [
        '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh',
        '/dev/sdi', '/dev/sdj', '/dev/sdk', '/dev/sdl'
    ]

    include admin
    include role::swift::eqiad-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sdm3': }
    swift::label_filesystem{ '/dev/sdn3': }
    swift::mount_filesystem{ '/dev/sdm3': }
    swift::mount_filesystem{ '/dev/sdn3': }
}

node /^ms-fe300[1-2]\.esams\.wmnet$/ {
    include admin
    include role::swift::esams-prod::proxy
}

node /^ms-be300[1-4]\.esams\.wmnet$/ {
    # 720xd *without* SSDs; sda & sdb serve both as root and as Swift disks
    $all_drives = [
        '/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf',
        '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj',
        '/dev/sdk', '/dev/sdl'
    ]

    include admin
    include role::swift::esams-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }

    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sda3': }
    swift::label_filesystem{ '/dev/sdb3': }
    swift::mount_filesystem{ '/dev/sda3': }
    swift::mount_filesystem{ '/dev/sdb3': }
}

node /^ms-fe200[1-4]\.codfw\.wmnet$/ {
    include admin

    if $::hostname =~ /^ms-fe200[12]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'ms-fe2001' {
        include role::swift::stats_reporter
    }

    include ::lvs::realserver
    include role::swift::proxy
}

node /^ms-be20[0-9][0-9]\.codfw\.wmnet$/ {
    include admin

    include role::swift::storage
}

# mw1001-1016 are jobrunners (precise)
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'jobrunner'
    if $::hostname =~ /^mw100[12]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'mw1010' {
        include misc::deployment::scap_proxy
    }

    include role::mediawiki::jobrunner
}


# mw1017-1022, mw1053 are apaches (trusty)
# mw1023-1113 are apaches (precise)
node /^mw1(01[7-9]|0[2-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}

    if $::hostname =~ /^mw10(1[78]|5[45])$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'mw1070' {
        include misc::deployment::scap_proxy
    }

    include role::mediawiki::appserver
}

# mw1114-1148 are api apaches (precise)
node /^mw11(1[4-9]|[23][0-9]|4[0-8])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'api_appserver'
    if $::hostname =~ /^mw111[45]$/ {
        $ganglia_aggregator = true
    }

    include role::mediawiki::appserver::api
}

# mw1149-1152 are apaches (precise)
node /^mw11(49|5[0-2])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'appserver'

    include role::mediawiki::appserver
}

# mw1153-1160 are imagescalers (precise)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'imagescaler'
    if $::hostname =~ /^mw115[34]$/ {
        $ganglia_aggregator = true
    }

    include role::mediawiki::imagescaler
}

# mw1161-1188 are apaches (precise)
node /^mw11(6[1-9]|7[0-9]|8[0-8])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}

    if $::hostname == 'mw1161' {
        include misc::deployment::scap_proxy
    }

    include role::mediawiki::appserver
}

# mw1189-1208 are api apaches (precise)
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'api_appserver'
    if $::hostname == 'mw1201' {
        include misc::deployment::scap_proxy
    }

    include role::mediawiki::appserver::api
}

# mw1209-1220 are apaches (precise)
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {

    class {'::admin': groups => ['deployment']}
    $cluster = 'appserver'
    include role::mediawiki::appserver
}

node 'neon.wikimedia.org' {
    class { 'base::firewall': }

    interface::add_ip6_mapped { 'main': interface => 'eth0' }

    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
        'codfw.wmnet',
        'ulsfo.wmnet',
        'esams.wikimedia.org'
    ]

    include standard
    include admin
    include role::icinga
    include role::ishmael
    include role::tendril
    include role::tcpircbot
}

node 'nescio.esams.wikimedia.org' {
    interface::ip { 'dns::recursor':
        interface => 'eth0',
        address   => '91.198.174.6',
    }

    include admin
    include standard

    include dns::recursor::statistics
    include network::constants

    class { 'dns::recursor':
        listen_addresses => ['91.198.174.6'],
        allow_from       => $network::constants::all_networks,
    }

    dns::recursor::monitor { '91.198.174.6': }
}

node 'netmon1001.wikimedia.org' {
    include admin
    include standard
    include webserver::apache
    include role::rancid
    include smokeping
    include smokeping::web
    include role::librenms
    include misc::torrus
    include misc::torrus::web
    include misc::torrus::xml-generation::cdn
    include passwords::network
    include ganglia::collector
    include role::servermon

    class { 'ganglia_new::monitor::aggregator':
        sites => ['eqiad', 'codfw'],
    }

    $snmp_ro_community = $passwords::network::snmp_ro_community

    interface::add_ip6_mapped { 'main': }

    $corerouters = [
        'cr1-eqiad.wikimedia.org',
        'cr1-esams.wikimedia.org',
        'cr1-ulsfo.wikimedia.org',
        'cr1-ulsfo.wikimedia.org',
        'cr2-eqiad.wikimedia.org',
        'cr2-knams.wikimedia.org',
        'cr2-ulsfo.wikimedia.org',
        'cr2-codfw.wikimedia.org',
        'pfw1-eqiad.wikimedia.org',
    ]

    $accessswitches = [
        'asw2-a5-eqiad.mgmt.eqiad.wmnet',
        'asw-a-eqiad.mgmt.eqiad.wmnet',
        'asw-b-eqiad.mgmt.eqiad.wmnet',
        'asw-c-eqiad.mgmt.eqiad.wmnet',
        'asw-d-eqiad.mgmt.eqiad.wmnet',
        'asw-a-codfw.mgmt.codfw.wmnet',
        'asw-b-codfw.mgmt.codfw.wmnet',
        'asw-c-codfw.mgmt.codfw.wmnet',
        'asw-d-codfw.mgmt.codfw.wmnet',
        'csw2-esams.wikimedia.org',
        'msw1-eqiad.mgmt.eqiad.wmnet',
        'psw1-eqiad.mgmt.eqiad.wmnet',
    ]

    $storagehosts = [
        'nas1001-a.eqiad.wmnet',
        'nas1001-b.eqiad.wmnet',
    ]

    misc::torrus::discovery::ddxfile { 'corerouters':
        subtree        => '/Core_routers',
        snmp_community => $snmp_ro_community,
        hosts          => $corerouters,
    }

    misc::torrus::discovery::ddxfile { 'accessswitches':
        subtree        => '/Access_switches',
        snmp_community => $snmp_ro_community,
        hosts          => $accessswitches,
    }

    misc::torrus::discovery::ddxfile { 'storage':
        subtree        => '/Storage',
        snmp_community => $snmp_ro_community,
        hosts          => $storagehosts,
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
    $gid = '500' # what is this used for? I couldn't get that.

    include base::firewall
    include standard
    include admin
    include role::ocg::production
}

node /^osm-cp100[1-4]\.wikimedia\.org$/ {
    include admin
    include standard-noexim
}

# Trusty app server / HHVM staging
node 'osmium.eqiad.wmnet' {
    include standard
    class {'::admin': groups => ['deployment']}
}

# base_analytics_logging_node is defined in role/logging.pp
node 'oxygen.wikimedia.org' inherits 'base_analytics_logging_node' {

    class { 'admin': groups => ['udp2log-users'] }
    include role::dataset::systemusers

    # main oxygen udp2log handles mostly Wikipedia Zero webrequest logs
        include role::logging::udp2log::oxygen
    # Also include lucene search loggging udp2log instance
        include role::logging::udp2log::lucene
}

node 'palladium.eqiad.wmnet' {
    include standard
    include admin
    include role::ipmi
    include role::salt::masters::production
    include role::deployment::salt_masters::production
    include role::access_new_install
    include role::puppetmaster::frontend
    include role::pybal_config

    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
        'codfw.wmnet',
        'ulsfo.wmnet',
        'esams.wmnet',
        'esams.wikimedia.org'
    ]
}

node /pc100[1-3]\.eqiad\.wmnet/ {
    $cluster = 'mysql'
    include admin
    include role::db::core
    include mysql_wmf::mysqluser
    include mysql_wmf::datadirs
    include mysql_wmf::pc::conf

    class { 'mysql_wmf::packages': mariadb => true }

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
    class { 'admin': groups => ['oit'] }
    include standard-noexim
    include role::mail::mx

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

node 'radium.wikimedia.org' {
    class { 'base::firewall': }
    include admin
    include standard
    include role::tor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node 'radon.eqiad.wmnet' {
    class { 'base::firewall': }
    include admin
    include standard-noexim
    include role::phabricator::legalpad
}

# Live Recent Changes WebSocket stream
node 'rcs1001.eqiad.wmnet', 'rcs1002.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include standard
    include role::rcstream

    $cluster = 'rcstream'
    $ganglia_aggregator = ( $::hostname == 'rcs1001' )
}

# netflow machine (jkrauska)
node 'rhenium.wikimedia.org' {
    include standard
    include role::pmacct
    class { 'admin': groups => ['pmacct-roots'] }
}

node 'sanger.wikimedia.org' {
    include base
    include ganglia
    include role::ntp
    include ldap::role::server::corp
    include ldap::role::client::corp
    class { 'admin': groups => ['oit'] }
}

node /^search100[0-6]\.eqiad\.wmnet/ {
    if $::hostname =~ /^search100(1|2)$/ {
        $ganglia_aggregator = true
    }

    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool1
}

node /^search10(0[7-9]|10)\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool2
}

node /^search101[1-4]\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool3
}

node /^search101[56]\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool4
}

node /^search10(19|20)\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool5
}

node /^search101[78]\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::prefix
}

node /^search10(19|2[0-2])\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool4
}

node /^search102[3-4]\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    include role::lucene::front_end::pool3
}

node /^searchidx100[0-2]\.eqiad\.wmnet/ {
    class { 'admin':
        groups => [
            'deployment',
            'search-roots',
        ],
    }
    mount { '/srv/mediawiki':
        ensure  => present,
        fstype  => 'none',
        options => 'bind',
        device  => '/a/bind-mount-mediawiki',
        before  => Exec['fetch_mediawiki']
    }
    include role::lucene::indexer
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

node /ssl100[1-9]\.wikimedia\.org/ {
    $cluster = 'ssl'
    if $::hostname =~ /^ssl100[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include admin
    include role::protoproxy::ssl
}

node /ssl300[1-4]\.esams\.wikimedia\.org/ {
    $cluster = 'ssl'
    if $::hostname =~ /^ssl300[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0'
    }

    include admin
    include role::protoproxy::ssl
}

node 'strontium.eqiad.wmnet' {
    include standard
    include admin
    include role::puppetmaster::backend
}

node 'stat1001.wikimedia.org' {
    include standard
    include role::statistics::www
    class { 'admin': groups => ['statistics-web-users'] }
}

node 'stat1002.eqiad.wmnet' {
    include standard
    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    class { 'admin':
        groups => [
            'statistics-privatedata-users',
            'statistics-admins',
            'analytics-privatedata-users',
            'analytics-roots',
            'analytics-admins',
        ],
    }

    # include classes needed for storing and crunching
    # private data on stat1002.
    include role::statistics::private

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
node 'stat1003.wikimedia.org' {
    include standard

    # stat1003 has a public IP and should be pretty
    # well firewalled off.  If it needs a specific
    # service opened up, this will be done in
    # statistics classes.
    # NOTE: This will be moved to another class
    # someday, probably standard.
    class { 'base::firewall': }

    include role::statistics::cruncher

    include misc::statistics::cron_blog_pageviews
    include misc::statistics::limn::data::jobs
    include misc::statistics::researchdb_password

    class { 'admin':
        groups => [
            'statistics-admins',
            'statistics-privatedata-users',
            'statistics-users',
            'researchers',
        ],
    }
}

node 'snapshot1001.eqiad.wmnet' {
    include snapshot

    class { 'admin':
        groups => [
            'udp2log-users',
            'deployment',
        ],
    }

    class { 'snapshot::dumps': hugewikis => true }
    include role::snapshot::common
}
node /^snapshot100[24]\.eqiad\.wmnet/ {
    include snapshot
    include snapshot::dumps

    class { 'admin':
        groups => [
            'udp2log-users',
            'deployment',
        ],
    }

    include role::snapshot::common
}
node 'snapshot1003.eqiad.wmnet' {
    include snapshot
    include snapshot::dumps
    include role::snapshot::cron::primary

    class { 'admin':
        groups => [
            'udp2log-users',
            'deployment',
        ],
    }
}

node 'terbium.eqiad.wmnet' {
    include role::mediawiki::common
    include role::db::maintenance
    include role::peopleweb
    include misc::monitoring::jobqueue
    include generic::wikidev-umask
    include misc::deployment::common_scripts
    include role::noc
    include role::mediawiki::searchmonitor

    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
    ]

    class { 'admin':
        groups => [
            'restricted',
            'deployment',
            'ldap-admins',
        ],
    }

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
    include misc::maintenance::purge_abusefilter
    include misc::maintenance::purge_checkuser
    include misc::maintenance::purge_securepoll

    # (bug 15434) Periodical run of currently disabled special pages
    # to be run against PMTPA slaves
    include misc::maintenance::updatequerypages

    package { 'python-mysqldb':
        ensure => installed,
    }

    include role::backup::host
    backup::set {'home': }
}

node /^elastic10[0-3][0-9]\.eqiad\.wmnet/ {
    # ganglia cluster name.
    $cluster = 'elasticsearch'
    if $::hostname =~ /^elastic10(0[17]|13)/ {
        $ganglia_aggregator = true
    }

    class { 'admin': groups => ['elasticsearch-roots'] }

    include standard
    include role::elasticsearch::server

    class { 'lvs::realserver':
        realserver_ips => '10.2.2.30',
    }
}

node 'lead.wikimedia.org' {
    class { 'admin': groups => ['oit'] }
    include standard-noexim
    include role::mail::mx

    interface::add_ip6_mapped { 'main': }
}

node /^logstash100[1-3]\.eqiad\.wmnet$/ {
    $cluster = 'logstash'
    if $::hostname =~ /^logstash100[13]$/ {
        $ganglia_aggregator = true
    }

    class { 'admin': groups => ['logstash-roots'] }

    include standard
    include role::logstash
    include role::kibana
}

node 'tin.eqiad.wmnet' {
    $cluster = 'misc'
    $domain_search = [
        'wikimedia.org',
        'eqiad.wmnet',
        'esams.wikimedia.org'
    ]

    include standard
    include generic::wikidev-umask
    include role::deployment::deployment_servers::production
    include mediawiki
    include misc::deployment
    include misc::deployment::scap_scripts
    include misc::deployment::l10nupdate
    include mysql
    include role::labsdb::manager
    include ssh::hostkeys-collect
    include role::apachesync
    include role::releases::upload

    class { 'admin':
        groups => [
            'deployment',
            'parsoid-admin',
            'ocg-render-admins',
        ]
    }

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
    $cluster = 'videoscaler'
    if $::hostname =~ /^tmh100[12]$/ {
        $ganglia_aggregator = true
    }
    include role::mediawiki::videoscaler

    class { 'admin':
        groups => ['deployment']
    }
}

# Receives log data from varnishes (udp 8422) and Apaches (udp 8421),
# processes it, and broadcasts to internal subscribers.
node 'vanadium.eqiad.wmnet' {
    class { 'admin':
        groups => [
            'eventlogging-admins',
            'eventlogging-roots',
        ],
    }

    include standard
    include role::eventlogging
    include role::ipython_notebook
    include role::logging::mediawiki::errors
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.wikimedia.org' {
    include standard
    class { 'admin':
        groups => [
            'eventlogging-admins',
            'eventlogging-roots',
        ],
    }

    include base::firewall
    include role::eventlogging::graphite
    include role::webperf
}

# Primary Graphite, StatsD, and profiling data aggregation host.
node 'tungsten.eqiad.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::txstatsd
    include role::gdash
    include role::mwprof
    include role::performance
}

# graphite test machine, currently with SSD caching + spinning disks
node 'graphite1001.eqiad.wmnet' {
    include admin
    include standard
    include role::graphite::production
    include role::txstatsd
    include role::gdash
}

# Labs Graphite and StatsD host
node 'labmon1001.eqiad.wmnet' {
    include standard

    class { 'admin': groups => ['labmon-roots'] }

    include role::labmon
}

node 'virt1000.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    $is_puppet_master      = true
    $is_labs_puppet_master = true
    $openstack_version     = 'havana'
    $use_neutron           = false

    include standard
    include admin
    include role::dns::ldap
    include ldap::role::server::labs
    include ldap::role::client::labs
    include role::nova::controller
    include role::nova::manager
    include role::salt::masters::labs
    include role::deployment::salt_masters::labs
    if $use_neutron == true {
        include role::neutron::controller

    }
}

node 'labcontrol2001.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    #$is_puppet_master      = true
    #$is_labs_puppet_master = true
    #$openstack_version     = 'folsom'
    #$use_neutron           = false

    include standard
    include admin
    include base::firewall
    include role::dns::ldap
    include ldap::role::server::labs
    include ldap::role::client::labs
    include role::salt::masters::labs

    #include role::nova::controller
    #include role::nova::manager
    #include role::salt::masters::labs
    #include role::deployment::salt_masters::labs
}

node 'neptunium.wikimedia.org' {
    $cluster               = 'virt'
    #$is_puppet_master      = true
    #$is_labs_puppet_master = true
    #$openstack_version     = 'folsom'
    #$use_neutron           = false

    include standard
    include admin
    include ldap::role::server::labs
    include ldap::role::client::labs

    #include role::nova::controller
    #include role::nova::manager
    #include role::salt::masters::labs
    #include role::deployment::salt_masters::labs
}

node 'labnet1001.eqiad.wmnet' {
    $cluster = 'virt'
    $openstack_version = 'havana'
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

node /virt100[1-5].eqiad.wmnet/ {
    $cluster = 'virt'
    $openstack_version = 'havana'
    $use_neutron = false

    include admin
    include standard
    include role::nova::compute
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node 'virt1006.eqiad.wmnet' {
    $cluster = 'virt'
    $openstack_version = 'havana'
    $use_neutron = false

    include admin
    include standard
    include role::nova::compute
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /virt100[7-9].eqiad.wmnet/ {
    $cluster = 'virt'
    $openstack_version = 'havana'
    $use_neutron = false

    include admin
    include standard
    include role::nova::compute
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node 'iodine.wikimedia.org' {
    class { 'base::firewall': }

    include admin
    include role::diamond
    include role::otrs

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^sca100[12]\.eqiad\.wmnet$/ {
    $cluster = 'sca'
    $ganglia_aggregator = true
    include standard

    include role::mathoid::production
    include role::citoid::production

    class { 'admin':
        groups => [
            'mathoid-roots',
            'mathoid-admin',
            'citoid-roots',
            'citoid-admin',
        ]
    }
    class { 'lvs::realserver':
        realserver_ips => [
                    '10.2.2.19', # citoid.svc.eqiad.wmnet
                    '10.2.2.20', # mathoid.svc.eqiad.wmnet
                    ],
    }
}

node 'uranium.wikimedia.org' {
    $ganglia_aggregator = true

    include standard
    include admin
    include role::ganglia::web
    # TODO: Resolve this
    #include misc::monitoring::views

    install_certificate{ 'ganglia.wikimedia.org': }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    $cluster = 'parsoid'

    if $::hostname == 'wtp1001' or $::hostname == 'wtp1002' {
        $ganglia_aggregator = true
    }

    class { 'admin': groups => ['parsoid-roots',
                                'parsoid-admin'] }
    include standard
    include role::parsoid::production

    class { 'lvs::realserver':
        realserver_ips => ['10.2.2.28'],
    }
}

node 'ytterbium.wikimedia.org' {

    class { 'admin': groups => ['gerrit-root', 'gerrit-admin'] }

    class { 'base::firewall': }

    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::production
    include role::gerrit::production

    install_certificate{ 'gerrit.wikimedia.org':
        ca => 'RapidSSL_CA.pem',
    }

}

node 'zinc.eqiad.wmnet' {

    include standard

    # zinc is a Solr box.  It will be handy
    # for search-roots to have access
    # here to help troubleshoot problems.
    # RT: 8144
    class { 'admin':
        groups => ['search-roots'],
    }
    include role::solr::ttm
}

node 'zirconium.wikimedia.org' {
    class { 'base::firewall': }

    include standard
    include admin
    include role::planet
    include misc::outreach::civicrm # contacts.wikimedia.org
    include role::etherpad
    include role::wikimania_scholarships
    include role::bugzilla
    include role::transparency
    include role::grafana
    include role::iegreview

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
