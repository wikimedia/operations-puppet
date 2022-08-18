# @summary profile to configure systemd timesyncd
# @param ensure wether to ensure the profile
# @param ntp_servers list of ntp servers
class profile::systemd::timesyncd (
    Wmflib::Ensure      $ensure      = lookup('profile::systemd::timesyncd::ensure'),
    Array[Stdlib::Host] $ntp_servers = lookup('profile::systemd::timesyncd::ntp_servers'),
) {

    class {'systemd::timesyncd':
        ensure      => $ensure,
        ntp_servers => $ntp_servers,
    }
    # HDFS/fuse is known to cause issues with timesync and ProtectSystem= strict
    # As such remove this from the list of accessible paths (T310643)
    systemd::unit { 'systemd-timesyncd_override_protect_system':
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
