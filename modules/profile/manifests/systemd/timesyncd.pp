# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure systemd timesyncd
# @param ensure wether to ensure the profile
# @param ntp_servers list of ntp servers
class profile::systemd::timesyncd (
    Wmflib::Ensure                           $ensure            = lookup('profile::systemd::timesyncd::ensure'),
    Hash[Wmflib::Sites, Wmflib::Sites]       $site_nearest_core = lookup('site_nearest_core'),
    Hash[Wmflib::Sites, Array[Stdlib::Fqdn]] $ntp_peers         = lookup('ntp_peers'),
    Array[Stdlib::Fqdn]                      $ntp_anycast_peers = lookup('ntp_anycast_peers'),
    Optional[Array[Stdlib::Host]]            $ntp_servers       = lookup('profile::systemd::timesyncd::ntp_servers', {'default_value' => undef}),
) {

    if $ntp_servers == undef {
        $_ntp_servers = $ntp_anycast_peers
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
}
