# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
#site.pp

import "realm.pp" # These ones first
import "generic-definitions.pp"

import "admins.pp"
import "backups.pp"
import "certs.pp"
import "decommissioning.pp"
import "dns.pp"
import "facilities.pp"
import "ganglia.pp"
import "gerrit.pp"
import "imagescaler.pp"
import "iptables.pp"
import "mail.pp"
import "misc/*.pp"
import "mobile.pp"
import "nagios.pp"
import "network.pp"
import "nfs.pp"
import "openstack.pp"
import "poolcounter.pp"
import "role/*.pp"
import "role/analytics/*.pp"
import "search.pp"
import "snapshots.pp"
import "sudo.pp"
import "svn.pp"
import "swift.pp"
import "webserver.pp"
import "zuul.pp"

# Include stages last
import "stages.pp"

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard {
    include base,
        ganglia,
        ntp::client,
        exim::simple-mail-sender
}

class standard-noexim {
    include base,
        ganglia,
        ntp::client
}


# Default variables
$cluster = "misc"

# Node definitions (alphabetic order)

node /^amslvs[1-4]\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^amslvs[12]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    interface::add_ip6_mapped { "main": interface => "eth0" }

    # Make sure GRO is off
    interface::offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
}

# amssq47 is a text varnish
node /^amssq47\.esams\.wikimedia\.org$/ {
    include role::cache::text, role::cache::ssl::unified

    interface::add_ip6_mapped { "main": }
}

# amssq48-62 are text varnish
node /^amssq(4[8-9]|5[0-9]|6[0-2])\.esams\.wikimedia\.org$/ {

    sysctl::parameters { 'vm dirty page flushes':
        values => {
            'vm.dirty_background_ratio' => 5,
        }
    }

    include role::cache::text

    interface::add_ip6_mapped { "main": }
}

# analytics1003 and analytics1004 are temporarily
# test Kafka Brokers.
node /analytics100[34]\.wikimedia\.org/ {
    include role::analytics
}

# analytics1009 is the Hadoop standby NameNode
node "analytics1009.eqiad.wmnet" {
    # analytics1009 is analytics Ganglia aggregator for Row A
    $ganglia_aggregator = true

    # include analytics user accounts
    include role::analytics::users

    include role::analytics::kraken
    include role::analytics::hadoop::standby
}

# analytics1010 is the Hadoop master node
# (primary NameNode, ResourceManager, etc.)
node "analytics1010.eqiad.wmnet" {
    # analytics1010 is analytics Ganglia aggregator for Row B
    $ganglia_aggregator = true

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
    # analytics1014 is analytics Ganglia aggregator for Row C
    if $::hostname == 'analytics1014' {
        $ganglia_aggregator = true
    }
    # include analytics user accounts
    include role::analytics::users

    include role::analytics::kraken
    include role::analytics::hadoop::worker
}

# analytics1021 and analytics1022 are Kafka Brokers.
node /analytics102[12]\.eqiad\.wmnet/ {
    # Kafka brokers are routed via IPv6 so that
    # other DCs can address without public IPv4
    # addresses.
    interface::add_ip6_mapped { "main": }

    include role::analytics
    include role::analytics::kafka::server
}

# analytics1023-1025 are zookeeper server nodes
node /analytics102[345].eqiad.wmnet/ {
    include role::analytics
    include role::analytics::zookeeper::server
}

# analytics1026 is a Hadoop client and job submitter.
node "analytics1026.eqiad.wmnet" {
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
node "analytics1027.eqiad.wmnet" {
    include role::analytics::clients
    include role::analytics::hive::server
    include role::analytics::oozie::server
    include role::analytics::hue
}



# git.wikimedia.org
node "antimony.wikimedia.org" {
    install_certificate{ "git.wikimedia.org": ca => "RapidSSL_CA.pem" }

    include standard,
        groups::wikidev,
        accounts::demon,
        role::gitblit,
        svn::server

    # full root for gerrit admin (RT-3698)
    sudo_user { "demon": privileges => ['ALL = NOPASSWD: ALL'] }
}

node "arsenic.eqiad.wmnet" {
    include role::applicationserver::maintenance,
        role::db::maintenance,
        misc::deployment::scap_scripts,
        admins::roots,
        admins::mortals,
        generic::wikidev-umask,
        nrpe,
        accounts::demon,
        groups::wikidev

    # rt 6189: temporary root for testing
    sudo_user { [ "demon" ]: privileges => ['ALL = NOPASSWD: ALL'] }

    #just adding this for the mediawiki require
    class { misc::maintenance::pagetriage: enabled => false }
}


node "bast1001.wikimedia.org" {
    system::role { "misc": description => "Bastion Server" }
    $cluster = "misc"
    $domain_search = "wikimedia.org eqiad.wmnet pmtpa.wmnet esams.wikimedia.org"

    include standard,
        svn::client,
        admins::roots,
        admins::mortals,
        admins::restricted,
        bastionhost,
        nrpe,
        nfs::netapp::home::othersite,
        misc::dsh,
        ssh::hostkeys-collect
}

node "bast4001.wikimedia.org" {
    system::role { "misc": description => "Operations Bastion" }
    $cluster = "misc"
    $domain_search = "wikimedia.org eqiad.wmnet pmtpa.wmnet ulsfo.wmnet esams.wikimedia.org"

    include standard,
    admins::roots,
    misc::management::ipmi,
    role::installserver::tftp-server

    # TODO: should have bastionhost class and it should open ssh access
    # but it is ready yet. Fix and remove this. tftp-server includes
    # base::firewall and policy is set to DROP
    ferm::service { 'ssh':
        proto   => 'tcp',
        port    => 'ssh',
    }

}

node "beryllium.wikimedia.org" {
    include standard-noexim
}

node "boron.wikimedia.org" {
    include standard-noexim
}

node "brewster.wikimedia.org" {

    $tftpboot_server_type = 'master'

    include standard,
        role::installserver,
        backup::client

    # set up brewster to use haproxy to proxy puppet
    # to palladium.
    include role::puppetproxy
}

node "calcium.wikimedia.org" {
    $cluster = "misc"

    include standard,
        groups::wikidev,
        accounts::robh

}

node /^(capella|nitrogen)\.wikimedia\.org$/ {

    include standard,
        role::ipv6relay

    interface::add_ip6_mapped { "main": interface => "eth0" }
}
node "carbon.wikimedia.org" {
    $cluster = "misc"
    $ganglia_aggregator = true

    include standard,
        backup::client,
        role::installserver
}

# cerium,praseodymium, ruthenium and xenon are cassandra test host
node /^(cerium|praseodymium|ruthenium|xenon)\.eqiad\.wmnet$/ {
    include standard

    include groups::wikidev, accounts::gwicke
    sudo_user { 'gwicke':
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
    include standard,
            role::dns::recursor

    interface::add_ip6_mapped { "main": interface => "eth0" }
}

node /^cp10(3[7-9]|40)\.eqiad\.wmnet$/ {
    if $::hostname =~ /^cp103[78]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::text
}

node /^cp104[34]\.eqiad\.wmnet$/ {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { "main": }

    include role::cache::misc
}

node 'cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet' {
    $ganglia_aggregator = true

    interface::add_ip6_mapped { "main": }

    include role::cache::parsoid, admins::parsoid
}

node 'cp1046.eqiad.wmnet', 'cp1047.eqiad.wmnet', 'cp1059.eqiad.wmnet', 'cp1060.eqiad.wmnet' {
    if $::hostname =~ /^cp104[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::mobile
}

node /^cp10(4[89]|5[01]|6[1-4])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^(cp1048|cp1061)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::upload
}

node /^cp10(5[2-5]|6[5-8])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^cp105[23]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::text
}

node 'cp1056.eqiad.wmnet', 'cp1057.eqiad.wmnet', 'cp1069.eqiad.wmnet', 'cp1070.eqiad.wmnet' {
    if $::hostname =~ /^cp105[67]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::bits
}

node /^cp300[12]\.esams\.wikimedia\.org$/ {
    interface::aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }

    interface::add_ip6_mapped { "main":
        require => Interface::Aggregate[bond0],
        interface => "bond0"
    }
    include standard
}

