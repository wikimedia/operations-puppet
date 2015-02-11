# = Class nagios_common::check::ganglia
#
# Installs check_ganglia package and sets up symlink into
# /usr/lib/nagios/plugins.
#
# check_ganglia allows arbitrary values to be queried from ganglia and checked
# for nagios/icinga.  This is better than ganglios, as it queries gmetad's xml
# query interfaces directly, rather than downloading and mangling xmlfiles from
# each aggregator.
#
# NOTE: Package not available for trusty yet
#
# [*config_dir*]
#   The base directory to put configuration in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the config file.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the config file.
#   Defaults to 'icinga'
class nagios_common::check::ganglia(
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
) {
    package { 'check-ganglia':
        ensure  => 'installed',
    }

    file { '/usr/lib/nagios/plugins/check_ganglia':
        ensure  => 'link',
        target  => '/usr/bin/check_ganglia',
        require => Package['check-ganglia'],
    }

    nagios_common::check_command::config { 'check_ganglia':
        require    => File["${config_dir}/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group
    }
}
