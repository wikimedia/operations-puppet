class dynamicproxy::api (
    Stdlib::HTTPUrl                   $keystone_api_url,
    String[1]                         $dns_updater_username,
    String[1]                         $dns_updater_password,
    String[1]                         $dns_updater_project,
    String[1]                         $token_validator_username,
    String[1]                         $token_validator_password,
    String[1]                         $token_validator_project,
    Stdlib::Host                      $mariadb_host,
    String[1]                         $mariadb_db,
    String[1]                         $mariadb_username,
    String[1]                         $mariadb_password,
    Stdlib::IP::Address::V4::Nosubnet $proxy_dns_ipv4,
    Stdlib::IP::Address::V6::Nosubnet $proxy_dns_ipv6,
    Hash[String, Dynamicproxy::Zone]  $supported_zones,
    String[1]                         $acme_certname,
    Boolean                           $read_only = false,
) {
    file { '/usr/local/bin/invisible-unicorn.py':
        source => 'puppet:///modules/dynamicproxy/api/invisible-unicorn.py',
        mode   => '0555',
    }

    ensure_packages([
        'python3-flask',
        'python3-flask-sqlalchemy',
        'python3-flask-keystone',  # this one is built and maintained by us
        'python3-pymysql',
        'python3-oslo.context',
        'python3-oslo.policy',
        'python3-flask-sqlalchemy',
    ])

    apt::pin { 'python3-flask':
        pin      => 'version 2.2.*',
        package  => 'python3-flask',
        priority => 1001,
        before   => Package['python3-flask'],
    }

    uwsgi::app { 'invisible-unicorn':
        settings  => {
            uwsgi => {
                plugins            => 'python3',
                master             => true,
                socket             => '/run/uwsgi/invisible-unicorn.sock',
                mount              => '/dynamicproxy-api=/usr/local/bin/invisible-unicorn.py',
                callable           => 'app',
                manage-script-name => true,
                workers            => 4,
            },
        },
        subscribe => File['/usr/local/bin/invisible-unicorn.py'],
    }

    file { '/etc/dynamicproxy-api':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { '/etc/dynamicproxy-api/zones.json':
        content => $supported_zones.to_json_pretty(),
        mode    => '0444',
        notify  => Uwsgi::App['invisible-unicorn'],
    }

    file { '/etc/dynamicproxy-api/config.ini':
        content   => template('dynamicproxy/api/invisible-unicorn.ini.erb'),
        mode      => '0444',
        show_diff => false,
        notify    => Uwsgi::App['invisible-unicorn'],
    }

    file { '/etc/dynamicproxy-api/schema.sql':
        source => 'puppet:///modules/dynamicproxy/api/schema.sql',
        mode   => '0555',
    }

    cinderutils::ensure { 'db_backups':
        min_gb      => 1,
        max_gb      => 20,
        mount_point => '/srv/backup',
        before      => File['/srv/backup/README'],
    }

    file { '/srv/backup/README':
        ensure => file,
        source => 'puppet:///modules/dynamicproxy/api/BackupReadme',
        mode   => '0644',
    }

    file { '/usr/local/sbin/proxydb-bak.sh':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/dynamicproxy/api/proxydb-bak.sh',
    }

    systemd::timer::job { 'proxydb-backup':
        ensure             => present,
        user               => 'root',
        description        => 'create a backup of the proxy configuration database',
        command            => "/usr/local/sbin/proxydb-bak.sh ${mariadb_db}",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    nginx::site { 'invisible-unicorn':
        content => template('dynamicproxy/api/api.conf.erb'),
        require => Uwsgi::App['invisible-unicorn'],
    }

    haproxy::site { 'proxy-api':
        content => template('dynamicproxy/api/tls-terminator.cfg.erb'),
    }
}