node /^cp30(0[3-9]|10)\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^cp300[34]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::upload
}

node /^cp301[1-4]\.esams\.wikimedia\.org$/ {
    interface::add_ip6_mapped { "main": }

    include role::cache::mobile
}

node /^cp(3019|302[0-2])\.esams\.wikimedia\.org$/ {
    if $::hostname =~ /^cp(3019|3020)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

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

    interface::add_ip6_mapped { "main": }

    include role::cache::bits, role::cache::ssl::unified
}

node /^cp40(0[5-7]|1[3-5])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4005|4013)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::upload, role::cache::ssl::unified
}

node /^cp40(0[89]|1[0678])\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp(4008|4016)$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::text, role::cache::ssl::unified
}

node /^cp40(1[129]|20)\.ulsfo\.wmnet$/ {
    if $::hostname =~ /^cp401[19]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": }

    include role::cache::mobile, role::cache::ssl::unified
}

node "dataset2.wikimedia.org" {
    $cluster = "misc"
    $gid=500

    include accounts::brion
    include role::download::primary
}

node "dataset1001.wikimedia.org" {
    $cluster = "misc"
    $gid=500
    interface::aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }

    include accounts::brion
    include role::download::secondary
}

# pmtpa dbs
node /^db(63)\.pmtpa\.wmnet/ {
    class { role::coredb::s1 : mariadb => true, innodb_file_per_table => true }
}

node /^db(69)\.pmtpa\.wmnet/ {
    class { role::coredb::s2 : mariadb => true, innodb_file_per_table => true }
}

node /^db(71)\.pmtpa\.wmnet/ {
    class { role::coredb::s3 : mariadb => true, innodb_file_per_table => true }
}

node /^db(72)\.pmtpa\.wmnet/ {
    class { role::coredb::s4 : mariadb => true, innodb_file_per_table => true }
}

node /^db(73)\.pmtpa\.wmnet/ {
    class { role::coredb::s5 : mariadb => true, innodb_file_per_table => true }
}

node /^db(74)\.pmtpa\.wmnet/ {
    class { role::coredb::s6 : mariadb => true, innodb_file_per_table => true }
}

node /^db(68)\.pmtpa\.wmnet/ {
    class { role::coredb::s7 : innodb_file_per_table => true }
}

## x1 shard
node /^db(38)\.pmtpa\.wmnet/ {
    include role::coredb::x1
}

## m1 shard (used to be db9|blondel|bellin in the past)
node "db9.pmtpa.wmnet" {
    include role::db::core
}

## m1 shard (new)
node /^db(35)\.pmtpa\.wmnet/ {
    class { role::coredb::m1 : mariadb => true }
}

## m2 shard
node /^db(48)\.pmtpa\.wmnet/ {
    include role::coredb::m2
}

## researchdb
node 'db67.pmtpa.wmnet' {
    class { role::coredb::researchdb : mariadb => true }
}

## pgehres special project
node 'db29.pmtpa.wmnet' {
    $gid = 500
    system::role { "role::admin_tools_sul_audit_db": description => "Admin Tools/SUL Audit database" }
    include base,
        standard,
        mysql_wmf,
        #mysql::conf, doing this by hand b/c this is a weird short-term use box
        mysql_wmf::datadirs,
        mysql_wmf::mysqluser,
        mysql_wmf::packages,
        ntp::client,
        admins::roots,
        accounts::pgehres
    package { [ 'php5', 'php5-cli', 'php5-mysql', 'python-sqlalchemy']:
        ensure => latest;
    }
}

## imminent decomission/reclaim from pmtpa pending 12th floor reorg
node /^db(6[012456]|7[5-7])\.pmtpa\.wmnet/{
    include standard
}

