# == Class zookeeper
# Installs common zookeeper package and configs.
#
# == Parameters
# $hosts         - Hash of zookeeper fqdns to myids.
#
# $data_dir      - Zookeeper dataDir.     Default: /var/lib/zookeeper
#
# $data_log_dir  - Zookeeper dataLogDir.  Default: undef.
#
# $max_client_connections - The maximum number of per-IP client connections.
#                           Default: 0 (unlimited)
#
# $tick_time     - The length of a single tick, which is the basic time unit used by
#                  ZooKeeper, as measured in milliseconds.  Default: 2000
#
# $init_limit    - Amount of time in ticks to allow followers to connect and sync to
#                  a leader.  Default: 10
#
# $sync_limit    - Amount of tim to allow followers to sync with ZooKeeper.  Default: 5
#
# $version       - Zookeeper package version number.  Set this if you need to
#                  override the default package version.  Default: installed.
#
# == Usage
#
# class { 'zookeeper':
#   hosts    => { 'zoo1.domain.org' => 1, 'zoo2.domain.org' => 2, 'zoo3.domain.org' => 3 },
#   data_dir => '/var/lib/zookeeper',
# }
#
# The above setup should be used to configure a 3 node zookeeper cluster.
# You can include the above class on any of your nodes that will need to talk
# to the zookeeper cluster.
#
# On the 3 zookeeper server nodes, you should also include:
#
# class { 'zookeeper::server': }
#
# This will ensure that the zookeeper server is running.
# Remember that this requires that you also include the
# zookeeper class as defined above as well as the server class.
#
# On each of the defined zookeeper hosts, a myid file must be created
# that identifies the host in the zookeeper quorum.  This myid number
# will be inferred from the nodes index in the zookeeper hosts array.
# e.g.  zoo1.domain.org's myid will be '1', zoo2.domain.org's myid will be 2, etc.
#
class zookeeper(
    $hosts                  = { "${::fqdn}" => 1 },
    $data_dir               = '/var/lib/zookeeper',
    $data_log_dir           = undef,
    $max_client_connections = 0,
    $tick_time              = 2000,
    $init_limit             = 10,
    $sync_limit             = 5,
    $conf_template          = 'zookeeper/zoo.cfg.erb',
    $version                = 'installed',
) {
    if !defined(Package['zookeeper']) {
        package { 'zookeeper':
            ensure => $version,
        }
    }

    file { '/etc/zookeeper/conf/zoo.cfg':
        content => template($conf_template),
        require => Package['zookeeper'],
    }
}
