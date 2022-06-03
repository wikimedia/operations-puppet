# vim: set ts=4 et sw=4:
# sets up an instance of the 'Volunteer Response Team System'
# https://wikitech.wikimedia.org/wiki/VRT_System
class profile::vrts(
    Stdlib::Fqdn $vrts_database_host = lookup('profile::vrts::database_host'),
    String $vrts_database_name       = lookup('profile::vrts::database_name'),
    String $vrts_database_user       = lookup('profile::vrts::database_user'),
    String $vrts_database_pw         = lookup('profile::vrts::database_pass'),
    Boolean $vrts_daemon             = lookup('profile::vrts::daemon'),
    String $exim_database_name       = lookup('profile::vrts::exim_database_name'),
    String $exim_database_user       = lookup('profile::vrts::exim_database_user'),
    String $exim_database_pass       = lookup('profile::vrts::exim_database_pass'),
){
    include network::constants
    include ::profile::prometheus::apache_exporter

    $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
        $x !~ /127.0.0.0|::1/
    }

    class { '::vrts':
        vrts_database_host => $vrts_database_host,
        vrts_database_name => $vrts_database_name,
        vrts_database_user => $vrts_database_user,
        vrts_database_pw   => $vrts_database_pw,
        vrts_daemon        => $vrts_daemon,
        exim_database_name => $exim_database_name,
        exim_database_user => $exim_database_user,
        exim_database_pass => $exim_database_pass,
        trusted_networks   => $trusted_networks,
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'perl'],
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

    ferm::service { 'vrts_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    $smtp_ferm = join($::mail_smarthost, ' ')
    ferm::service { 'vrts_smtp':
        proto  => 'tcp',
        port   => '25',
        srange => "@resolve((${smtp_ferm}))",
    }

    monitoring::service { 'smtp':
        description   => 'OTRS SMTP',
        check_command => 'check_smtp',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/OTRS#Troubleshooting',
    }

    nrpe::monitor_service{ 'clamd':
        description  => 'clamd running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C clamd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/OTRS#ClamAV',
    }
    nrpe::monitor_service{ 'freshclam':
        description  => 'freshclam running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C freshclam',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/OTRS#ClamAV',
    }

    # can conflict with ferm module
    ensure_packages('libnet-dns-perl')
}
