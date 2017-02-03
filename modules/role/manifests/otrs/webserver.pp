# vim: set ts=4 et sw=4:
# sets up an instance of the 'Open-source Ticket Request System'
# https://en.wikipedia.org/wiki/OTRS
#
# filtertags: labs-project-otrs
class role::otrs::webserver {

    system::role { 'role::otrs::webserver':
        description => 'OTRS Web Application Server',
    }
    include standard
    include base::firewall

    include passwords::mysql::otrs
    include passwords::exim
    include network::constants
    $otrs_database_user = $::passwords::mysql::otrs::user
    $otrs_database_pw   = $::passwords::mysql::otrs::pass
    $exim_database_pass = $passwords::exim::otrs_mysql_password

    $otrs_database_host = hiera('otrs::otrs_database_host')
    $otrs_database_name = hiera('otrs::otrs_database_name')

    class { '::otrs':
        otrs_database_host => $otrs_database_host,
        otrs_database_name => $otrs_database_name,
        otrs_database_user => $otrs_database_user,
        otrs_database_pw   => $otrs_database_pw,
        exim_database_name => 'otrs',
        exim_database_user => 'exim',
        exim_database_pass => $exim_database_pass,
        trusted_networks   => $network::constants::all_networks,
    }

    # TODO: On purpose here since it references a file not in a module which is
    # used by other classes as well
    # lint:ignore:puppet_url_without_modules
    file { '/etc/exim4/wikimedia_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/wikimedia_domains',
        require => Class['exim4'],
    }
    # lint:endignore

    ferm::service { 'otrs_http':
        proto => 'tcp',
        port  => '80',
    }

    $smtp_ferm = join($::mail_smarthost, ' ')
    ferm::service { 'otrs_smtp':
        proto  => 'tcp',
        port   => '25',
        srange => "@resolve((${smtp_ferm}))",
    }

    monitoring::service { 'smtp':
        description   => 'OTRS SMTP',
        check_command => 'check_smtp',
    }

    nrpe::monitor_service{ 'clamd':
        description  => 'clamd running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C clamd'
    }
    nrpe::monitor_service{ 'freshclam':
        description  => 'freshclam running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C freshclam'
    }

    # can conflict with ferm module
    if ! defined(Package['libnet-dns-perl']){
        package { 'libnet-dns-perl':
            ensure => present,
        }
    }
}
