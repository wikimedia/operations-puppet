# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
#site.pp

import 'realm.pp' # These ones first
import 'generic-definitions.pp'

import 'admins.pp'
import 'backups.pp'
import 'certs.pp'
import 'decommissioning.pp'
import 'dns.pp'
import 'facilities.pp'
import 'ganglia.pp'
import 'gerrit.pp'
import 'imagescaler.pp'
import 'iptables.pp'
import 'mail.pp'
import 'misc/*.pp'
import 'mobile.pp'
import 'nagios.pp'
import 'network.pp'
import 'nfs.pp'
import 'openstack.pp'
import 'role/*.pp'
import 'role/analytics/*.pp'
import 'search.pp'
import 'sudo.pp'
import 'swift.pp'
import 'webserver.pp'
import 'zuul.pp'

# Include stages last
import 'stages.pp'

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard {
    include base
    include ganglia
    include ntp::client
    include exim::simple-mail-sender
}

class standard-noexim {
    include base
    include ganglia
    include ntp::client
}


# Default variables
$cluster = 'misc'

# Node definitions (alphabetic order)

node /^amslvs[1-4]\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^amslvs[12]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    # Make sure GRO is off
    interface::offload { 'eth0 gro':
        interface => 'eth0',
        setting   => 'gro',
        value     => 'off',
    }
}

# amssq47 is a text varnish
node /^amssq47\.esams\.wikimedia\.org$/ {
    include role::cache::text
    include role::cache::ssl::unified

    interface::add_ip6_mapped { 'main': }
}

# amssq48-62 are text varnish
node /^amssq(4[8-9]|5[0-9]|6[0-2])\.esams\.wikimedia\.org$/ {

    sysctl::parameters { 'vm dirty page flushes':
        values => {
            'vm.dirty_background_ratio' => 5,
        }
    }

    include role::cache::text

    interface::add_ip6_mapped { 'main': }
}


# analytics1003 is being used for testing kafkatee
# in preperation for replacing udp2log
node 'analytics1003.eqiad.wmnet' {
    include role::analytics
    include role::analytics::kafkatee::webrequest::mobile
}

node 'analytics1004.eqiad.wmnet' {
    include role::analytics

    # Nik will temporarly use analytics1004
    # to do some elasticsearch load testing.
    include accounts::manybubbles
}


# analytics1009 is the Hadoop standby NameNode
node 'analytics1009.eqiad.wmnet' {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    # analytics1009 is analytics Ganglia aggregator for Row A
    $ganglia_aggregator = true
    include standard
    include admins::roots

    # include analytics user accounts
    include role::analytics::users

    include role::analytics::kraken
    include role::analytics::hadoop::standby
}

# analytics1010 is the Hadoop master node
# (primary NameNode, ResourceManager, etc.)
node 'analytics1010.eqiad.wmnet' {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    # analytics1010 is analytics Ganglia aggregator for Row B
    $ganglia_aggregator = true
    include standard
    include admins::roots

    # include analytics user accounts
    include role::analytics::users

    include role::analytics::kraken
    include role::analytics::hadoop::master
}

# analytics1011-analytics1020 are Hadoop worker nodes
# NOTE:  If you add, remove or move Hadoop nodes, you should edit
# templates/hadoop/net-topology.py.erb to make sure the
# hostname -> /datacenter/rack/row id is correct.  This is
# used for Hadoop network topology awareness.
node /analytics10(1[1-9]|20).eqiad.wmnet/ {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    # analytics1014 is analytics Ganglia aggregator for Row C
    if $::hostname == 'analytics1014' {
        $ganglia_aggregator = true
    }
    include standard
    include admins::roots

    # include analytics user accounts
    include role::analytics::users

    include role::analytics::kraken
    include role::analytics::hadoop::worker
}

# analytics1021 and analytics1022 are Kafka Brokers.
node /analytics102[12]\.eqiad\.wmnet/ {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { 'main': }
    include standard
    include admins::roots

    include role::analytics
    include role::analytics::kafka::server
}

# analytics1023-1025 are zookeeper server nodes
node /analytics102[345].eqiad.wmnet/ {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    include standard
    include admins::roots

    include role::analytics
    include role::analytics::zookeeper::server
}

# analytics1026 is a Hadoop client and job submitter.
node 'analytics1026.eqiad.wmnet' {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    include standard
    include admins::roots

    # include analytics user accounts
    include role::analytics::users
    include role::analytics::kraken
    # Including kraken import and hive partition cron jobs.
    include role::analytics::kraken::jobs::import::pagecounts
    include role::analytics::kraken::jobs::hive::partitions::external
}

# analytics1027 hosts the frontend
# interfaces to Kraken and Hadoop.
# (Hue, Oozie, Hive, etc.)

node 'analytics1027.eqiad.wmnet' {
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = 'analytics'
    include standard
    include admins::roots

    include role::analytics::users
    include role::analytics::clients
    include role::analytics::hive::server
    include role::analytics::oozie::server
    include role::analytics::hue
}



# git.wikimedia.org
node 'antimony.wikimedia.org' {
    install_certificate{ 'git.wikimedia.org':
        ca => 'RapidSSL_CA.pem',
    }
    install_certificate{ 'svn.wikimedia.org':
        ca => 'RapidSSL_CA.pem',
    }

    include standard
    include groups::wikidev
    include accounts::demon
    include accounts::qchris # RT 6720
    include role::gitblit
    include role::subversion

    # full root for gerrit admin (RT-3698)
    sudo_user { 'demon':
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

node 'bast1001.wikimedia.org' {
    system::role { 'misc':
        description => 'Bastion Server',
    }
    $cluster = 'misc'
    $domain_search = 'wikimedia.org eqiad.wmnet pmtpa.wmnet esams.wikimedia.org'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include subversion::client
    include admins::roots
    include admins::mortals
    include admins::restricted
    include bastionhost
    include nrpe
    include nfs::netapp::home::othersite
    include misc::dsh
    include ssh::hostkeys-collect
}

node 'bast4001.wikimedia.org' {
    system::role { 'misc': description => 'Operations Bastion' }
    $cluster = 'misc'
    $domain_search = 'wikimedia.org eqiad.wmnet pmtpa.wmnet ulsfo.wmnet esams.wikimedia.org'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include admins::roots
    include misc::management::ipmi
    include role::installserver::tftp-server

    # TODO: should have bastionhost class and it should open ssh access
    # but it is ready yet. Fix and remove this. tftp-server includes
    # base::firewall and policy is set to DROP
    ferm::service { 'ssh':
        proto   => 'tcp',
        port    => 'ssh',
    }

}

node 'beryllium.wikimedia.org' {
    include standard-noexim
}

node 'boron.wikimedia.org' {
    include standard-noexim
}

node 'brewster.wikimedia.org' {

    $tftpboot_server_type = 'master'

    include standard
    include role::installserver
    include backup::client

    # set up brewster to use haproxy to proxy puppet
    # to palladium.
    include role::puppetproxy
}

node 'calcium.wikimedia.org' {
    $cluster = 'misc'

    include standard
    include groups::wikidev
    include accounts::robh

}

node 'carbon.wikimedia.org' {
    $cluster = 'misc'
    $ganglia_aggregator = true

    include standard
    include backup::client
    include role::installserver
}

node 'caesium.eqiad.wmnet' {
    $cluster = 'misc'

    include standard
    include role::releases
}

# cerium,praseodymium, ruthenium and xenon are cassandra test host
node /^(cerium|praseodymium|ruthenium|xenon)\.eqiad\.wmnet$/ {

    system::role { 'role::cassandra-test':
        description => 'Cassandra test server',
    }

    include standard
    include groups::wikidev
    include accounts::gwicke
    include accounts::ssastry

    sudo_user { ['gwicke', 'ssastry']:
        privileges => ['ALL = (ALL) NOPASSWD: ALL'],
    }

    # XXX: to be moved into the puppet class
    sysctl::parameters { 'cassandra':
        values => {
            'vm.max_map_count' => 1048575,
        },
    }
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
    include standard
    include role::dns::recursor

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^cp10(3[7-9]|40)\.eqiad\.wmnet$/ {
    if $::hostname =~ /^cp103[78]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::text
}

node /^cp104[34]\.eqiad\.wmnet$/ {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main': }

    include role::cache::misc
}

node 'cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { 'main': }

    include role::cache::parsoid
    include admins::parsoid
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    if $::hostname =~ /^cp104[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::mobile
}

node /^cp10(4[89]|5[01]|6[1-4])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^(cp1048|cp1061)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::upload
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^cp105[23]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::text
}

node 'cp1056.eqiad.wmnet', 'cp1057.eqiad.wmnet', 'cp1069.eqiad.wmnet', 'cp1070.eqiad.wmnet' {
    if $::hostname =~ /^cp105[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::bits
}

node /^cp300[12]\.esams\.wikimedia\.org$/ {
    interface::aggregate { 'bond0':
        orig_interface => 'eth0',
        members        => [ 'eth0', 'eth1' ],
    }

    interface::add_ip6_mapped { 'main':
        require   => Interface::Aggregate['bond0'],
        interface => 'bond0'
    }
    include standard
}

node /^cp30(0[3-9]|10)\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^cp300[34]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::upload
}

node /^cp301[1-4]\.esams\.wikimedia\.org$/ {
    interface::add_ip6_mapped { 'main': }

    include role::cache::mobile
}

node /^cp(3019|302[0-2])\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^cp(3019|3020)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::bits
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

    include role::cache::bits
    include role::cache::ssl::unified
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4005|4013)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::upload
    include role::cache::ssl::unified
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4008|4016)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::text
    include role::cache::ssl::unified
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp401[19]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main': }

    include role::cache::mobile
    include role::cache::ssl::unified
}

