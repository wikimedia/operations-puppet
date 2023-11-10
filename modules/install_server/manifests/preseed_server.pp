# Class: install_server::preseed_server
#
# This class populated preseeding server's configuration
#
# Parameters:
#
# Actions:
#       Populate preseeding configuration directory
#
# Requires:
#
# Sample Usage:
#   include install_server::preseed_server


class install_server::preseed_server (
    Hash[Stdlib::IP::Address, Install_server::Preseed_ip::Config] $preseed_per_ip = {},
    Hash[String[1], Array[Install_server::Preseed_host::Config]] $preseed_per_hostname = {},

) {
    file { '/srv/autoinstall':
        ensure  => directory,
        mode    => '0444',
        source  => 'puppet:///modules/install_server/autoinstall',
        recurse => true,
        links   => manage,
        purge   => true,
    }

    file { '/srv/autoinstall/netboot.cfg':
        ensure  => present,
        mode    => '0444',
        content => template('install_server/netboot.cfg.erb'),
    }

    file { '/srv/autoinstall/preseed.cfg':
        ensure => link,
        target => '/srv/autoinstall/netboot.cfg',
    }
}
