# Installs a proxy server for the install server
class profile::installserver::proxy(
    Wmflib::Ensure $ensure = lookup('profile::installserver::proxy::ensure'),
){

    class { 'squid3':
        ensure         => $ensure,
        config_content => template('role/caching-proxy/squid.conf.erb'),
    }

    cron { 'squid-logrotate':
        ensure  => $ensure,
        command => '/usr/sbin/squid3 -k rotate',
        user    => 'root',
        hour    => '17',
        minute  => '15',
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
