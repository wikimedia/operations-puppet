# == Class profile::sre::os_updates
#
# Installs a script to track the status of OS upgrades across our fleet
class profile::sre::os_updates (
    Stdlib::Host $os_reports_host = lookup('profile::sre::os_reports::host'),
) {

    group { 'os-reports':
        ensure => present,
    }

    user { 'os-reports':
        ensure     => 'present',
        gid        => 'os-reports',
        shell      => '/bin/bash',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/srv/os-reports':
        ensure => 'directory',
        owner  => 'os-reports',
        group  => 'os-reports',
        mode   => '0755',
    }

    file { '/usr/local/bin/os-updates-report':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/sre/os-updates-report.py',
    }

    wmflib::dir::mkdir_p('/etc/wikimedia/os-updates', {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    })

    file { '/etc/wikimedia/os-updates/os-updates-tracking.cfg':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/sre/os-updates-tracking.cfg',
    }

    file { '/etc/wikimedia/os-updates/puppetdb_owners.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => profile::contacts::get_owners().to_yaml,
    }

    file { '/etc/wikimedia/os-updates/stretch.yaml':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/sre/stretch.yaml',
    }

    # The reports could be run on any Cumin host, but only generate it once
    $os_reports_timer_ensure = ($facts['fqdn'] == $os_reports_host).bool2str('present', 'absent')

    systemd::timer::job { 'generate_os_reports':
        ensure          => $os_reports_timer_ensure,
        description     => 'Generate OS migration report/overview',
        user            => 'os-reports',
        logging_enabled => false,
        send_mail       => false,
        command         => '/usr/local/bin/os-updates-report',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 02:00:00'},
    }

    ensure_packages(['python3-pypuppetdb', 'python3-dominate'])

    class {'rsync::server':
        ensure_service => stdlib::ensure($os_reports_timer_ensure, 'service')
    }
    # Allow miscweb hosts to pull reports for serving them via HTTP
    $miscweb_rsync_clients = wmflib::role::hosts('miscweb')
    rsync::server::module { 'osreports':
        ensure         => $os_reports_timer_ensure,
        path           => '/srv/os-reports',
        read_only      => 'yes',
        hosts_allow    => $miscweb_rsync_clients,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }
}
