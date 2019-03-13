# == Class: diamond
#
# Diamond is a Python network daemon that collects system metrics and
# publishes them to a metric aggregator like Graphite or StatsD. Diamond
# ships with a suite of metric collectors for CPU, memory, network, disk,
# etc. Diamond also features an API for implementing custom collectors
# that gather metrics from almost any source.
#
# === Parameters
#
# [*handler*]
#   Import path and class name of diamond.handler.Handler subclass to
#   publish metrics too.
#
#   See: <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#
# [*interval*]
#   Default interval in seconds at which statistics will be collected
#
# [*settings*]
#   A hash of configuration options for the desired handler.
#   See <https://github.com/BrightcoveOS/Diamond/wiki/Handlers>
#   for a listing of configuration options.
#
#   These are passed on verbatim to diamond so should all be quoted
#   strings and not native puppet types e.g. 'true' not true.
#
# [*path_prefix*]
#   The prefix to be used for metrics, used to namespace where
#   the metric came from.
#
# [*keep_logs_for*]
#   Integer of days to keep logs after current day.
#
# [*service*]
#   controls the state of the diamond service
#   See: http://docs.puppetlabs.com/references/latest/type.html#service-attribute-ensure
#
# === Examples
#
# A Graphite configuration for Diamond:
#
#  class { '::diamond':
#    handler  => 'diamond.handler.graphite.GraphiteHandler',
#    settings => {
#      host => 'graphite.wikimedia.org',
#      port => 2003,
#    },
#  }
#

class diamond(
    $handler       = 'diamond.handler.graphite.GraphiteHandler',
    $interval      = '60',
    $path_prefix   = 'servers',
    $keep_logs_for = '5',
    $service       = running,
    $settings      = {
        host  => 'localhost',
        port  => '8125',
        batch => '20',
    },
) {
    require_package('python-statsd')
    if empty($handler) {
        fail('$handler cannot be empty')
    }

    package { [ 'diamond', ]:
        ensure  => present,
    }

    file { [ '/etc/diamond/collectors', '/etc/diamond/handlers' ]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['diamond'],
    }

    file { '/etc/diamond/diamond.conf':
        content => template('diamond/diamond.conf.erb'),
        require => File['/etc/diamond/collectors', '/etc/diamond/handlers'],
    }

    # Truncate the import path, leaving only the class name.
    $handler_class = regsubst($handler, '.*\.', '')
    file { "/etc/diamond/handlers/${handler_class}.conf":
        content => template('diamond/handler.conf.erb'),
    }

    service { 'diamond':
        ensure     => $service,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['diamond'],
        subscribe  => [
            File['/etc/diamond/diamond.conf'],
            File["/etc/diamond/handlers/${handler_class}.conf"],
        ],
    }

    if os_version('debian >= jessie') {
        systemd::unit { 'diamond':
            ensure   => present,
            restart  => true,
            override => true,
            content  => template('diamond/initscripts/diamond.systemd_override.erb'),
        }
    }

    diamond::collector { 'CPU':
        settings => {
            # lint:ignore:quoted_booleans
            # As per comments above, these must be quoted for the config
            #  file.
            percore   => 'false',
            normalize => 'true',
            # lint:endignore
        },
    }

    diamond::collector { 'Network': }
    diamond::collector { 'DiskSpace':
        settings => {
            filesystems     => 'ext2,ext3,ext4,xfs,fuse.fuse_dfs,fat32,fat16,btrfs',
            # Dockerd has ephemeral mounts - T181295
            exclude_filters => [
                '^/var/lib/docker/',
                '^/run/docker/',
            ],
        },
    }

    diamond::collector { 'LoadAverage': }
    diamond::collector { 'Memory': }
    diamond::collector { 'VMStat': }


    diamond::collector { 'TCP':
        settings => {
            allowed_names => [
              'ListenOverflows', 'ListenDrops',
              'TCPLoss', 'TCPTimeouts',
              'TCPFastRetrans', 'TCPLostRetransmit',
              'TCPForwardRetrans', 'TCPSlowStartRetrans',
              'CurrEstab', 'TCPAbortOnMemory',
              'TCPBacklogDrop', 'AttemptFails',
              'EstabResets', 'InErrs',
              'ActiveOpens', 'PassiveOpens',
              'TCPFastOpenActive', 'TCPFastOpenActiveFail',
              'TCPFastOpenPassive', 'TCPFastOpenPassiveFail',
              'TCPFastOpenListenOverflow', 'TCPFastOpenCookieReqd',
              'TCPSynRetrans', 'TCPOrigDataSent',
            ],
            gauges        => [
              'CurrEstab', 'MaxConn',
              'TCPFastOpenActive', 'TCPFastOpenActiveFail',
              'TCPFastOpenPassive', 'TCPFastOpenPassiveFail',
              'TCPFastOpenListenOverflow', 'TCPFastOpenCookieReqd',
            ],
        },
    }

    diamond::collector { 'DiskUsage':
        settings => {
            devices => 'PhysicalDrive[0-9]+$|md[0-9]+$|sd[a-z]+$|x?vd[a-z]+$|disk[0-9]+$',
        },
    }
}
