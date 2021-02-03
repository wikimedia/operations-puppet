# Installs a proxy server for the install server
class profile::installserver::proxy(
    Wmflib::Ensure $ensure = lookup('profile::installserver::proxy::ensure'),
){

    class { 'squid':
        ensure         => $ensure,
        config_content => template('role/caching-proxy/squid.conf.erb'),
    }

    base::service_auto_restart { 'squid': }

    systemd::timer::job { 'squid-logrotate':
        ensure      => $ensure,
        user        => 'root',
        description => 'rotate squid proxy log files',
        command     => '/usr/sbin/squid -k rotate',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 17:15:00'},
    }

    ferm::service { 'proxy':
        proto  => 'tcp',
        port   => '8080',
        srange => '$PRODUCTION_NETWORKS',
    }

    # Monitoring
    monitoring::service { 'squid':
        ensure        => $ensure,
        description   => 'Squid',
        check_command => 'check_tcp!8080',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/HTTP_proxy',
    }
}
