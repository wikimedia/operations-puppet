# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure systemd timesyncd
# @param ensure wether to ensure the profile
# @param ntp_servers list of ntp servers
class profile::systemd::timesyncd (
    Wmflib::Ensure                           $ensure            = lookup('profile::systemd::timesyncd::ensure'),
    Hash[Wmflib::Sites, Wmflib::Sites]       $site_nearest_core = lookup('site_nearest_core'),
    Hash[Wmflib::Sites, Array[Stdlib::Fqdn]] $ntp_peers         = lookup('ntp_peers'),
    Optional[Array[Stdlib::Host]]            $ntp_servers       = lookup('profile::systemd::timesyncd::ntp_servers', {'default_value' => undef}),
) {

    # For historical context, this array was manually managed via
    # hieradata/$::site/profile/systemd/timesyncd.yaml.
    #
    # To set ntp_servers in a site, use the ntp_peers under it and the peers of
    # the closest core site, which we determine from $::datacenters_tree.
    if $ntp_servers == undef {
        $_ntp_servers = [$ntp_peers[$::site], $ntp_peers[$site_nearest_core[$::site]]].flatten
    } else {
        $_ntp_servers = $ntp_servers
    }

    class {'systemd::timesyncd':
        ensure      => $ensure,
        ntp_servers => $_ntp_servers,
    }
    # HDFS/fuse is known to cause issues with timesync and ProtectSystem= strict
    # As such remove this from the list of accessible paths (T310643)
    systemd::unit { 'systemd-timesyncd.service':
        ensure   => $ensure,
        content  => "[Service]\nInaccessiblePaths=-/mnt\n",
        restart  => true,
        override => true,
    }
    systemd::unit { 'systemd-timedated.service':
        ensure   => $ensure,
        content  => "[Service]\nInaccessiblePaths=-/mnt\n",
        restart  => true,
        override => true,
    }
    profile::auto_restarts::service { 'systemd-timesyncd':
        ensure => $ensure,
    }

    file { '/usr/lib/nagios/plugins/check_timedatectl':
        ensure => 'absent',
    }
    # /usr/local/lib/nagios/plugins is managed by the nrpe module
    # and dependencies will be handled via auto requires
    nrpe::plugin { 'check_timedatectl':
        ensure => $ensure,
        source => 'puppet:///modules/profile/systemd/check_timedatectl',
    }

    nrpe::monitor_service { 'timesynd_ntp_status':
        ensure         => $ensure,
        description    => 'Check the NTP synchronisation status of timesyncd',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_timedatectl',
        contact_group  => 'admins',
        check_interval => 30,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/NTP',
    }
}