node 'dataset2.wikimedia.org' {
    $cluster = 'misc'
    $gid= '500'

    include accounts::brion
#    include role::download::primary
    include role::dataset::secondary
    include role::download::wikimedia
}

node 'dataset1001.wikimedia.org' {
    $cluster = 'misc'
    $gid= '500'
    interface::aggregate { 'bond0':
        orig_interface => 'eth0',
        members        => [ 'eth0', 'eth1' ],
    }

    include accounts::brion
#    include role::download::secondary
    include role::dataset::primary
    include role::download::wikimedia
}

# pmtpa dbs
node /^db(63)\.pmtpa\.wmnet/ {
    $ganglia_aggregator = true
    class { 'role::coredb::s1':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(69)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s2':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(71)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s3':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(72)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s4':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(73)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s5':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(74)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s6':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

node /^db(68)\.pmtpa\.wmnet/ {
    class { 'role::coredb::s7':
        # Sole mysql 5.1 pmtpa slave
        innodb_file_per_table => true,
    }
}

## x1 shard
node /^db(38)\.pmtpa\.wmnet/ {
    include role::coredb::x1
}

## m1 shard (new)
node /^db(35)\.pmtpa\.wmnet/ {
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

## m2 shard
node /^db(48)\.pmtpa\.wmnet/ {
    include role::coredb::m2
}

## researchdb
node 'db67.pmtpa.wmnet' {
    class { 'role::coredb::researchdb':
        mariadb => true,
    }
}

## imminent decomission/reclaim from pmtpa pending 12th floor reorg
node /^db(6[012456]|7[5-7])\.pmtpa\.wmnet/{
    include standard
}

# eqiad dbs
node /^db10(43|49|50|51|52|55|56|61|62)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(56)/ {
        $ganglia_aggregator = true
        include mha::manager
    }
    class { 'role::coredb::s1':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(02|09|18|36|60|63)\.eqiad\.wmnet/ {
    class { 'role::coredb::s2':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(03|19|35|38)\.eqiad\.wmnet/ {
    class { 'role::coredb::s3':
        # Many more tables than other shards.
        # innodb_file_per_table=off to reduce file handles.
        innodb_file_per_table => false,
        mariadb               => true,
    }
}

node /^db10(04|11|20|40|42|59)\.eqiad\.wmnet/ {
    class { 'role::coredb::s4':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(05|21|26|37|45|58)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db1021/ {
        $ganglia_aggregator = true
    }
    class { 'role::coredb::s5':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(06|10|15|22|23|30)\.eqiad\.wmnet/ {
    class { 'role::coredb::s6':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

node /^db10(07|28|33|34|39|41)\.eqiad\.wmnet/ {
    class { 'role::coredb::s7':
        innodb_file_per_table => true,
        mariadb               => true,
    }
}

## x1 shard
node /^db10(29|31)\.eqiad\.wmnet/ {
    include role::coredb::x1
}

## m1 shard
node /^db10(01|16)\.eqiad\.wmnet/ {
    class { 'role::coredb::m1':
        mariadb => true,
    }
}

## m2 shard
node /^db104[68]\.eqiad\.wmnet/ {
    if $::hostname =~ /^db1048/ {
        $ganglia_aggregator = true
    }
    if $::hostname =~ /^db1046/ {
        class { 'role::coredb::m2':
            mariadb => true,
        }
    } else {
        include role::coredb::m2
    }
}

## researchdb s1
node 'db1047.eqiad.wmnet' {
    class { 'role::coredb::researchdb':
        mariadb               => true,
        innodb_file_per_table => true,
    }
}

## researchdb s5
node 'db1017.eqiad.wmnet' {
    class { 'role::coredb::researchdb':
        shard                 => 's5',
        mariadb               => true,
        innodb_file_per_table => true,
        innodb_log_file_size  => '1000M'
    }
}

## SANITARIUM
node 'db1053.eqiad.wmnet' {
    class { 'role::db::sanitarium':
        instances => {
            's1' => {
                'port'                    => '3306',
                'innodb_log_file_size'    => '2000M',
                'ram'                     => '72G',
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
        }
    }
}

node 'db1054.eqiad.wmnet' {
    class { 'role::db::sanitarium':
        instances => {
            's2' => {
                'port'                   => '3306',
                'innodb_log_file_size'   => '2000M',
                'ram'                    => '24G',
                'repl_wild_ignore_tables'=> $::private_tables,
                'log_bin'                => true,
                'binlog_format'          => 'row',
            },
            's4' => {
                'port'                    => '3307',
                'innodb_log_file_size'    => '2000M',
                'ram'                     => '24G',
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
            's5' => {
                'port'                    => '3308',
                'innodb_log_file_size'    => '1000M',
                'ram'                     => '24G',
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin'                 => true,
                'binlog_format'           => 'row',
            },
        }
    }
}

node 'db1057.eqiad.wmnet' {
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

node 'db1014.eqiad.wmnet' {
    $cluster = 'misc'
    include standard
    include udpprofile::collector
}

node 'db1044.eqiad.wmnet' {
    include standard
    include role::mariadb::tendril
}

node /^dbstore100(1|2)\.eqiad\.wmnet/ {
    include standard
    include role::mariadb::dbstore
}

node 'dobson.wikimedia.org' {
    interface::ip { 'dns::recursor':
        interface => 'eth0',
        address   => '208.80.152.131',
    }

    include base
    include ganglia
    include exim::simple-mail-sender
    include dns::recursor::statistics
    include network::constants

    class { 'ntp::server':
        servers => [ '173.9.142.98',
                    '66.250.45.2',
                    '169.229.70.201',
                    '69.31.13.207',
                    '72.167.54.201'
        ],
        peers   => [ 'linne.wikimedia.org' ],
    }

    class { 'dns::recursor':
        listen_addresses => [ '208.80.152.131' ],
        allow_from       => $network::constants::all_networks
    }
    dns::recursor::monitor { '208.80.152.131': }
}

node 'dysprosium.eqiad.wmnet' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
}

node 'eeden.esams.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include role::authdns::ns2
}

node 'ekrem.wikimedia.org' {
    include standard
    include role::ircd
}

# base_analytics_logging_node is defined in role/logging.pp
node 'emery.wikimedia.org' inherits 'base_analytics_logging_node' {
    include generic::higher_min_free_kbytes
    include admins::mortals
    include accounts::milimetric # RT 4312
    include accounts::tnegrin    # RT 5391
    include role::logging::udp2log::emery
}

node 'tarin.pmtpa.wmnet' {
    $ganglia_aggregator = true
    include standard
    include role::poolcounter
}

node 'aluminium.wikimedia.org' {
    include role::fundraising::civicrm
    include accounts::file_mover

    interface::ip { 'fundraising.wikimedia.org':
        interface => 'eth0',
        address   => '208.80.154.12',
    }
}

# erbium is a webrequest udp2log host
node 'erbium.eqiad.wmnet' inherits 'base_analytics_logging_node' {
    # gadolinium hosts the separate nginx webrequest udp2log instance.
    include role::logging::udp2log::erbium
    include accounts::tnegrin       # RT 5391
}

# es1 equad
node /es100[1-4]\.eqiad\.wmnet/ {
    class { 'role::coredb::es1':
        mariadb => true,
    }
}

node /es4\.pmtpa\.wmnet/ {
    include role::coredb::es1
}

# es2-3
node /es7\.pmtpa\.wmnet/ {
  include role::coredb::es2
}

node /es8\.pmtpa\.wmnet/ {
  include role::coredb::es3
}

## imminent decomission/reclaim from pmtpa pending 12th floor reorg
node /^es([569]|10)\.pmtpa\.wmnet/{
    include standard
}

node /es100[5-7]\.eqiad\.wmnet/ {
    if $::hostname =~ /^es100[67]/ {
        class { 'role::coredb::es2':
            mariadb => true,
        }
    } else {
        include role::coredb::es2
    }
}

node /es10(0[89]|10)\.eqiad\.wmnet/ {
    if $::hostname =~ /^es10(09|10)/ {
        class { 'role::coredb::es3':
            mariadb => true,
        }
    } else {
        include role::coredb::es3
    }
}

node 'fenari.wikimedia.org' {
    system::role { 'misc':
        description => 'Bastion & NOC Server',
    }
    $cluster = 'misc'
    $domain_search = 'wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include role::applicationserver::maintenance
    include subversion::client
    include nfs::netapp::home
    include admins::roots
    include admins::mortals
    include admins::restricted
    include bastionhost
    include misc::noc-wikimedia
    include nrpe
    include drac
    include accounts::awjrichards
    include generic::wikidev-umask
    include misc::dsh
    include ssh::hostkeys-collect

    install_certificate{ 'noc.wikimedia.org': }
}

node 'fluorine.eqiad.wmnet' {
    $cluster = 'misc'

    include standard
    include admins::roots
    include admins::mortals
    include admins::restricted
    include nrpe

    class { 'role::logging::mediawiki':
        monitor       => false,
        log_directory => '/a/mw-log',
    }

}

node 'formey.wikimedia.org' {

    $sudo_privs = [ 'ALL = NOPASSWD: /usr/local/sbin/add-ldap-user',
            'ALL = NOPASSWD: /usr/local/sbin/delete-ldap-user',
            'ALL = NOPASSWD: /usr/local/sbin/modify-ldap-user',
            'ALL = NOPASSWD: /usr/local/bin/svn-group',
            'ALL = NOPASSWD: /usr/local/sbin/add-labs-user',
            'ALL = NOPASSWD: /var/lib/gerrit2/review_site/bin/gerrit.sh' ]
    sudo_user { [ 'robla', 'sumanah', 'reedy' ]: privileges => $sudo_privs }

    # full root for gerrit admin (RT-3698)
    sudo_user { 'demon': privileges => ['ALL = NOPASSWD: ALL'] }

    $gid = '550'
    $ldapincludes = ['openldap', 'nss', 'utils']
    $ssh_tcp_forwarding = 'no'
    $ssh_x11_forwarding = 'no'
    include standard
    include webserver::php5
    include role::subversion
    include backup::client
    include role::deployment::test

    class { 'ldap::role::client::labs':
        ldapincludes => $ldapincludes,
    }
}

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node 'gadolinium.wikimedia.org' inherits 'base_analytics_logging_node' {
    include accounts::milimetric
    include accounts::tnegrin     # RT 5391

    # relay the incoming webrequest log stream to multicast
    include role::logging::relay::webrequest-multicast
    # relay EventLogging traffic over to vanadium
    include role::logging::relay::eventlogging

    # gadolinium hosts the separate nginx webrequest udp2log instance.
    include role::logging::udp2log::nginx

    # gadolinium runs Domas' webstatscollector.
    # udp2log runs the 'filter' binary (on erbium)
    # which sends logs over to the 'collector' (on gadolinium)
    # service, which writes dump files in /a/webstats/dumps.
    include role::logging::webstatscollector
}

node 'gallium.wikimedia.org' {
    $cluster = 'misc'
    $gid= '500'
    sudo_user { [ 'demon', 'krinkle', 'reedy', 'mholmquist' ]:
        privileges => [
            'ALL = (jenkins) NOPASSWD: ALL',
            'ALL = (jenkins-slave) NOPASSWD: ALL',
            'ALL = (gerritslave) NOPASSWD: ALL',
            'ALL = NOPASSWD: /etc/init.d/jenkins',
            'ALL = (testswarm) NOPASSWD: ALL',
            'ALL = NOPASSWD: /etc/init.d/postgresql-8.4',
            'ALL = (postgres) NOPASSWD: /usr/bin/psql',
        ]
    }

    # Bug 49846, let us sync VisualEditor in mediawiki/extensions.git
    sudo_user { 'jenkins-slave':
        privileges => [
            'ALL = (jenkins) NOPASSWD: /srv/deployment/integration/slave-scripts/bin/gerrit-sync-ve-push.sh',
        ]
    }

    # full root for Jenkins admin (RT-4101)
    sudo_user { 'hashar':
        privileges => ['ALL = NOPASSWD: ALL'],
    }

    include standard
    include nrpe
    include contint::firewall
    include contint::android-sdk
    include role::ci::master
    include role::ci::slave
    include role::ci::testswarm
    include role::ci::website
    include role::zuul::production
    include admins::roots
    include admins::jenkins

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
    include standard
    include role::poolcounter
    include role::backup::director
    include role::backup::storage
}

node 'holmium.wikimedia.org' {
    include standard
    include admins::roots
    include misc::blogs::wikimedia
}

node 'hooft.esams.wikimedia.org' {
    $ganglia_aggregator = true
    $domain_search = 'esams.wikimedia.org wikimedia.org esams.wmnet'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include role::installserver::tftp-server
    include admins::roots
    include admins::mortals
    include admins::restricted

    # TODO: 2013-12-13. rsync is an unpuppetized service on hooft. Ferms is
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
    # TODO: should have bastionhost class and it should open ssh access
    # but it is ready yet. Fix and remove this
    ferm::service { 'ssh':
        proto   => 'tcp',
        port    => 'ssh',
    }

    class { 'ganglia_new::monitor::aggregator':
        sites =>  'esams',
    }
}

node 'manutius.wikimedia.org' {
    $corerouters = [
        'cr1-sdtpa.wikimedia.org',
        'cr2-pmtpa.wikimedia.org',
        'csw1-sdtpa.wikimedia.org',
        'cr1-esams.wikimedia.org',
        'cr2-knams.wikimedia.org',
        'csw2-esams.wikimedia.org',
        'cr1-eqiad.wikimedia.org',
        'cr2-eqiad.wikimedia.org',
        'cr1-ulsfo.wikimedia.org',
        'cr2-ulsfo.wikimedia.org',
        'mr1-pmtpa.mgmt.pmtpa.wmnet',
        'pfw1-eqiad.wikimedia.org'
    ]

    $accessswitches = [
        'asw-a4-sdtpa.mgmt.pmtpa.wmnet',
        'asw-a5-sdtpa.mgmt.pmtpa.wmnet',
        'asw-b-sdtpa.mgmt.pmtpa.wmnet',
        'asw-d-pmtpa.mgmt.pmtpa.wmnet',
        'asw-d1-sdtpa.mgmt.pmtpa.wmnet',
        'asw-d2-sdtpa.mgmt.pmtpa.wmnet',
        'asw-d3-sdtpa.mgmt.pmtpa.wmnet',
        'asw2-d3-sdtpa.mgmt.pmtpa.wmnet',
        'asw-a-eqiad.mgmt.eqiad.wmnet',
        'asw-b-eqiad.mgmt.eqiad.wmnet',
        'asw-c-eqiad.mgmt.eqiad.wmnet',
        'asw-d-eqiad.mgmt.eqiad.wmnet',
        'asw2-a5-eqiad.mgmt.eqiad.wmnet',
        'psw1-eqiad.mgmt.eqiad.wmnet',
        'msw1-eqiad.mgmt.eqiad.wmnet',
        'msw2-pmtpa.mgmt.pmtpa.wmnet',
        'msw2-sdtpa.mgmt.pmtpa.wmnet'
    ]

    $storagehosts = [
        'nas1-a.pmtpa.wmnet',
        'nas1-b.pmtpa.wmnet',
        'nas1001-a.eqiad.wmnet',
        'nas1001-b.eqiad.wmnet'
    ]

    include standard
    include webserver::apache
    include misc::torrus
    include misc::torrus::web
    include misc::torrus::xml-generation::cdn
    include ganglia::collector
    include passwords::network

    $snmp_ro_community = $passwords::network::snmp_ro_community

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

    class { 'ganglia_new::monitor::aggregator':
        sites => ['pmtpa', 'eqiad'],
    }
}

node 'hume.wikimedia.org' {
    $cluster = 'misc'

    include role::applicationserver::maintenance
    include mysql
    include nfs::netapp::home
    include nfs::upload
    include misc::deployment::scap_scripts
    include admins::roots
    include admins::mortals
    include admins::restricted
    include nrpe

    class { 'misc::maintenance::updatequerypages':
        enabled => false,
    }
    class { 'misc::maintenance::geodata':
        enabled => false,
    }
    class { 'misc::maintenance::update_flaggedrev_stats':
        enabled => false,
    }
    class { 'misc::maintenance::refreshlinks':
        enabled => false,
    }
    class { 'misc::maintenance::update_special_pages':
        enabled => false,
    }
}

node 'iron.wikimedia.org' {
    system::role { 'misc':
        description => 'Operations Bastion',
    }
    $cluster = 'misc'
    $domain_search = 'wikimedia.org eqiad.wmnet pmtpa.wmnet ulsfo.wmnet esams.wikimedia.org'

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include standard
    include admins::roots
    include misc::management::ipmi
    include role::access_new_install

    # search QA scripts for ops use
    include search::searchqa
}

## labsdb dbs
node 'labsdb1001.eqiad.wmnet' {
    class { 'role::db::labsdb':
        instances => {
            's1' => {
                'port'                           => '3306',
                'innodb_log_file_size'           => '2000M',
                'ram'                            => '120G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
        }
    }
}

node 'labsdb1002.eqiad.wmnet' {
    class { 'role::db::labsdb':
        instances => {
            's2' => {
                'port'                           => '3306',
                'innodb_log_file_size'           => '2000M',
                # kernel oom killer striking mysqld.
                #reduce footprint during investigation
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
            's4' => {
                'port'                           => '3307',
                'innodb_log_file_size'           => '2000M',
                # kernel oom killer striking mysqld.
                #reduce footprint during investigation
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
            's5' => {
                'port'                           => '3308',
                'innodb_log_file_size'           => '1000M',
                # kernel oom killer striking mysqld.
                #reduce footprint during investigation
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
        }
    }
}

node 'labsdb1003.eqiad.wmnet' {
    class { 'role::db::labsdb':
        instances => {
            's3' => {
                'port'                           => '3306',
                'innodb_log_file_size'           => '500M',
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
            's6' => {
                'port'                           => '3307',
                'innodb_log_file_size'           => '500M',
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
            's7' => {
                'port'                           => '3308',
                'innodb_log_file_size'           => '500M',
                'ram'                            => '32G',
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs'                => 'mysql',
                'slave_transaction_retries'      => '100000',
                'read_only'                      => '0',
                'max_user_connections'           => '512',
            },
        }
    }
}

node 'labsdb1004.eqiad.wmnet' {
    $osm_slave = 'labsdb1005.eqiad.wmnet'
    $osm_slave_v4 = '10.64.37.9'

    include role::osm::master
    #include role::labs::db::slave
}

node 'labsdb1005.eqiad.wmnet' {
    $osm_master = 'labsdb1004.eqiad.wmnet'

    include role::osm::slave
    #include role::labs::db::master
}

node /labstore[12]\.pmtpa\.wmnet/ {

    $site = 'pmtpa'
    $cluster = 'gluster'
    $ldapincludes = ['openldap', 'nss', 'utils']

    $ganglia_aggregator = true

    include standard
    include openstack::project-storage

    class { 'ldap::role::client::labs':
        ldapincludes => $ldapincludes,
    }

    if $::hostname =~ /^labstore2$/ {
        include openstack::project-storage-service
    }

}

node /labstore[34]\.pmtpa\.wmnet/ {

    $site = 'pmtpa'
    $cluster = 'labsnfs'
#    $ldapincludes = ['openldap', 'nss', 'utils']
#
#    $ganglia_aggregator = true

    include standard
#    include openstack::project-nfs-storage-service
#    include rsync::server
#
#    rsync::server::module {
#        'pagecounts':
#            path        => '/exp/pagecounts',
#            read_only   => 'false',
#            hosts_allow => ['208.80.154.11', '208.80.152.185'],
#    }
#
#    class { 'ldap::role::client::labs':
#        ldapincludes => $ldapincludes }
}

node /labstore100[12]\.eqiad\.wmnet/ {

    $site = 'eqiad'
    $cluster = 'labsnfs'
    $ldapincludes = ['openldap', 'nss', 'utils']

    $ganglia_aggregator = true

    include standard
    include openstack::project-nfs-storage-service
    include rsync::server

    rsync::server::module {
        'pagecounts':
            path        => '/srv/dumps/pagecounts',
            read_only   => 'false',
            hosts_allow => ['208.80.154.11', '208.80.152.185'];
    }

    class { 'ldap::role::client::labs': ldapincludes => $ldapincludes }
}

node 'lanthanum.eqiad.wmnet' {
    include standard
    include admins::roots
    include admins::jenkins
    include role::ci::slave  # RT #5074

    # Used as a Jenkins slave so some folks need escalated privileges
    $gid= '500'
    sudo_user { [ 'demon', 'krinkle', 'reedy', 'mholmquist' ]:
        privileges => [
        'ALL = (jenkins-slave) NOPASSWD: ALL',
        'ALL = (gerritslave) NOPASSWD: ALL',
        ]
    }

    # full root for Jenkins admin (RT-5677)
    sudo_user { 'hashar':
        privileges => ['ALL = NOPASSWD: ALL'],
    }

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

node 'linne.wikimedia.org' {
    interface::ip { 'url-downloader':
        interface => 'eth0',
        address   => '208.80.152.143',
    }

    include base
    include ganglia
    include exim::simple-mail-sender
    include url-downloader

    class { 'ntp::server':
        servers => [ '198.186.191.229',
                    '64.113.32.2',
                    '173.8.198.242',
                    '208.75.88.4',
                    '75.144.70.35',
        ],
        peers   => [ 'dobson.wikimedia.org' ],
    }
}

node /lvs100[1-6]\.wikimedia\.org/ {
    if $::hostname =~ /^lvs100[12]$/ {
        $ganglia_aggregator = true
    }

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

    # Make sure GRO is off
    interface::manual { 'eth1':
        interface => 'eth1',
        before    => Interface::Offload['eth1 gro'],
    }
    interface::manual { 'eth2':
        interface => 'eth2',
        before    => Interface::Offload['eth2 gro'],
    }
    interface::manual { 'eth3':
        interface => 'eth3',
        before    => Interface::Offload['eth3 gro'],
    }

    interface::offload { 'eth0 gro':
        interface => 'eth0',
        setting   => 'gro',
        value     => 'off',
    }
    interface::offload { 'eth1 gro':
        interface => 'eth1',
        setting   => 'gro',
        value     => 'off',
    }
    interface::offload { 'eth2 gro':
        interface => 'eth2',
        setting   => 'gro',
        value     => 'off',
    }
    interface::offload { 'eth3 gro':
        interface => 'eth3',
        setting   => 'gro',
        value     => 'off',
    }
}


# ULSFO lvs servers
node /^lvs400[1-4]\.ulsfo\.wmnet$/ {
    # lvs4001 and lvs4003 are in different racks
    if $::hostname =~ /^lvs400[13]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    # Make sure GRO is off
    interface::offload { 'eth0 gro':
        interface => 'eth0',
        setting   => 'gro',
        value     => 'off',
    }

    # bnx2x is buggy with TPA (LRO) + LVS
    interface::offload { 'eth0 lro':
        interface => 'eth0',
        setting   => 'lro',
        value     => 'off',
    }
}

node 'maerlant.esams.wikimedia.org' {
    include standard
}

node 'magnesium.wikimedia.org' {

    $cluster = 'misc'

    include role::racktables
    include role::rt
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    $cluster = 'memcached'
    if $::hostname =~ /^mc100[12]$/ {
        $ganglia_aggregator = true
    }

    include role::memcached
    include passwords::redis

    file { '/a':
        ensure => 'directory',
    }

    class { 'redis':
        maxmemory => '500Mb',
        password  => $passwords::redis::main_password,
    }
    include redis::ganglia
}

node /^rdb100[1-4]\.eqiad\.wmnet/ {
    $ganglia_aggregator = true

    $redis_replication = {
        'rdb1002' => 'rdb1001',
        'rdb1004' => 'rdb1003',
    }

    class { 'role::db::redis':
        redis_replication => $redis_replication,
    }
}

node 'rubidium.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include role::authdns::ns0
}

node 'mchenry.wikimedia.org' {
    $gid = '500'

    include base
    include ganglia
    include ntp::client
    include dns::recursor::statistics
    include nrpe
    include ldap::role::client::corp
    include backup::client
    include privateexim::aliases::private
    include exim::stats
    include groups::wikidev
    include accounts::jdavis
    include network::constants

    interface::ip { 'dns::recursor':
        interface => 'eth0',
        address   => '208.80.152.132',
    }

    class { 'dns::recursor':
        listen_addresses => ['208.80.152.132'],
        allow_from       => $network::constants::all_networks
    }

    dns::recursor::monitor { '208.80.152.132': }

    # mails the wikimedia.org mail alias file to OIT once per week
    class { 'misc::maintenance::mail_exim_aliases':
        enabled => true,
    }

    # TODO: This unfortunately will not work while mchenry is still hardy
    include backup::host
    backup::set { 'roothome': }
}

node 'mexia.wikimedia.org' {
    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
    include role::authdns::ns1
}

node /mobile100[1-4]\.wikimedia\.org/ {
    include standard-noexim
}

node 'ms6.esams.wikimedia.org' {
    interface::aggregate { 'bond0':
        orig_interface => 'eth0',
        members        => [ 'eth0', 'eth1', 'eth2', 'eth3' ],
    }

    include standard
}

node 'ms1001.wikimedia.org' {
    include standard
    include role::mirror::media
}

node 'ms1002.eqiad.wmnet' {
    include standard
}

node /ms100[4]\.eqiad\.wmnet/ {
    $cluster = 'misc'
    $ganglia_aggregator = true

    include standard
}

node /^ms-fe[1-4]\.pmtpa\.wmnet$/ {
    if $::hostname =~ /^ms-fe[12]$/ {
        $ganglia_aggregator = true
    }
    if $::hostname =~ /^ms-fe1$/ {
        include role::swift::pmtpa-prod::ganglia_reporter
    }

    class { 'lvs::realserver':
        realserver_ips => '10.2.1.27',
    }

    include role::swift::pmtpa-prod::proxy
}

node /^ms-be(3|[6-8]|10)\.pmtpa\.wmnet$/ {
    # the ms-be hosts that are 720xds with ssds have two more disks
    # but with the h310s they show up as m and n, those get the OS
    $all_drives = [ '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj',
        '/dev/sdk', '/dev/sdl' ]

    include role::swift::pmtpa-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sdm3': }
    swift::label_filesystem{ '/dev/sdn3': }
    swift::mount_filesystem{ '/dev/sdm3': }
    swift::mount_filesystem{ '/dev/sdn3': }
}

node /^ms-be(1|2|4|5|9|11|12)\.pmtpa\.wmnet$/ {
    # the ms-be hosts with ssds have two more disks
    # this is the 720xds with h710 layout
    $all_drives = [ '/dev/sdc', '/dev/sdd', '/dev/sde',
        '/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
        '/dev/sdl', '/dev/sdm', '/dev/sdn' ]

    include role::swift::pmtpa-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sda3': }
    swift::label_filesystem{ '/dev/sdb3': }
    swift::mount_filesystem{ '/dev/sda3': }
    swift::mount_filesystem{ '/dev/sdb3': }
}

node /^ms-fe100[1-4]\.eqiad\.wmnet$/ {
    if $::hostname =~ /^ms-fe100[12]$/ {
        $ganglia_aggregator = true
    }
    if $::hostname == 'ms-fe1001' {
        include role::swift::eqiad-prod::ganglia_reporter
    }

    class { 'lvs::realserver': realserver_ips => [ '10.2.2.27' ] }

    include role::swift::eqiad-prod::proxy
}

node /^ms-be10[0-9][0-9]\.eqiad\.wmnet$/ {
    $all_drives = [
        '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh',
        '/dev/sdi', '/dev/sdj', '/dev/sdk', '/dev/sdl'
    ]

    include role::swift::eqiad-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => '1' }
    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem{ '/dev/sdm3': }
    swift::label_filesystem{ '/dev/sdn3': }
    swift::mount_filesystem{ '/dev/sdm3': }
    swift::mount_filesystem{ '/dev/sdn3': }
}

node /^ms-be300[1-4]\.esams\.wikimedia\.org$/ {
    $cluster = 'ceph'

    if $::hostname =~ /^ms-be300[12]$/ {
        $ganglia_aggregator = true
    }

    include standard
}

# mw1001-1016 are jobrunners (precise)
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw100[12]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'mw1010' {
        include misc::deployment::scap_proxy
    }

    class { 'role::applicationserver::jobrunner':
        run_jobs_enabled => true,
    }

}

# mw1017-1113 are apaches (precise)
node /^mw1(01[7-9]|0[2-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw101[78]$/ {
        $ganglia_aggregator = true
    }

    if $::hostname == 'mw1070' {
        include misc::deployment::scap_proxy
    }


    # mw1017 is test.wikipedia.org (precise)
    if $::hostname == 'mw1017' {
        include role::applicationserver::appserver::test
    } else {
        include role::applicationserver::appserver
    }
}

# mw1114-1148 are api apaches (precise)
node /^mw11(1[4-9]|[23][0-9]|4[0-8])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw111[45]$/ {
        $ganglia_aggregator = true
    }

    include role::applicationserver::appserver::api
}

# mw1149-1152 are bits apaches (precise)
node /^mw11(49|5[0-2])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw115[12]$/ {
        $ganglia_aggregator = true
    }

    include role::applicationserver::appserver::bits
}

# mw1153-1160 are imagescalers (precise)
node /^mw11(5[3-9]|60)\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw115[34]$/ {
        $ganglia_aggregator = true
    }

    include role::applicationserver::imagescaler
}

# mw1161-1188 are apaches (precise)
node /^mw11(6[1-9]|7[0-9]|8[0-8])\.eqiad\.wmnet$/ {

    if $::hostname == 'mw1161' {
        include misc::deployment::scap_proxy
    }

    include role::applicationserver::appserver
}

# mw1189-1208 are api apaches (precise)
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {

    if $::hostname == 'mw1201' {
        include misc::deployment::scap_proxy
    }

    include role::applicationserver::appserver::api
}

# mw1209-1220 are apaches (precise)
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {

    include role::applicationserver::appserver
}

node 'neon.wikimedia.org' {
    $domain_search = 'wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org'

    $ircecho_logs = { '/var/log/icinga/irc.log' => '#wikimedia-operations' }
    $ircecho_nick = 'icinga-wm'
    $ircecho_server = 'chat.freenode.net'
    include standard
    include icinga::monitor
    include role::ishmael
    include role::echoirc
    include role::tendril
    include tcpircbot
    include passwords::logmsgbot

    tcpircbot::instance { 'logmsgbot':
        channels => '#wikimedia-operations',
        password => $passwords::logmsgbot::logmsgbot_password,
        cidr     => [
            '::ffff:10.64.21.123/128',    # vanadium
            '::ffff:10.64.0.196/128',     # tin
            '::ffff:208.80.152.165/128',  # fenari
            '::ffff:127.0.0.1/128',       # loopback
        ],
    }
}

node 'nescio.esams.wikimedia.org' {
    interface::ip { 'dns::recursor':
        interface => 'eth0',
        address   => '91.198.174.6',
    }

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
    include standard
    include webserver::apache
    include misc::rancid
    include smokeping
    include smokeping::web
    include role::librenms

    interface::add_ip6_mapped { 'main': }
}

node /^nfs[12].pmtpa.wmnet/ {

    $server_bind_ips = "127.0.0.1 ${ipaddress_eth0}"
    $cluster = 'misc'

    include standard
    include misc::nfs-server::home::rsyncd
    include backup::client
    include backup::host
    include role::syslog::centralserver
    backup::set { 'var-opendj-backups': }

    # don't need udp2log monitoring on nfs hosts
    class { 'role::logging::mediawiki':
        monitor       => false,
        log_directory => '/home/wikipedia/logs',
    }

}

node 'nickel.wikimedia.org' {
    $ganglia_aggregator = true

    include standard
    include ganglia::web
    include misc::monitoring::views

    install_certificate{ 'ganglia.wikimedia.org': }
}

node 'nitrogen.wikimedia.org' {

    include standard
    include role::ipv6relay

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^osm-cp100[1-4]\.wikimedia\.org$/ {
    include standard-noexim
}

# base_analytics_logging_node is defined in role/logging.pp
node 'oxygen.wikimedia.org' inherits 'base_analytics_logging_node' {
    include accounts::awjrichards
    include accounts::datasets
    include accounts::dsc
    include accounts::diederik
    include accounts::manybubbles #RT 4312
    include accounts::milimetric  #RT 4312
    include accounts::tnegrin     # RT 5391

    # main oxygen udp2log handles mostly Wikipedia Zero webrequest logs
        include role::logging::udp2log::oxygen
    # Also include lucene search loggging udp2log instance
        include role::logging::udp2log::lucene
}

node 'palladium.eqiad.wmnet' {
    include passwords::puppet::database

    include standard
    include backup::client
    include misc::management::ipmi
    include role::salt::masters::production
    include role::deployment::salt_masters::production
    include role::access_new_install

    class { 'puppetmaster':
        allow_from  => [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
        ],
        server_type => 'frontend',
        workers     => ['palladium.eqiad.wmnet',
                        'strontium.eqiad.wmnet'
        ],
        config      => {
            'thin_storeconfigs' => true,
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'db1001.eqiad.wmnet',
        }
    }
}

node /pc100[1-3]\.eqiad\.wmnet/ {

    include role::db::core
    include mysql_wmf::mysqluser
    include mysql_wmf::datadirs
    include mysql_wmf::pc::conf

    class { mysql_wmf::packages : mariadb => true }

    system::role { 'mysql::pc::conf':
        description => 'parser cache mysql server',
    }
}

node 'pdf2.wikimedia.org' {
    $ganglia_aggregator = true
    $cluster = 'pdf'

    include role::pdf
    include groups::wikidev
    include accounts::file_mover
    include accounts::mwalker     #rt 6468
}

node 'pdf3.wikimedia.org' {
    $cluster = 'pdf'

    include role::pdf
    include groups::wikidev
    include accounts::file_mover
    include accounts::mwalker     #rt 6468
}

node 'potassium.eqiad.wmnet' {
    include standard
    include role::poolcounter
}

# QA box for the new PDF system
node 'tantalum.eqiad.wmnet' {
    $gid = '500'
    include standard
    include role::ocg::test
    include groups::wikidev
    include admins::roots
    include accounts::mwalker
    include accounts::maxsem
    include accounts::anomie
    include accounts::cscott
}

node 'sanger.wikimedia.org' {
    $gid = '500'

    include base
    include ganglia
    include ntp::client
    include nrpe
    include ldap::role::server::corp
    include ldap::role::client::corp
    include groups::wikidev
    include accounts::jdavis
    include backup::client
}

node /^search100[0-6]\.eqiad\.wmnet/ {
    if $::hostname =~ /^search100(1|2)$/ {
        $ganglia_aggregator = true
    }

    include role::lucene::front_end::pool1
}

node /^search10(0[7-9]|10)\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool2
}

node /^search101[1-4]\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool3
}

node /^search101[56]\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool4
}

node /^search10(19|20)\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool5
}

node /^search101[78]\.eqiad\.wmnet/ {

    include role::lucene::front_end::prefix
}

node /^search10(19|2[0-2])\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool4
}

node /^search102[3-4]\.eqiad\.wmnet/ {

    include role::lucene::front_end::pool3
}

node /^searchidx100[0-2]\.eqiad\.wmnet/ {

    include role::lucene::indexer
}

node 'silver.wikimedia.org' {
    include standard
    include groups::wikidev
    include mobile::vumi
    include mobile::vumi::udp2log
}

node 'sodium.wikimedia.org' {

    system::role { 'role::lists':
        description => 'Mailing list server',
    }

    $nameservers_prefix = [ $ipaddress ]

    include base
    include ganglia
    include ntp::client
    include nrpe
    include mailman
    include dns::recursor
    include backup::client

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $network::constants::all_networks,
    }

    class { 'exim::roled':
        outbound_ips           => [ '208.80.154.61',
                                    '2620:0:861:1:208:80:154:61'
        ],
        list_outbound_ips      => [ '208.80.154.4',
                                    '2620:0:861:1::2'
        ],
        local_domains          => [ '+system_domains',
                                    '+mailman_domains'
        ],
        enable_mail_relay      => 'secondary',
        enable_mailman         => 'true',
        enable_mail_submission => 'false',
        enable_spamassassin    => 'true',
    }

    interface::ip { 'lists.wikimedia.org_v4':
        interface => 'eth0',
        address   => '208.80.154.4',
        prefixlen => '32',
    }

    interface::ip { 'lists.wikimedia.org_v6':
        interface => 'eth0',
        address   => '2620:0:861:1::2',
        prefixlen => '128',
    }
}

node /ssl100[1-9]\.wikimedia\.org/ {
    if $::hostname =~ /^ssl100[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }

    include role::protoproxy::ssl
}

node /ssl300[1-4]\.esams\.wikimedia\.org/ {
    if $::hostname =~ /^ssl300[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { 'main':
        interface => 'eth0'
    }

    include role::protoproxy::ssl
}

node 'stafford.pmtpa.wmnet' {
    include standard

    # Display notice that this is no longer an active puppetmaster.
    file { '/etc/update-motd.d/99-obsolete-puppetmaster':
        ensure => 'present',
        source => 'puppet:///modules/puppetmaster/motd/99-obsolete',
    }
}

node 'strontium.eqiad.wmnet' {
    include standard
    include passwords::puppet::database

    class { 'puppetmaster':
        allow_from  => [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
        ],
        server_type => 'backend',
        config      => {
            'thin_storeconfigs' => true,
            'ca'                => 'false',
            'ca_server'         => 'palladium.eqiad.wmnet',
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'db1001.eqiad.wmnet',
            'dbconnections'     => '256',
        }
    }
}

node 'stat1.wikimedia.org' {
    include standard
    include admins::roots

    include role::statistics::cruncher

    # special accounts
    include admins::globaldev  # RT 3119
    include accounts::ezachte
    include accounts::abartov      # RT 4106
    include accounts::aengels
    include accounts::akhanna
    include accounts::bsitu        # RT 4959
    include accounts::milimetric   # RT 3540
    include accounts::diederik
    include accounts::dsc
    include accounts::dartar
    include accounts::declerambaul
    include accounts::ebernhardson # RT 4959,5717
    include accounts::fflorin      # RT 6011
    include accounts::fschulenburg # RT 4475, revoked RT 7117
    include accounts::giovanni     # RT 3460,revoked 6854
    include accounts::halfak
    include accounts::howief       # RT 3576
    include accounts::ironholds
    include accounts::jdlrobson
    include accounts::jgonera
    include accounts::jmorgan
    include accounts::kaldari      # RT 4959
    include accounts::spage
    include accounts::maryana      # RT 3517
    include accounts::mflaschen    # RT 4796
    include accounts::mgrover      # RT 4600,revoked 6854
    include accounts::mlitn        # RT 4959
    include accounts::otto
    include accounts::reedy
    include accounts::rfaulk       # RT 5040
    include accounts::spetrea      # RT 3584
    include accounts::swalling     # RT 3653
    include accounts::yurik        # RT 4835
    include accounts::mwalker      # RT 5038
    include accounts::awight       # RT 5048
    include accounts::jforrester   # RT 5302
    include accounts::qchris       # RT 5474
    include accounts::tnegrin      # RT 5391
    include accounts::kwang        # RT 5520
    include accounts::siebrand     # RT 5726
    include accounts::mholmquist   # RT 6009
    include accounts::msyed        # RT 6506
    include accounts::nuria        # RT 6525
    include accounts::csalvia      # RT 6664
    include accounts::leila        # RT 6765
    include accounts::gdubuc       # RT 7074

    sudo_user { 'otto':
        privileges => ['ALL = NOPASSWD: ALL'],
    }

    # Allow Christian to sudo -u stats
    # to debug and test stats' automated cron jobs.
    sudo_user { 'qchris':
        privileges => ['ALL = (stats) NOPASSWD: ALL'],
    }

    include misc::statistics::cron_blog_pageviews
    include misc::statistics::limn::mobile_data_sync
    include misc::statistics::iptables
}

node 'stat1001.wikimedia.org' {
    include standard
    include admins::roots

    include role::statistics::www

    # special accounts
    include accounts::ezachte
    include accounts::diederik
    include accounts::otto
    include accounts::dsc
    include accounts::milimetric
    include accounts::rfaulk   # RT 4258
    include accounts::ypanda   # RT 4687
    include accounts::qchris   # RT 5474
    include accounts::tnegrin  # RT 5391

    sudo_user { 'otto':
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

node 'stat1002.eqiad.wmnet' {
    include standard
    include admins::roots

    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    # Users in the admins::privatedata
    # class have access to stat1002 so that
    # they can do analysis on webrequest logs
    # and other private data.
    include admins::privatedata

    # add ezachte, spetrea, ironholds to stats group so they can
    # access files created by stats user cron jobs.
    User<|title == ezachte|>     { groups +> [ 'stats' ] }
    User<|title == spetrea|>     { groups +> [ 'stats' ] }
    User<|title == ironholds|>   { groups +> [ 'stats' ] }

    sudo_user { 'otto':
        privileges => ['ALL = NOPASSWD: ALL'],
    }

    # include classes needed for storing and crunching
    # private data on stat1002.
    include role::statistics::private

    # Include Hadoop and other analytics cluster
    # clients so that analysts can use the number
    # crunching packages already installed on stat1002
    # in post processing of Hadoop generated datasets.
    include role::analytics::clients
}

# stat1003 is a general purpose number cruncher for
# researchers and analysts.  It is primarily used
# to connect to MySQL research databases and save
# query results for further processing on this node.
node 'stat1003.wikimedia.org' {
    include standard
    include admins::roots

    include role::statistics::cruncher

    include misc::statistics::cron_blog_pageviews
    include misc::statistics::limn::mobile_data_sync

    # special accounts
    include admins::globaldev      # RT 3119
    include accounts::ezachte
    include accounts::milimetric   # RT 3540
    include accounts::diederik
    include accounts::dartar
    include accounts::halfak
    include accounts::howief       # RT 3576
    include accounts::ironholds
    include accounts::jdlrobson
    include accounts::jgonera
    include accounts::jmorgan
    include accounts::kaldari      # RT 4959
    include accounts::maryana      # RT 3517
    include accounts::mflaschen    # RT 4796
    include accounts::spetrea      # RT 3584
    include accounts::swalling     # RT 3653
    include accounts::yurik        # RT 4835
    include accounts::awight       # RT 5048
    include accounts::jforrester   # RT 5302
    include accounts::qchris       # RT 5474
    include accounts::tnegrin      # RT 5391
    include accounts::mholmquist   # RT 6009
    include accounts::msyed        # RT 6506
    include accounts::nuria        # RT 6525
    include accounts::csalvia      # RT 6664
    include accounts::leila        # RT 6765
    include accounts::gdubuc       # RT 7074

    # Allow Christian to sudo -u stats
    # to debug and test stats' automated cron jobs.
    sudo_user { 'qchris':
        privileges => ['ALL = (stats) NOPASSWD: ALL'],
    }

}

node 'snapshot1001.eqiad.wmnet' {
    $gid= '500'
    include snapshot
    class { 'snapshot::dumps': hugewikis => true }
}
node /^snapshot100[24]\.eqiad\.wmnet/ {
    $gid= '500'
    include snapshot
    include snapshot::dumps
}
node 'snapshot1003.eqiad.wmnet' {
    $gid= '500'
    include snapshot
    include snapshot::dumps
    include role::snapshot::cron::primary
}

node 'terbium.eqiad.wmnet' {
    include role::applicationserver::maintenance
    include role::db::maintenance
    include misc::deployment::scap_scripts
    include icinga::monitor::jobqueue
    include misc::monitoring::jobqueue
    include admins::roots
    include admins::mortals
    include admins::restricted
    include generic::wikidev-umask
    include nrpe


    class { 'misc::maintenance::pagetriage':
        enabled => true,
    }
    class { 'misc::maintenance::translationnotifications':
        enabled => true,
    }
    class { 'misc::maintenance::updatetranslationstats':
        ensure => 'present',
    }
    class { 'misc::maintenance::wikidata':
        enabled => true,
    }
    class { 'misc::maintenance::echo_mail_batch':
        enabled => true,
    }
    class { 'misc::maintenance::parsercachepurging':
        enabled => true,
    }
    class { 'misc::maintenance::cleanup_upload_stash':
        enabled => true,
    }
    class { 'misc::maintenance::tor_exit_node':
        enabled => true,
    }
    class { 'misc::maintenance::geodata':
        enabled => true,
    }
    class { 'misc::maintenance::update_flaggedrev_stats':
        enabled => true,
    }
    class { 'misc::maintenance::refreshlinks':
        enabled => true,
    }
    class { 'misc::maintenance::update_special_pages':
        enabled => true,
    }
    class { 'misc::maintenance::purge_abusefilter':
        enabled => true,
    }
    class { 'misc::maintenance::purge_checkuser':
        enabled => true,
    }

    # (bug 15434) Periodical run of currently disabled special pages
    # to be run against PMTPA slaves
    class { 'misc::maintenance::updatequerypages':
        enabled => true,
    }
}

node /^elastic10(0[1-9]|1[0-6])\.eqiad\.wmnet/ {
    # ganglia cluster name.
    $cluster = 'elasticsearch'
    if $::hostname =~ /^elastic10(0[17]|13)/ {
        $ganglia_aggregator = true
    }

    include accounts::manybubbles
    include accounts::demon
    include groups::wikidev

    sudo_user { ['manybubbles', 'demon'] :
        privileges => ['ALL = NOPASSWD: ALL'],
    }

    include standard
    include role::elasticsearch::server

    class { 'lvs::realserver':
        realserver_ips => '10.2.2.30',
    }
}

node /^logstash100[1-3]\.eqiad\.wmnet$/ {
    $cluster = 'logstash'
    if $::hostname =~ /^logstash100[13]$/ {
        $ganglia_aggregator = true
    }

    include standard
    include role::logstash
    include role::kibana
    include groups::wikidev
    include accounts::aaron
    include accounts::bd808
    include accounts::manybubbles
    include accounts::demon

    sudo_user { ['aaron', 'bd808', 'manybubbles', 'demon']:  # RT 6366, 6896
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

node 'tin.eqiad.wmnet' {
    $cluster = 'misc'
    $domain_search = 'wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org'

    include standard
    include admins::roots
    include admins::mortals
    include generic::wikidev-umask
    include role::deployment::deployment_servers::production
    include misc::deployment
    include misc::deployment::scap_scripts
    include misc::deployment::l10nupdate
    include mysql
    include role::labsdb::manager
    include ssh::hostkeys-collect

    # for reedy RT #6322
    package { 'unzip':
        ensure => 'present',
    }
}

# titinium hosts archiva.wikimedia.org
node 'titanium.wikimedia.org' {
    $cluster = 'misc'

    include standard
    include admins::roots

    include role::archiva
}


node 'tridge.wikimedia.org' {

    system::role { 'role::backup':
        description => 'Backup server',
    }

    include base
    include backup::server
}

# tmh1001/tmh1002 video encoding server (precise only)
node /^tmh100[1-2]\.eqiad\.wmnet/ {
    if $::hostname =~ /^tmh100[12]$/ {
        $ganglia_aggregator = true
    }
    class { 'role::applicationserver::videoscaler':
        run_jobs_enabled => true,
    }

}

# Receives log data from varnishes (udp 8422) and Apaches (udp 8421),
# processes it, and broadcasts to internal subscribers.
node 'vanadium.eqiad.wmnet' {
    $gid = '500'

    include standard
    include role::eventlogging
    include role::ipython_notebook
    include role::logging::mediawiki::errors
    include groups::wikidev
    include accounts::nuria         # RT 6535

    sudo_user { 'nuria':
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors.
node 'hafnium.wikimedia.org' {
    include standard
    include role::eventlogging::graphite
    include role::webperf
}

# Primary Graphite, StatsD, and profiling data aggregation host.
node 'tungsten.eqiad.wmnet' {
    include standard
    include role::graphite
    include role::txstatsd
    include role::gdash
    include role::mwprof
    include role::performance
}

node 'virt1000.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    $is_puppet_master      = 'true'
    $is_labs_puppet_master = 'true'
    $openstack_version     = 'havana'
    $use_neutron = false

    include admins::labs

    include standard
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

node 'virt0.wikimedia.org' {
    $cluster               = 'virt'
    $ganglia_aggregator    = true
    $is_puppet_master      = 'true'
    $is_labs_puppet_master = 'true'
    $openstack_version     = 'folsom'
    $use_neutron = false

    include admins::labs

    include standard
    include role::dns::ldap
    include ldap::role::server::labs
    include ldap::role::client::labs
    include role::nova::controller
    include role::nova::manager
    include role::salt::masters::labs
    include role::deployment::salt_masters::labs
    include backup::client
}

node 'virt2.pmtpa.wmnet' {
    $cluster           = 'virt'
    $openstack_version = 'folsom'
    $use_neutron = false

    include admins::labs

    include standard
    include role::nova::network
    include role::nova::api
}

node /virt([5-9]|1[0-5]).pmtpa.wmnet/ {
    $cluster = 'virt'
    if $::hostname =~ /^virt5$/ {

        $ganglia_aggregator = true
    }

    $openstack_version = 'folsom'
    $use_neutron = false

    include admins::labs

    include standard
    include role::nova::compute
}

node 'labnet1001.eqiad.wmnet' {
    $cluster = 'virt'
    $openstack_version = 'havana'
    $use_neutron = false

    $ganglia_aggregator = true

    include standard
    include role::nova::api
    include admins::labs

    if $use_neutron == true {
        include role::neutron::nethost
    } else {
        include role::nova::network
    }
}

node /virt100[1-7].eqiad.wmnet/ {
    $cluster = 'virt'
    $openstack_version = 'havana'
    $use_neutron = false

    include standard
    include role::nova::compute
    if $use_neutron == true {
        include role::neutron::computenode
    }
}

node /virt100[8-9].eqiad.wmnet/ {
    $cluster = 'virt'
    include admins::labs

    include standard
}

node 'iodine.wikimedia.org' {
    include role::otrs

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    $cluster = 'parsoid'
    $nagios_group = "${cluster}_${::site}"

    if $::hostname == 'wtp1001' {
        $ganglia_aggregator = true
    }

    include standard
    include admins::roots
    include admins::parsoid
    include role::parsoid::production

    class { 'lvs::realserver':
        realserver_ips => ['10.2.2.28'],
    }
}

node /^solr100[1-3]\.eqiad\.wmnet/ {
    include standard
    include role::solr::geodata
}

node 'ytterbium.wikimedia.org' {

    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::production
    include role::gerrit::production
    include backup::client
    include groups::wikidev
    include accounts::demon
    include accounts::qchris # RT 6720

    install_certificate{ 'gerrit.wikimedia.org':
        ca => 'RapidSSL_CA.pem',
    }

    # full root for gerrit admin (RT-3698)
    sudo_user { 'demon':
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

node 'zinc.eqiad.wmnet' {

    include standard
    include role::solr::ttm
}

node 'zirconium.wikimedia.org' {
    include standard
    include admins::roots
    include nrpe
    include role::planet
    include misc::outreach::civicrm # contacts.wikimedia.org
    include misc::etherpad_lite
    include role::wikimania_scholarships
    include role::bugzilla
    include groups::wikidev
    include accounts::bd808 # rt 6448

    interface::add_ip6_mapped { 'main':
        interface => 'eth0',
    }
}

node default {
    include standard
}

# as of 2013-11-18 these fundraising servers use frack puppet
#
# barium.frack.eqiad.wmnet
# boron.frack.eqiad.wmnet
# db78.pmtpa.wmnet
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
