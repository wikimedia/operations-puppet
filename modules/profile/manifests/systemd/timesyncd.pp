# @summary profile to configure systemd timesyncd
# @param ensure wether to ensure the profile
# @ntp_servers list of ntp servers
class profile::systemd::timesyncd (
    Wmflib::Ensure      $ensure      = lookup('profile::systemd::timesyncd::ensure'),
    Array[Stdlib::Host] $ntp_servers = lookup('profile::systemd::timesyncd::ntp_servers'),
) {

    class {'systemd::timesyncd':
        ensure      => $ensure,
        ntp_servers => $ntp_servers,
    }

    profile::auto_restarts::service { 'systemd-timesyncd':
        ensure => $ensure,
    }

    file { '/usr/lib/nagios/plugins/check_timedatectl':
        ensure => stdlib::ensure($ensure, file),
        source => 'puppet:///modules/profile/systemd/check_timedatectl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'timesynd_ntp_status':
        ensure         => $ensure,
        description    => 'Check the NTP synchronisation status of timesyncd',
        nrpe_command   => '/usr/lib/nagios/plugins/check_timedatectl',
        require        => File['/usr/lib/nagios/plugins/check_timedatectl'],
        contact_group  => 'admins',
        check_interval => 30,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/NTP',
    }
}