# eqiad dbs
node /^db10(33|37|43|49|50|51|52|55|56)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(56)/ {
        $ganglia_aggregator = true
        include mha::manager
    }

    if $::hostname =~ /^db10(33|37|49|50|51|52|55|56)/ {
        class { role::coredb::s1 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname =~ /^db10(43)/ {
        class { role::coredb::s1 : mariadb => true }
    } else {
        include role::coredb::s1
    }
}

node /^db10(02|09|18|34|36|60)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(02|18|34|36|60)/ {
        class { role::coredb::s2 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname == "db1009" {
        class { role::coredb::s2 : mariadb => true }
    } else {
        include role::coredb::s2
    }
}

node /^db10(03|10|19|35|38)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(03|19|35|38)/ {
        class { role::coredb::s3 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname == "db1010" {
        class { role::coredb::s3 : mariadb => true }
    } else {
        include role::coredb::s3
    }
}

node /^db10(04|11|20|40|42|59)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(04|11|20|40|42|59)/ {
        class { role::coredb::s4 : mariadb => true }
    } else {
        include role::coredb::s4
    }
}

node /^db10(05|21|26|45|58)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db1021/ {
        $ganglia_aggregator = true
    }
    if $::hostname =~ /^db10(45)/ {
        class { role::coredb::s5 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname =~ /^db10(05|21|26|58)/ {
        class { role::coredb::s5 : mariadb => true }
    } else {
        include role::coredb::s5
    }
}

node /^db10(06|15|22|23|27)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(06|22|23)/ {
        class { role::coredb::s6 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname =~ /^db10(15|27)/ {
        class { role::coredb::s6 : mariadb => true }
    } else {
        include role::coredb::s6
    }
}

node /^db10(07|24|28|39|41)\.eqiad\.wmnet/ {
    if $::hostname =~ /^db10(07|24|39|41)/ {
        class { role::coredb::s7 : innodb_file_per_table => true, mariadb => true }
    } elsif $::hostname == "db1028" {
        class { role::coredb::s7 : mariadb => true }
    } else {
        include role::coredb::s7
    }
}

## x1 shard
node /^db10(29|30|31)\.eqiad\.wmnet/ {
    include role::coredb::x1
}

## m1 shard
node /^db10(01|16)\.eqiad\.wmnet/ {
    class { role::coredb::m1 : mariadb => true }
}

## m2 shard
node /^db104[68]\.eqiad\.wmnet/ {
    if $::hostname =~ /^db1046/ {
        class { role::coredb::m2 : mariadb => true }
    } else {
        include role::coredb::m2
    }
}

## researchdb s1
node 'db1047.eqiad.wmnet' {
    class { role::coredb::researchdb :
        mariadb => true,
        innodb_file_per_table => true,
    }
}

## researchdb s5
node 'db1017.eqiad.wmnet' {
    class { role::coredb::researchdb :
        shard => "s5",
        mariadb => true,
        innodb_file_per_table => true,
        innodb_log_file_size => "1000M"
    }
}

## SANITARIUM
node 'db1053.eqiad.wmnet' {
    class { role::db::sanitarium:
        instances => {
            's1' => {
                'port' => 3306,
                'innodb_log_file_size' => "2000M",
                'ram' => "72G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
        }
    }
}

node 'db1054.eqiad.wmnet' {
    class { role::db::sanitarium:
        instances => {
            's2' => {
                'port' => 3306,
                'innodb_log_file_size' => "2000M",
                'ram' => "24G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
            's4' => {
                'port' => 3307,
                'innodb_log_file_size' => "2000M",
                'ram' => "24G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
            's5' => {
                'port' => 3308,
                'innodb_log_file_size' => "1000M",
                'ram' => "24G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
        }
    }
}

node 'db1057.eqiad.wmnet' {
    class { role::db::sanitarium:
        instances => {
            's3' => {
                'port' => 3306,
                'innodb_log_file_size' => "500M",
                'ram' => "24G",
                'repl_ignore_dbs' => $::private_wikis,
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
            's6' => {
                'port' => 3307,
                'innodb_log_file_size' => "500M",
                'ram' => "24G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
            's7' => {
                'port' => 3308,
                'innodb_log_file_size' => "500M",
                'ram' => "24G",
                'repl_wild_ignore_tables' => $::private_tables,
                'log_bin' => true,
                'binlog_format' => "row",
            },
        }
    }
}

node "db1014.eqiad.wmnet" {
    $cluster = "misc"
    include standard,
        udpprofile::collector
}

# ad-hoc mariadb test box
node "db1044.eqiad.wmnet" {
    $cluster = "misc"
    include standard,
        mysql_wmf,
        mysql_wmf::datadirs,
        mysql_wmf::mysqluser
}

node "dobson.wikimedia.org" {
    interface::ip { "dns::recursor": interface => "eth0", address => "208.80.152.131" }

    include base,
        ganglia,
        exim::simple-mail-sender,
        dns::recursor::statistics

    include network::constants

    class { 'ntp::server':
        servers => [ "173.9.142.98", "66.250.45.2", "169.229.70.201", "69.31.13.207", "72.167.54.201" ],
        peers => [ "linne.wikimedia.org" ],
    }

    class { "dns::recursor":
        listen_addresses => [ "208.80.152.131" ],
        allow_from => $network::constants::all_networks
    }
    dns::recursor::monitor { "208.80.152.131": }
}

node "dysprosium.eqiad.wmnet" {
    interface::add_ip6_mapped { "main": interface => "eth0" }

    include standard
}

node 'eeden.esams.wikimedia.org' {
    interface::add_ip6_mapped { "main": interface => "eth0" }
    include role::authdns::ns2
}

node "ekrem.wikimedia.org" {
    include standard,
            role::ircd
}

# base_analytics_logging_node is defined in role/logging.pp
node "emery.wikimedia.org" inherits "base_analytics_logging_node" {
    include
        generic::higher_min_free_kbytes,
        admins::mortals,
        accounts::milimetric, # RT 4312
        accounts::tnegrin     # RT 5391

    include role::logging::udp2log::emery
}

node /(ersch|tarin)\.pmtpa\.wmnet/ {
    $ganglia_aggregator = true
    include standard,
        role::poolcounter
}

node "aluminium.wikimedia.org" {
    include role::fundraising::civicrm,
        accounts::file_mover
    class { 'misc::fundraising::backup::archive_sync': hour => [0,8,16], minute => 5 }
    interface::ip { "fundraising.wikimedia.org": interface => "eth0", address => "208.80.154.12" }
}

# erbium is a webrequest udp2log host
node "erbium.eqiad.wmnet" inherits "base_analytics_logging_node" {
    # gadolinium hosts the separate nginx webrequest udp2log instance.
    include role::logging::udp2log::erbium

    include accounts::tnegrin       # RT 5391
}

# es1 equad
node /es100[1-4]\.eqiad\.wmnet/ {
    class { role::coredb::es1 : mariadb => true }
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
node /^es([123569]|10)\.pmtpa\.wmnet/{
    include standard
}

node /es100[5-7]\.eqiad\.wmnet/ {
    if $::hostname =~ /^es100[67]/ {
        class { role::coredb::es2 : mariadb => true }
    } else {
        include role::coredb::es2
    }
}

node /es10(0[89]|10)\.eqiad\.wmnet/ {
    if $::hostname =~ /^es10(09|10)/ {
        class { role::coredb::es3 : mariadb => true }
    } else {
        include role::coredb::es3
    }
}

node "fenari.wikimedia.org" {
    system::role { "misc": description => "Bastion & NOC Server" }
    $cluster = "misc"
    $domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

    include role::applicationserver::maintenance,
        svn::client,
        nfs::netapp::home,
        admins::roots,
        admins::mortals,
        admins::restricted,
        bastionhost,
        misc::noc-wikimedia,
        nrpe,
        drac,
        accounts::awjrichards,
        accounts::erosen,
        generic::wikidev-umask,
        misc::dsh,
        ssh::hostkeys-collect
    install_certificate{ "noc.wikimedia.org": }
}

node "fluorine.eqiad.wmnet" {
    $cluster = "misc"

    include standard,
        admins::roots,
        admins::mortals,
        admins::restricted,
        nrpe

    class { "role::logging::mediawiki":
        monitor => false,
        log_directory => "/a/mw-log"
    }

}

node "formey.wikimedia.org" {
    install_certificate{ "star.wikimedia.org": }

    $sudo_privs = [ 'ALL = NOPASSWD: /usr/local/sbin/add-ldap-user',
            'ALL = NOPASSWD: /usr/local/sbin/delete-ldap-user',
            'ALL = NOPASSWD: /usr/local/sbin/modify-ldap-user',
            'ALL = NOPASSWD: /usr/local/bin/svn-group',
            'ALL = NOPASSWD: /usr/local/sbin/add-labs-user',
            'ALL = NOPASSWD: /var/lib/gerrit2/review_site/bin/gerrit.sh' ]
    sudo_user { [ "robla", "sumanah", "reedy" ]: privileges => $sudo_privs }

    # full root for gerrit admin (RT-3698)
    sudo_user { "demon": privileges => ['ALL = NOPASSWD: ALL'] }

    $gid = 550
    $ldapincludes = ['openldap', 'nss', 'utils']
    $ssh_tcp_forwarding = "no"
    $ssh_x11_forwarding = "no"
    include standard,
        webserver::php5,
        svn::server,
        backup::client,
        role::deployment::test

    class { "ldap::role::client::labs": ldapincludes => $ldapincludes }
}

# gadolinium is the webrequest socat multicast relay.
# base_analytics_logging_node is defined in role/logging.pp
node "gadolinium.wikimedia.org" inherits "base_analytics_logging_node" {
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

node "gallium.wikimedia.org" {
    $cluster = "misc"
    $gid=500
    sudo_user { [ "demon", "krinkle", "reedy", "dsc", "mholmquist" ]: privileges => [
         'ALL = (jenkins) NOPASSWD: ALL'
        ,'ALL = (jenkins-slave) NOPASSWD: ALL'
        ,'ALL = (gerritslave) NOPASSWD: ALL'
        ,'ALL = NOPASSWD: /etc/init.d/jenkins'
        ,'ALL = (testswarm) NOPASSWD: ALL'
        ,'ALL = NOPASSWD: /etc/init.d/postgresql-8.4'
        ,'ALL = (postgres) NOPASSWD: /usr/bin/psql'
    ]}

    # full root for Jenkins admin (RT-4101)
    sudo_user { "hashar": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard,
        nrpe,
        contint::firewall,
        contint::android-sdk,
        role::ci::master,
        role::ci::slave,
        role::ci::testswarm,
        role::ci::website,
        role::zuul::production,
        admins::roots,
        admins::jenkins

    # gallium received a SSD drive (RT #4916) mount it
    file { '/srv/ssd':
        owner => root,
        group => root,
        ensure => directory,
    }
    mount { '/srv/ssd':
        ensure => mounted,
        device => '/dev/sdb1',
        fstype => 'xfs',
        options => 'noatime,nodiratime,nobarrier,logbufs=8',
        require => File['/srv/ssd'],
    }

    install_certificate{ "star.mediawiki.org": }
    install_certificate{ "star.wikimedia.org": }
}

node "harmon.pmtpa.wmnet" {
    $cluster = "misc"

    include standard,
        admins::roots
}

node "helium.eqiad.wmnet" {
    include standard,
        role::poolcounter,
        role::backup::director,
        role::backup::storage
}

node "holmium.wikimedia.org" {
    include standard,
        admins::roots,
        misc::blogs::wikimedia
}

node "hooft.esams.wikimedia.org" {
    $ganglia_aggregator = true
    $domain_search = "esams.wikimedia.org wikimedia.org esams.wmnet"

    include standard,
        role::installserver::tftp-server,
        admins::roots,
        admins::mortals,
        admins::restricted

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

    class { "ganglia_new::monitor::aggregator": sites => ["esams"] }
}

# base_analytics_logging_node is defined in role/logging.pp

node "locke.wikimedia.org" inherits "base_analytics_logging_node" {
    include
        accounts::dsc,
        accounts::tstarling,
        accounts::datasets,
        accounts::milimetric,
        accounts::tnegrin,       # RT 5391
        misc::udp2log::utilities,
        misc::udp2log

    sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }

    # fundraising banner log pipeline (moved to gadolinium)
    #include misc::fundraising::udp2log_rotation
}

node "manutius.wikimedia.org" {
    $corerouters = [
        "cr1-sdtpa.wikimedia.org",
        "cr2-pmtpa.wikimedia.org",
        "csw1-sdtpa.wikimedia.org",
        "cr1-esams.wikimedia.org",
        "cr2-knams.wikimedia.org",
        "csw2-esams.wikimedia.org",
        "cr1-eqiad.wikimedia.org",
        "cr2-eqiad.wikimedia.org",
        "cr1-ulsfo.wikimedia.org",
        "cr2-ulsfo.wikimedia.org",
        "mr1-pmtpa.mgmt.pmtpa.wmnet",
        "pfw1-eqiad.wikimedia.org"
    ]

    $accessswitches = [
        "asw-a4-sdtpa.mgmt.pmtpa.wmnet",
        "asw-a5-sdtpa.mgmt.pmtpa.wmnet",
        "asw-b-sdtpa.mgmt.pmtpa.wmnet",
        "asw-d-pmtpa.mgmt.pmtpa.wmnet",
        "asw-d1-sdtpa.mgmt.pmtpa.wmnet",
        "asw-d2-sdtpa.mgmt.pmtpa.wmnet",
        "asw-d3-sdtpa.mgmt.pmtpa.wmnet",
        "asw2-d3-sdtpa.mgmt.pmtpa.wmnet",
        "asw-a-eqiad.mgmt.eqiad.wmnet",
        "asw-b-eqiad.mgmt.eqiad.wmnet",
        "asw-c-eqiad.mgmt.eqiad.wmnet",
        "asw2-a5-eqiad.mgmt.eqiad.wmnet",
        "psw1-eqiad.mgmt.eqiad.wmnet",
        "msw1-eqiad.mgmt.eqiad.wmnet",
        "msw2-pmtpa.mgmt.pmtpa.wmnet",
        "msw2-sdtpa.mgmt.pmtpa.wmnet"
    ]

    $storagehosts = [ "nas1-a.pmtpa.wmnet", "nas1-b.pmtpa.wmnet", "nas1001-a.eqiad.wmnet", "nas1001-b.eqiad.wmnet" ]

    include standard,
        webserver::apache,
        misc::torrus,
        misc::torrus::web,
        misc::torrus::xml-generation::cdn,
        ganglia::collector

    include passwords::network
    $snmp_ro_community = $passwords::network::snmp_ro_community

    misc::torrus::discovery::ddxfile {
        "corerouters":
            subtree => "/Core_routers",
            snmp_community => $snmp_ro_community,
            hosts => $corerouters;
        "accessswitches":
            subtree => "/Access_switches",
            snmp_community => $snmp_ro_community,
            hosts => $accessswitches;
        "storage":
            subtree => "/Storage",
            snmp_community => $snmp_ro_community,
            hosts => $storagehosts
    }

    class { "ganglia_new::monitor::aggregator": sites => ["pmtpa", "eqiad"] }
}

node "hooper.wikimedia.org" {
    $ganglia_aggregator = true

    include standard,
        admins::roots,
        svn::client

    install_certificate{ "star.wikimedia.org": }
}

node "hume.wikimedia.org" {
    $cluster = "misc"

    include role::applicationserver::maintenance,
        mysql,
        nfs::netapp::home,
        nfs::upload,
        misc::deployment::scap_scripts,
        misc::monitoring::jobqueue,
        admins::roots,
        admins::mortals,
        admins::restricted,
        nrpe

    class { misc::maintenance::updatequerypages: enabled => false }
    class { misc::maintenance::geodata: enabled => false }
    class { misc::maintenance::update_flaggedrev_stats: enabled => false }
    class { misc::maintenance::refreshlinks: enabled => false }
    class { misc::maintenance::update_special_pages: enabled => false }
}

node "iron.wikimedia.org" {
    system::role { "misc": description => "Operations Bastion" }
    $cluster = "misc"
    $domain_search = "wikimedia.org eqiad.wmnet pmtpa.wmnet ulsfo.wmnet esams.wikimedia.org"

    include standard,
    admins::roots,
    misc::management::ipmi

    # search QA scripts for ops use
    include search::searchqa
}

node "kaulen.wikimedia.org" {
    system::role { "misc": description => "Bugzilla server" }
    $gid = 500

    include standard,
            role::bugzilla::old,
            admins::roots

}

## labsdb dbs
node 'labsdb1001.eqiad.wmnet' {
    class { role::db::labsdb:
        instances => {
            's1' => {
                'port' => 3306,
                'innodb_log_file_size' => "2000M",
                'ram' => "120G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
        }
    }
}

node 'labsdb1002.eqiad.wmnet' {
    class { role::db::labsdb:
        instances => {
            's2' => {
                'port' => 3306,
                'innodb_log_file_size' => "2000M",
                # kernel oom killer striking mysqld. reduce footprint during investigation
                'ram' => "32G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
            's4' => {
                'port' => 3307,
                'innodb_log_file_size' => "2000M",
                # kernel oom killer striking mysqld. reduce footprint during investigation
                'ram' => "32G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
            's5' => {
                'port' => 3308,
                'innodb_log_file_size' => "1000M",
                # kernel oom killer striking mysqld. reduce footprint during investigation
                'ram' => "32G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
        }
    }
}

node 'labsdb1003.eqiad.wmnet' {
    class { role::db::labsdb:
        instances => {
            's3' => {
                'port' => 3306,
                'innodb_log_file_size' => "500M",
                'ram' => "48G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
            's6' => {
                'port' => 3307,
                'innodb_log_file_size' => "500M",
                'ram' => "48G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
            's7' => {
                'port' => 3308,
                'innodb_log_file_size' => "500M",
                'ram' => "48G",
                'innodb_locks_unsafe_for_binlog' => true,
                'repl_ignore_dbs' => 'mysql',
                'slave_transaction_retries' => 100000,
                'read_only' => 0,
                'max_user_connections' => 512,
            },
        }
    }
}

node /labstore[12]\.pmtpa\.wmnet/ {

    $cluster = "gluster"
    $ldapincludes = ['openldap', 'nss', 'utils']

    $ganglia_aggregator = true

    include standard,
        openstack::project-storage

    class { "ldap::role::client::labs": ldapincludes => $ldapincludes }

    if $::hostname =~ /^labstore2$/ {
        include openstack::project-storage-service
    }

}

node /labstore[34]\.pmtpa\.wmnet/ {

    $cluster = "labsnfs"
    $ldapincludes = ['openldap', 'nss', 'utils']

    $ganglia_aggregator = true

    include standard,
        openstack::project-nfs-storage-service,
        rsync::server

    rsync::server::module {
        'pagecounts':
            path        => '/exp/pagecounts',
            read_only   => 'false',
            hosts_allow => ['208.80.154.11', '208.80.152.185'];
    }

    class { "ldap::role::client::labs": ldapincludes => $ldapincludes }
}

node 'lanthanum.eqiad.wmnet' {
    include standard,
        admins::roots,
        admins::jenkins,
        role::ci::slave  # RT #5074

    # Used as a Jenkins slave so some folks need escalated privileges
    $gid=500
    sudo_user { [ 'demon', 'krinkle', 'reedy', 'dsc', 'mholmquist' ]: privileges => [
        'ALL = (jenkins-slave) NOPASSWD: ALL',
        'ALL = (gerritslave) NOPASSWD: ALL',
        ]
    }

    # full root for Jenkins admin (RT-5677)
    sudo_user { "hashar": privileges => ['ALL = NOPASSWD: ALL'] }

    # lanthanum received a SSD drive just like gallium (RT #5178) mount it
    file { '/srv/ssd':
        owner => root,
        group => root,
        ensure => directory,
    }
    mount { '/srv/ssd':
        ensure => mounted,
        device => '/dev/sdb1',
        fstype => 'xfs',
        options => 'noatime,nodiratime,nobarrier,logbufs=8',
        require => File['/srv/ssd'],
    }

}

node "linne.wikimedia.org" {
    interface::ip { "misc::url-downloader": interface => "eth0", address => "208.80.152.143" }

    include base,
        ganglia,
        exim::simple-mail-sender,
        misc::url-downloader

    class { 'ntp::server':
        servers => [ "198.186.191.229", "64.113.32.2", "173.8.198.242", "208.75.88.4", "75.144.70.35" ],
        peers => [ "dobson.wikimedia.org" ],
    }
}

node /lvs[1-6]\.wikimedia\.org/ {
    if $::hostname =~ /^lvs[12]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    $ips = {
        'internal' => {
            'lvs1' => "10.0.0.11",
            'lvs2' => "10.0.0.12",
            'lvs3' => "10.0.0.13",
            'lvs4' => "10.0.0.14",
            'lvs5' => "10.0.0.15",
            'lvs6' => "10.0.0.16",
        },
    }

    interface::add_ip6_mapped { "main": interface => "eth0" }

    # Set up tagged interfaces to all subnets with real servers in them
    interface::tagged { "eth0.2":
        base_interface => "eth0",
        vlan_id => "2",
        address => $ips["internal"][$::hostname],
        netmask => "255.255.0.0"
    }

    # Make sure GRO is off
    interface::offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
}

node /lvs100[1-6]\.wikimedia\.org/ {
    if $::hostname =~ /^lvs100[12]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    interface::add_ip6_mapped { "main": interface => "eth0" }

    include lvs::configuration
    $ips = $lvs::configuration::subnet_ips

    # Set up tagged interfaces to all subnets with real servers in them
    case $::hostname {
        /^lvs100[1-3]$/: {
            # Row A subnets on eth0
            interface::tagged { "eth0.1017":
                base_interface => "eth0",
                vlan_id => "1017",
                address => $ips["private1-a-eqiad"][$::hostname],
                netmask => "255.255.252.0"
            }
            # Row B subnets on eth1
            interface::tagged { "eth1.1002":
                base_interface => "eth1",
                vlan_id => "1002",
                address => $ips["public1-b-eqiad"][$::hostname],
                netmask => "255.255.255.192"
            }
            interface::tagged { "eth1.1018":
                base_interface => "eth1",
                vlan_id => "1018",
                address => $ips["private1-b-eqiad"][$::hostname],
                netmask => "255.255.252.0"
            }
        }
        /^lvs100[4-6]$/: {
            # Row B subnets on eth0
            interface::tagged { "eth0.1018":
                base_interface => "eth0",
                vlan_id => "1018",
                address => $ips["private1-b-eqiad"][$::hostname],
                netmask => "255.255.252.0"
            }
            # Row A subnets on eth1
            interface::tagged { "eth1.1001":
                base_interface => "eth1",
                vlan_id => "1001",
                address => $ips["public1-a-eqiad"][$::hostname],
                netmask => "255.255.255.192"
            }
            interface::tagged { "eth1.1017":
                base_interface => "eth1",
                vlan_id => "1017",
                address => $ips["private1-a-eqiad"][$::hostname],
                netmask => "255.255.252.0"
            }
        }
    }
    # Row C subnets on eth2
    interface::tagged {
        "eth2.1003":
            base_interface => "eth2",
            vlan_id => "1003",
            address => $ips["public1-c-eqiad"][$::hostname],
            netmask => "255.255.255.192";
        "eth2.1019":
            base_interface => "eth2",
            vlan_id => "1019",
            address => $ips["private1-c-eqiad"][$::hostname],
            netmask => "255.255.252.0";
    }
    # Row D subnets on eth3

    # Make sure GRO is off
    interface::manual { "eth1": interface => "eth1", before => Interface::Offload["eth1 gro"] }
    interface::manual { "eth2": interface => "eth2", before => Interface::Offload["eth2 gro"] }
    interface::manual { "eth3": interface => "eth3", before => Interface::Offload["eth3 gro"] }

    interface::offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
    interface::offload { "eth1 gro": interface => "eth1", setting => "gro", value => "off" }
    interface::offload { "eth2 gro": interface => "eth2", setting => "gro", value => "off" }
    interface::offload { "eth3 gro": interface => "eth3", setting => "gro", value => "off" }
}


# ULSFO lvs servers
node /^lvs400[1-4]\.ulsfo\.wmnet$/ {
    # lvs4001 and lvs4003 are in different racks
    if $::hostname =~ /^lvs400[13]$/ {
        $ganglia_aggregator = true
    }

    include role::lvs::balancer

    interface::add_ip6_mapped { "main": interface => "eth0" }

    # Make sure GRO is off
    interface::offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }

    # bnx2x is buggy with TPA (LRO) + LVS
    interface::offload { "eth0 lro": interface => "eth0", setting => "lro", value => "off" }
}

node "maerlant.esams.wikimedia.org" {
    include standard
}

node "magnesium.wikimedia.org" {

    $cluster = "misc"

    include role::racktables
    include role::request-tracker-apache::production, exim::rt
}

node /^mc(10[01][0-9])\.eqiad\.wmnet/ {
    $cluster = "memcached"
    if $::hostname =~ /^mc100[12]$/ {
        $ganglia_aggregator = true
    }

    include role::memcached,
        passwords::redis

    file { "/a":
        ensure => directory;
    }

    class { "redis":
        maxmemory         => "500Mb",
        password          => $passwords::redis::main_password,
    }
    include redis::ganglia
}

node /^rdb100[1-4]\.eqiad\.wmnet/ {
    $ganglia_aggregator = true

    $redis_replication = {
        'rdb1002' => 'rdb1001',
        'rdb1004' => 'rdb1003',
    }

    class { role::db::redis : redis_replication => $redis_replication }
}

node 'rubidium.wikimedia.org' {
    interface::add_ip6_mapped { "main": interface => "eth0" }
    include role::authdns::ns0
}

node "mchenry.wikimedia.org" {
    $gid = 500

    interface::ip { "dns::recursor": interface => "eth0", address => "208.80.152.132" }

    include base,
        ganglia,
        ntp::client,
        dns::recursor::statistics,
        nrpe,
        ldap::role::client::corp,
        backup::client,
        privateexim::aliases::private,
        groups::wikidev,
        accounts::jdavis

    include network::constants

    class { "dns::recursor":
        listen_addresses => ["208.80.152.132"],
        allow_from => $network::constants::all_networks
    }

    dns::recursor::monitor { "208.80.152.132": }

    # mails the wikimedia.org mail alias file to OIT once per week
    class { misc::maintenance::mail_exim_aliases: enabled => true }

    # TODO: This unfortunately will not work while mchenry is still hardy
    include backup::host
    backup::set { 'roothome': }
}

node 'mexia.wikimedia.org' {
    interface::add_ip6_mapped { "main": interface => "eth0" }
    include role::authdns::ns1
}

node /mobile100[1-4]\.wikimedia\.org/ {
    include standard-noexim
}

node "ms5.pmtpa.wmnet" {
    include standard
}

node "ms6.esams.wikimedia.org" {
    interface::aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1", "eth2", "eth3" ] }

    include standard
}

node /^ms(10|1001)\.wikimedia\.org$/ {
    include standard,
        role::mirror::media
}

node "ms1002.eqiad.wmnet" {
    include standard
}

node /ms100[4]\.eqiad\.wmnet/ {
    $cluster = "misc"
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

    class { "lvs::realserver": realserver_ips => [ "10.2.1.27" ] }

    include role::swift::pmtpa-prod::proxy
}

node /^ms-be(3|[6-8]|10)\.pmtpa\.wmnet$/ {
    # the ms-be hosts that are 720xds with ssds have two more disks
    # but with the h310s they show up as m and n, those get the OS
    $all_drives = [ '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
        '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj',
        '/dev/sdk', '/dev/sdl' ]

    include role::swift::pmtpa-prod::storage

    swift::create_filesystem{ $all_drives: partition_nr => "1" }
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

    swift::create_filesystem{ $all_drives: partition_nr => "1" }
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
    $cluster = "ceph"

    if $::hostname =~ /^ms-be300[12]$/ {
        $ganglia_aggregator = true
    }

    include standard
}

# mw1-16 are application servers for jobrunners only (precise)
node /^mw([1-9]|1[0-6])\.pmtpa\.wmnet$/ {
    if $::hostname =~ /^mw[12]$/ {
        $ganglia_aggregator = true
    }

    class { role::applicationserver::jobrunner: run_jobs_enabled => false }
}

# mw17-59 are application servers (precise)
node /^mw(1[7-9]|[2-5][0-9])\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver
    include nfs::upload
}

# mw60-61 are bits application servers (precise)
node /^mw6[01]\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver::bits
}

# mw62-74 are api application servers (precise)
node /^mw(6[2-9]|7[0-4])\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver::api
    include nfs::upload
}

# mw75-80 are imagescalers (precise)
node /^mw(7[5-9]|80)\.pmtpa\.wmnet$/ {
    if $::hostname =~ /^mw7[56]$/ {
        $ganglia_aggregator = true
    }

    include role::applicationserver::imagescaler
}

# mw81-111 are application servers (precise)
node /^mw(8[1-9]|9[0-9]|10[0-9]|111)\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver
    include nfs::upload
}

# mw112-125 are api application servers (precise)
node /^mw(11[2-9]|12[0-5])\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver::api
    include nfs::upload
}

# mw1001-1016 are jobrunners (precise)
node /^mw10(0[1-9]|1[0-6])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw100[12]$/ {
        $ganglia_aggregator = true
    }

    class { role::applicationserver::jobrunner: run_jobs_enabled => true }
}

# mw1017-1113 are apaches (precise)
node /^mw1(01[7-9]|0[2-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet$/ {
    if $::hostname =~ /^mw101[78]$/ {
        $ganglia_aggregator = true
    }

    # mw1017 is test.wikipedia.org (precise)
    if $::hostname == "mw1017" {
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

    include role::applicationserver::appserver
}

# mw1189-1208 are api apaches (precise)
node /^mw1(189|19[0-9]|20[0-8])\.eqiad\.wmnet$/ {

    include role::applicationserver::appserver::api
}

# mw1209-1220 are apaches (precise)
node /^mw12(09|1[0-9]|20)\.eqiad\.wmnet$/ {

    include role::applicationserver::appserver
}

node "neon.wikimedia.org" {
    $domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

    $ircecho_logs = { "/var/log/icinga/irc.log" => "#wikimedia-operations" }
    $ircecho_nick = "icinga-wm"
    $ircecho_server = "chat.freenode.net"
    include standard,
        icinga::monitor,
        role::ishmael,
        role::echoirc,
        tcpircbot,
        passwords::logmsgbot

    tcpircbot::instance { 'logmsgbot':
        channels => ['#wikimedia-operations', '#wikimedia-dev'],
        password => $passwords::logmsgbot::logmsgbot_password,
        cidr     => [
            '::ffff:10.64.21.123/128',    # vanadium
            '::ffff:10.64.0.196/128',     # tin
            '::ffff:208.80.152.165/128',  # fenari
            '::ffff:127.0.0.1/128',       # loopback
        ],
    }
}

node "nescio.esams.wikimedia.org" {
    interface::ip { "dns::recursor": interface => "eth0", address => "91.198.174.6" }

    include standard,
        dns::recursor::statistics

    include network::constants

    class { "dns::recursor":
        listen_addresses => [ "91.198.174.6" ],
        allow_from => $network::constants::all_networks
    }

    dns::recursor::monitor { "91.198.174.6": }

}

node 'netmon1001.wikimedia.org' {
    include standard,
        webserver::apache,
        misc::rancid,
        smokeping,
        smokeping::web,
        role::librenms

    interface::add_ip6_mapped { "main": }
}

node /^nfs[12].pmtpa.wmnet/ {

    $server_bind_ips = "127.0.0.1 $ipaddress_eth0"
    $cluster = "misc"

    include standard,
        misc::nfs-server::home::rsyncd,
        misc::syslog-server,
        backup::client

    include backup::host
    backup::set { 'var-opendj-backups': }

    # don't need udp2log monitoring on nfs hosts
    class { "role::logging::mediawiki":
        monitor => false,
        log_directory => "/home/wikipedia/logs"
    }

}

node "nickel.wikimedia.org" {
    $ganglia_aggregator = true

    include standard,
        ganglia::web,
        misc::monitoring::views

     install_certificate{ "ganglia.wikimedia.org": }
}

node /^osm-cp100[1-4]\.wikimedia\.org$/ {
    include standard-noexim
}

# base_analytics_logging_node is defined in role/logging.pp
node "oxygen.wikimedia.org" inherits "base_analytics_logging_node" {
    include
        accounts::awjrichards,
        accounts::datasets,
        accounts::dsc,
        accounts::diederik,
        accounts::manybubbles, #RT 4312
        accounts::milimetric,  #RT 4312
        accounts::tnegrin     # RT 5391

    # main oxygen udp2log handles mostly Wikipedia Zero webrequest logs
        include role::logging::udp2log::oxygen
    # Also include lucene search loggging udp2log instance
        include role::logging::udp2log::lucene
}

node 'palladium.eqiad.wmnet' {
    include passwords::puppet::database

    include standard,
        backup::client,
        misc::management::ipmi,
        role::salt::masters::production,
        role::deployment::salt_masters::production

    class { puppetmaster:
        allow_from => [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
         ],
        server_type => 'frontend',
        workers => ['palladium.eqiad.wmnet', 'strontium.eqiad.wmnet'],
        config => {
            'thin_storeconfigs' => true,
            'dbadapter' => 'mysql',
            'dbuser' => 'puppet',
            'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver' => 'db1001.eqiad.wmnet',
        }
    }
}

node /pc([1-3]\.pmtpa|100[1-3]\.eqiad)\.wmnet/ {

    include role::db::core,
        mysql_wmf::mysqluser,
        mysql_wmf::datadirs,
        mysql_wmf::pc::conf

    if $::hostname =~ /^pc100(1|2|3)/ {
        class { mysql_wmf::packages : mariadb => true }
    } else {
        include mysql_wmf::packages
    }

    system::role { "mysql::pc::conf": description => "parser cache mysql server" }
}

node "pdf1.wikimedia.org" {
    $ganglia_aggregator = true
    $cluster = "pdf"

    include role::pdf,
        groups::wikidev,
        accounts::file_mover,
        accounts::mwalker     #rt 6468
}

node "pdf2.wikimedia.org" {
    $ganglia_aggregator = true
    $cluster = "pdf"

    include role::pdf,
        groups::wikidev,
        accounts::file_mover,
        accounts::mwalker     #rt 6468
}

node "pdf3.wikimedia.org" {
    $cluster = "pdf"

    include role::pdf,
        groups::wikidev,
        accounts::file_mover,
        accounts::mwalker     #rt 6468
}

node "professor.pmtpa.wmnet" {
    $cluster = "misc"
    include base,
        ganglia,
        ntp::client,
        udpprofile::collector
}

node "potassium.eqiad.wmnet" {
    include standard,
        role::poolcounter
}

node "rhodium.eqiad.wmnet" {
    $gid = 500
    include role::ocg::test,
        groups::wikidev,
        admins::roots,
        accounts::mwalker,
        accounts::cscott,
        accounts::maxsem,
        accounts::anomie
}

node "sanger.wikimedia.org" {
    $gid = 500

    include base,
        ganglia,
        ntp::client,
        nrpe,
        ldap::role::server::corp,
        ldap::role::client::corp,
        groups::wikidev,
        accounts::jdavis,
        backup::client

    ## hardy doesn't support augeas, so we can't do this. /stab
    #include ldap::server::iptables
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

node "searchidx2.pmtpa.wmnet" {

    include role::lucene::indexer
}

node "silver.wikimedia.org" {
    include standard,
        groups::wikidev,
        mobile::vumi,
        mobile::vumi::udp2log
}

node "sockpuppet.pmtpa.wmnet" {
    include standard,
        backup::client,
        misc::management::ipmi,
        role::salt::masters::production,
        role::deployment::salt_masters::production

    # Display notice that this is no longer an active puppetmaster.
    file {"/etc/update-motd.d/99-obsolete-puppetmaster":
        ensure => 'present',
        source => 'puppet:///modules/puppetmaster/motd/99-obsolete';
    }
}

node "sodium.wikimedia.org" {

    $nameservers_prefix = [ $ipaddress ]

    include base,
        ganglia,
        ntp::client,
        nrpe,
        mailman,
        dns::recursor,
        backup::client

    interface::add_ip6_mapped { "main": interface => "eth0" }

    class { 'spamassassin':
        required_score => '4.0',
        use_bayes => '0',
        bayes_auto_learn => '0',
    }

    class { exim::roled:
        outbound_ips => [ "208.80.154.61", "2620:0:861:1:208:80:154:61" ],
        list_outbound_ips => [ "208.80.154.4", "2620:0:861:1::2" ],
        local_domains => [ "+system_domains", "+mailman_domains" ],
        enable_mail_relay => "secondary",
        enable_mailman => "true",
        enable_mail_submission => "false",
        enable_spamassassin => "true"
    }

    interface::ip {
        "lists.wikimedia.org_v4": interface => "eth0", address => "208.80.154.4", prefixlen => 32;
        "lists.wikimedia.org_v6": interface => "eth0", address => "2620:0:861:1::2", prefixlen => 128;
    }
}

# srv193 was test.wikipedia.org (precise)
# on 20130711 test has been switched over to mw1017
node "srv193.pmtpa.wmnet" {
    include role::applicationserver::appserver::test
    include nfs::upload
    include nfs::netapp::home,
        memcached
}

# srv235-247 are application servers (precise)
node /^srv(23[5-9]|24[0-7])\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver
    include nfs::upload
}

# srv248-249 are bits application servers (precise)
node /^srv24[89]\.pmtpa\.wmnet$/ {
    $ganglia_aggregator = true
    include role::applicationserver::appserver::bits
}

# srv250-257 are API application servers (precise)
node /^srv25[0-7]\.pmtpa\.wmnet$/ {
    if $::hostname =~ /^srv25[45]$/ {
        $ganglia_aggregator = true
    }
    include role::applicationserver::appserver::api
    include nfs::upload
}

# srv258-289 are applicationservers (precise)
node /^srv(25[89]|2[6-8][0-9])\.pmtpa\.wmnet$/ {
    if $::hostname =~ /^srv25[89]$/ {
        $ganglia_aggregator = true
    }

    include role::applicationserver::appserver
    include nfs::upload
}

# srv290-301 are API application servers (precise)
node /^srv(29[0-9]|30[01])\.pmtpa\.wmnet$/ {
    include role::applicationserver::appserver::api
    include nfs::upload
}

node /ssl100[1-9]\.wikimedia\.org/ {
    if $::hostname =~ /^ssl100[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": interface => "eth0" }

    include role::protoproxy::ssl
}

node /ssl300[1-4]\.esams\.wikimedia\.org/ {
    if $::hostname =~ /^ssl300[12]$/ {
        $ganglia_aggregator = true
    }

    interface::add_ip6_mapped { "main": interface => "eth0" }

    include role::protoproxy::ssl
}

node "stafford.pmtpa.wmnet" {
    include standard

    # Display notice that this is no longer an active puppetmaster.
    file {"/etc/update-motd.d/99-obsolete-puppetmaster":
        ensure => 'present',
        source => 'puppet:///modules/puppetmaster/motd/99-obsolete';
    }
}

node 'strontium.eqiad.wmnet' {
    include standard,
        passwords::puppet::database

    class { puppetmaster:
        allow_from => [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
         ],
        server_type => 'backend',
        config => {
            'thin_storeconfigs' => true,
            'ca' => 'false',
            'ca_server' => 'palladium.eqiad.wmnet',
            'dbadapter' => 'mysql',
            'dbuser' => 'puppet',
            'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver' => 'db1001.eqiad.wmnet',
            'dbconnections' => '256',
        }
    }
}

node "stat1.wikimedia.org" {
    include role::statistics::cruncher

    # special accounts
    include admins::globaldev, # RT 3119
        accounts::ezachte,
        accounts::abartov,    # RT 4106
        accounts::aengels,
        accounts::akhanna,
        accounts::bsitu,      # RT 4959
        accounts::milimetric, # RT 3540
        accounts::diederik,
        accounts::dsc,
        accounts::dartar,
        accounts::declerambaul,
        accounts::ebernhardson, # RT 4959,5717
        accounts::fflorin, # RT 6011
        accounts::fschulenburg, # RT 4475
        accounts::giovanni,  # RT 3460
        accounts::halfak,
        accounts::howief,    # RT 3576
        accounts::ironholds,
        accounts::jdlrobson,
        accounts::jgonera,
        accounts::jmorgan,
        accounts::kaldari,   # RT 4959
        accounts::lwelling,  # RT 4959
        accounts::spage,
        accounts::maryana,   # RT 3517
        accounts::mflaschen, # RT 4796
        accounts::mgrover,   # RT 4600
        accounts::mlitn,     # RT 4959
        accounts::otto,
        accounts::reedy,
        accounts::rfaulk,    # RT 5040
        accounts::spetrea,   # RT 3584
        accounts::swalling,  # RT 3653
        accounts::yurik,     # RT 4835
        accounts::mwalker,   # RT 5038
        accounts::awight,    # RT 5048
        accounts::jforrester,# RT 5302
        accounts::qchris,    # RT 5474
        accounts::tnegrin,   # RT 5391
        accounts::kwang,     # RT 5520
        accounts::siebrand,  # RT 5726
        accounts::mholmquist,# RT 6009
        accounts::msyed,     # RT 6506
        accounts::nuria      # RT 6525

    sudo_user { "otto":   privileges => ['ALL = NOPASSWD: ALL'] }

    # Allow Christian to sudo -u stats to debug and test stats' automated cron jobs.
    sudo_user { "qchris": privileges => ['ALL = (stats) NOPASSWD: ALL'] }

    include misc::statistics::cron_blog_pageviews,
        misc::statistics::limn::mobile_data_sync,
        misc::statistics::iptables
}

node "stat1001.wikimedia.org" {
    include role::statistics::www

    # special accounts
    include accounts::ezachte,
        accounts::diederik,
        accounts::otto,
        accounts::dsc,
        accounts::milimetric,
        accounts::rfaulk,  # RT 4258
        accounts::ypanda,  # RT 4687
        accounts::erosen,  # RT 5161
        accounts::qchris,  # RT 5474
        accounts::tnegrin  # RT 5391

    sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }
}

node "stat1002.eqiad.wmnet" {
    # stat1002 is intended to be the private
    # webrequest access log storage host.
    # Users should not use it for app development.
    # Data processing on this machine is fine.

    # Accounts that were previously on stat1
    # for the purposes of crunching private
    # webrequest access logs have been ported
    # over from there.
    include admins::privatedata

    include accounts::manybubbles  # rt 5886
    include accounts::ironholds    # rt 6452

    # add ezachte, spetrea, ironholds to stats group so they can
    # access files created by stats user cron jobs.
    User<|title == ezachte|>     { groups +> [ "stats" ] }
    User<|title == spetrea|>     { groups +> [ "stats" ] }
    User<|title == ironholds|>   { groups +> [ "stats" ] }

    sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }

    # include classes needed for storing and crunching
    # private data on stat1002.
    include role::statistics::private
}

node "streber.wikimedia.org" {
    system::role { "misc": description => "network monitoring server" }

    include passwords::root,
        base::resolving,
        base::sysctl,
        base::motd,
        base::vimconfig,
        base::standard-packages,
        base::monitoring::host,
        base::environment,
        base::platform,
        ssh,
        ganglia,
        ntp::client,
        role::salt::minions,
        admins::roots,
#       misc::torrus,
        misc::rancid,
        firewall::builder

    class { "misc::syslog-server": config => "network" }

    install_certificate{ "star.wikimedia.org": }
}

node /^snapshot([1-4]\.pmtpa|100[1-4]\.eqiad)\.wmnet/ {
    $gid=500
    include base,
        ntp::client,
        ganglia,
        mediawiki::sync,
        snapshots::packages,
        snapshots::sync,
        snapshots::files,
        snapshots::noapache,
        sudo::appserver,
        admins::roots,
        admins::mortals,
        accounts::datasets,
        nfs::data,
        groups::wikidev
}

node "terbium.eqiad.wmnet" {
    include role::applicationserver::maintenance,
        role::db::maintenance,
        misc::deployment::scap_scripts,
        icinga::monitor::jobqueue,
        admins::roots,
        admins::mortals,
        admins::restricted,
        generic::wikidev-umask,
        nrpe


    class { misc::maintenance::pagetriage: enabled => true }
    class { misc::maintenance::translationnotifications: enabled => true }
    class { misc::maintenance::wikidata: enabled => true }
    class { misc::maintenance::echo_mail_batch: enabled => true }
    class { misc::maintenance::parsercachepurging: enabled => true }
    class { misc::maintenance::cleanup_upload_stash: enabled => true }
    class { misc::maintenance::tor_exit_node: enabled => true }
    class { misc::maintenance::aft5: enabled => true }
    class { misc::maintenance::geodata: enabled => true }
    class { misc::maintenance::update_flaggedrev_stats: enabled => true }
    class { misc::maintenance::refreshlinks: enabled => true }
    class { misc::maintenance::update_special_pages: enabled => true }

    # (bug 15434) Periodical run of currently disabled special pages
    # to be run against PMTPA slaves
    class { misc::maintenance::updatequerypages: enabled => true }
}

node /^elastic10(0[1-9]|1[0-2])\.eqiad\.wmnet/ {
    # ganglia cluster name.
    $cluster = 'elasticsearch'
    if $::hostname =~ /^elastic100[17]/ {
        $ganglia_aggregator = true
    }

    include accounts::manybubbles,
        accounts::demon,
        groups::wikidev

    sudo_user { [ "manybubbles" ]: privileges => ['ALL = NOPASSWD: ALL'] }
    sudo_user { [ "demon" ]: privileges => ['ALL = NOPASSWD: ALL'] }

    include standard
    include role::elasticsearch::server
    class { "lvs::realserver": realserver_ips => [ "10.2.2.30" ] }
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

    sudo_user { ['aaron', 'bd808']:  # RT 6366
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

node "tin.eqiad.wmnet" {
    $cluster = "misc"
    $domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

    include standard,
        admins::roots,
        admins::mortals,
        generic::wikidev-umask,
        role::deployment::deployment_servers::production,
        misc::deployment,
        misc::deployment::scap_scripts,
        misc::deployment::l10nupdate,
        mysql,
        role::labsdb::manager,
        ssh::hostkeys-collect

    package { 'unzip': ensure => present } # for reedy RT #6322
}

node "tridge.wikimedia.org" {
    include base,
        backup::server
}

# tmh1/tmh2 video encoding server (precise only)
node /^tmh[1-2]\.pmtpa\.wmnet/ {
    if $::hostname =~ /^tmh[12]$/ {
        $ganglia_aggregator = true
    }

    class { role::applicationserver::videoscaler: run_jobs_enabled => false }

    include nfs::upload
}

# tmh1001/tmh1002 video encoding server (precise only)
node /^tmh100[1-2]\.eqiad\.wmnet/ {
    if $::hostname =~ /^tmh100[12]$/ {
        $ganglia_aggregator = true
    }
    class { role::applicationserver::videoscaler: run_jobs_enabled => true }

}

# Receives log data from varnishes (udp 8422) and Apaches (udp 8421),
# processes it, and broadcasts to internal subscribers.
node 'vanadium.eqiad.wmnet' {
    $gid = 500

    include standard,
        role::eventlogging,
        role::ipython_notebook,
        role::logging::mediawiki::errors,
        groups::wikidev,
        accounts::nuria         # RT 6535

    sudo_user { 'nuria':
        privileges => ['ALL = NOPASSWD: ALL'],
    }
}

# Hosts visualization / monitoring of EventLogging event streams
# and MediaWiki errors. Non-critical at the moment. See RT #5514.
node 'hafnium.wikimedia.org' {
    include standard,
        role::eventlogging::graphite,
        webperf,
        webperf::asset_check,
        webperf::navtiming
}

# StatsD & Graphite host for eqiad. Slotted to replace professor.pmtpa.
# RT #5871
node 'tungsten.eqiad.wmnet' {
    include standard
    include role::statsd
    include role::graphite
    include role::gdash
    include role::mwprof
}

node "virt1000.wikimedia.org" {
    $cluster = "virt"
    $ganglia_aggregator = true
    $is_puppet_master = "true"
    $is_labs_puppet_master = "true"
    $openstack_version = "folsom"

    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard,
        role::dns::ldap,
        ldap::role::server::labs,
        ldap::role::client::labs,
        role::nova::controller,
        role::salt::masters::labs,
        role::deployment::salt_masters::labs
}

node "virt0.wikimedia.org" {
    $cluster = "virt"
    $ganglia_aggregator = true

    $is_puppet_master = "true"
    $is_labs_puppet_master = "true"
    $openstack_version = "folsom"

    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard,
        role::dns::ldap,
        ldap::role::server::labs,
        ldap::role::client::labs,
        role::nova::controller,
        role::nova::manager,
        role::salt::masters::labs,
        role::deployment::salt_masters::labs,
        backup::client
}

node 'virt2.pmtpa.wmnet' {
    $cluster = "virt"
    $openstack_version = "folsom"

    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard,
        role::nova::network,
        role::nova::api
}

node /virt([5-9]|1[0-5]).pmtpa.wmnet/ {
    $cluster = "virt"
    if $::hostname =~ /^virt5$/ {

        $ganglia_aggregator = true
    }

    $openstack_version = "folsom"

    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard,
        role::nova::compute
}

node "labnet1001.eqiad.wmnet" {
    $cluster = "virt"

    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard
}

node /virt100[1-9].eqiad.wmnet/ {
    $cluster = "virt"
    # full root for mhoover, Labs migration contractor
    include admins::labs
    sudo_user { "mhoover": privileges => ['ALL = NOPASSWD: ALL'] }

    include standard
}

node "iodine.wikimedia.org" {
    include role::otrs

    interface::add_ip6_mapped { "main": interface => "eth0" }
}

node /^wtp10(0[1-9]|1[0-9]|2[0-4])\.eqiad\.wmnet$/ {
    $cluster = "parsoid"
    $nagios_group = "${cluster}_$::site"

    if $::hostname == "wtp1001" {
        $ganglia_aggregator = true
    }

    include standard,
        admins::roots,
        admins::parsoid,
        role::parsoid::production

    class { "lvs::realserver": realserver_ips => [ "10.2.2.28" ] }
}

node /^solr(100)?[1-3]\.(eqiad|pmtpa)\.wmnet/ {
    include standard,
        role::solr::geodata
}

node "ytterbium.wikimedia.org" {

    # Note: whenever moving Gerrit out of ytterbium, you will need
    # to update the role::zuul::production
    include role::gerrit::production,
        backup::client,
        groups::wikidev,
        accounts::demon

    install_certificate{ "gerrit.wikimedia.org": ca => "RapidSSL_CA.pem" }

    # full root for gerrit admin (RT-3698)
    sudo_user { "demon": privileges => ['ALL = NOPASSWD: ALL'] }
}


node "yvon.wikimedia.org" {
    include base,
        ganglia,
        ntp::client,
        certificates::wmf_ca
}

node "zhen.wikimedia.org" {
    include standard,
        groups::wikidev,
        mobile::vumi
}

node "zinc.eqiad.wmnet" {

    include standard,
        role::solr::ttm
}

node "zirconium.wikimedia.org" {
    include standard,
        admins::roots,
        nrpe,
        role::planet,
        misc::outreach::civicrm, # contacts.wikimedia.org
        misc::etherpad_lite,
        role::wikimania_scholarships,
        role::bugzilla,
        groups::wikidev,
        accounts::bd808 # rt 6448

    interface::add_ip6_mapped { "main": interface => "eth0" }
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
# erzurumi.pmtpa.wmnet
# indium.frack.eqiad.wmnet
# loudon.wikimedia.org (pmtpa)
# lutetium.frack.eqiad.wmnet
# pappas.wikimedia.org (pmtpa)
# pay-lvs1001.frack.eqiad.wmnet
# pay-lvs1002.frack.eqiad.wmnet
# payments1.wikimedia.org (pmtpa)
# payments2.wikimedia.org (pmtpa)
# payments3.wikimedia.org (pmtpa)
# payments4.wikimedia.org (pmtpa)
# payments1001.frack.eqiad.wmnet
# payments1002.frack.eqiad.wmnet
# payments1003.frack.eqiad.wmnet
# payments1004.frack.eqiad.wmnet
# samarium.frack.eqiad.wmnet
# silicon.frack.eqiad.wmnet
# tellurium.frack.eqiad.wmnet
# thulium.frack.eqiad.wmnet
