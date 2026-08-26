# == Class profile::discovery::client
#
# Will use confd to watch our discovery system and save the result as a json file in a chosen directory.
# Also exports the conftool-configured pooled state of both the discovery (dnsdisc) and geodns
# object types as node-exporter textfile metrics.
#
# === Parameters
#
# [*path*] The directory where the file should go.
#
# [*watch_interval*] The interval in seconds for checks on etcd. Defaults to 5
#
class profile::discovery::client(
    Stdlib::Unixpath $path=lookup('profile::discovery::path'),
    Boolean $prometheus_export = lookup('profile::discovery::prometheus_export', {default_value => true}),
){
    # We need confd
    require ::profile::conftool::state
    file { $path:
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    confd::file { "${path}/discovery-basic.yaml":
        ensure     => present,
        content    => template('profile/discovery/basic.yaml.tpl.erb'),
        watch_keys => ['/'],
        prefix     => '/discovery',
        mode       => '0444',
        check      => 'ruby -e \"require \'yaml\'; YAML.load_file(\'{{ .src }}\')\"',
    }

    confd::file { '/var/lib/prometheus/node.d/discovery-conftool-state.prom':
        ensure     => bool2str($prometheus_export, 'present', 'absent'),
        content    => template('profile/discovery/prometheus.prom.erb'),
        watch_keys => ['/'],
        prefix     => '/discovery',
        mode       => '0444',
    }

    confd::file { '/var/lib/prometheus/node.d/geodns-conftool-state.prom':
        ensure     => bool2str($prometheus_export, 'present', 'absent'),
        content    => template('profile/discovery/geodns-prometheus.prom.erb'),
        watch_keys => ['/'],
        prefix     => '/geodns',
        mode       => '0444',
    }

    confd::file { "${path}/services.yaml":
        ensure     => absent,
    }
}
