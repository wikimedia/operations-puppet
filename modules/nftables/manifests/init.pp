# SPDX-License-Identifier: Apache-2.0
class nftables (
    Wmflib::Ensure $ensure = 'absent',
) {
    if debian::codename::eq('buster') and $ensure == 'present' {
        # nftables in buster is too old to correctly include externally defined
        # set, see https://phabricator.wikimedia.org/T354279
        apt::package_from_bpo { 'nftables_buster_bpo':
            packages => ['libnftnl11', 'libnftables1', 'nftables'],
            distro   => 'buster',
        }
    } else {
        package { 'nftables':
            ensure => $ensure,
        }
    }

    # if we want the service to be stopped, it indicates we actually don't want this unit running
    # this may prevent accidents in servers whose firewall is managed by others (e.g, neutron)
    if $ensure == 'absent' {
        systemd::mask { 'nftables.service': }
    }
    if $ensure == 'present' {
        systemd::unmask { 'nftables.service': }
    }

    $nft_main_file = '/etc/nftables/main.nft' # used in the systemd template
    systemd::service { 'nftables':
        ensure         => $ensure,
        content        => systemd_template('nftables'),
        override       => true,
        service_params => {
            hasrestart => true,
            restart    => '/usr/bin/systemctl reload nftables'
        }
    }

    # create a directory to hold the nftables main config
    file { '/etc/nftables/':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare sets of servers, included by the main config
    file { '/etc/nftables/sets':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare incoming traffic, included by the main config
    file { '/etc/nftables/input':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare outgoing traffic, included by the main config
    file { '/etc/nftables/output':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to define outbound DSCP markings, included by the main config
    file { '/etc/nftables/postrouting':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare exceptions from connection tracking for
    # traffic, included by the main config
    file { '/etc/nftables/notrack':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
    }

    # deploy the basic configuration file, i.e, the basic nftables ruleset skeleton
    file { $nft_main_file:
        ensure  => $ensure,
        source  => 'puppet:///modules/nftables/main.nft',
        require => File['/etc/nftables'],
        notify  => Service['nftables'],
    }

    # cleanup the file shipped with the debian package, we don't use it
    file { '/etc/nftables.conf':
        ensure => 'absent',
    }

    File <| tag == 'nft' |>
}
