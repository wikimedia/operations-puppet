# SPDX-License-Identifier: Apache-2.0`
# @param ensure ensure parameter for files and service
class nftables (
    Wmflib::Ensure $ensure         = 'absent',
) {
    debian::codename::require::min('buster')

    package { 'nftables':
        ensure => $ensure,
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
            restart    => '/usr/bin/systemctl reload nftables',
        },
    }

    # create a directory to hold the nftables main config
    file { '/etc/nftables/':
        ensure  => stdlib::ensure($ensure, 'directory'),
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare sets of servers, included by the main config
    file { '/etc/nftables/sets':
        ensure  => stdlib::ensure($ensure, 'directory'),
        purge   => true,
        recurse => true,
    }

    # For Puppet roles to declare incoming traffic, included by the main config
    file { '/etc/nftables/input':
        ensure  => stdlib::ensure($ensure, 'directory'),
        purge   => true,
        recurse => true,
    }

    # deploy the basic configuration file, i.e, the basic nftables ruleset skeleton
    file { $nft_main_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        source  => 'puppet:///modules/nftables/main.nft',
        require => File['/etc/nftables'],
        notify  => Systemd::Service['nftables'],
    }

    # cleanup the file shipped with the debian package, we don't use it
    file { '/etc/nftables.conf':
        ensure => 'absent',
    }

    File <| tag == 'nft' |>
}
