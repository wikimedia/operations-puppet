# SPDX-License-Identifier: Apache-2.0
# @summary class to add os-reports scripts
# @param ensure the ensure param
# @param os_reports_host the host where we generate the reports
class profile::sre::os_updates (
    Wmflib::Ensure         $ensure          = lookup('profile::sre::os_reports::ensure'),
    Optional[Stdlib::Host] $os_reports_host = lookup('profile::sre::os_reports::host'),
) {

    systemd::sysuser { 'os-reports':
        ensure => $ensure,
        shell  => '/bin/bash',
    }

    file { '/srv/os-reports':
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'os-reports',
        group  => 'os-reports',
        mode   => '0755',
    }

    file { '/usr/local/bin/os-updates-report':
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/sre/os-updates-report.py',
    }

    if $ensure == 'present' {
        wmflib::dir::mkdir_p('/etc/wikimedia/os-updates', {
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        })
    }

    file {
        default:
            ensure => stdlib::ensure($ensure, 'file'),
            owner  => 'root',
            group  => 'root',
            mode   => '0444';
        '/etc/wikimedia/os-updates/os-updates-tracking.cfg':
            source => 'puppet:///modules/profile/sre/os-updates-tracking.cfg';
        '/etc/wikimedia/os-updates/puppetdb_owners.yaml':
            content => profile::contacts::get_owners().to_yaml;
        '/etc/wikimedia/os-updates/additional_owners.yaml':
            source => 'puppet:///modules/profile/sre/additional_owners.yaml';
        '/etc/wikimedia/os-updates/buster.yaml':
            source => 'puppet:///modules/profile/sre/buster.yaml';
        '/etc/wikimedia/os-updates/bullseye.yaml':
            source => 'puppet:///modules/profile/sre/bullseye.yaml';
    }

    # The reports could be run on any Cumin host, but only generate it once
    $os_reports_timer_ensure = ($facts['fqdn'] == $os_reports_host).bool2str($ensure, 'absent')

    systemd::timer::job { 'generate_os_reports':
        ensure          => $os_reports_timer_ensure,
        description     => 'Generate OS migration report/overview',
        user            => 'os-reports',
        logging_enabled => false,
        send_mail       => false,
        command         => '/usr/local/bin/os-updates-report',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 02:00:00'},
    }

    if $ensure == 'present' {
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
}
