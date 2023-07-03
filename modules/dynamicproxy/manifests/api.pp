class dynamicproxy::api (
    Stdlib::HTTPUrl                   $keystone_api_url,
    String[1]                         $dns_updater_username,
    String[1]                         $dns_updater_password,
    String[1]                         $dns_updater_project,
    String[1]                         $token_validator_username,
    String[1]                         $token_validator_password,
    String[1]                         $token_validator_project,
    Stdlib::IP::Address::V4::Nosubnet $proxy_dns_ipv4,
    Hash[String, Dynamicproxy::Zone]  $supported_zones,
    Optional[String]                  $acme_certname = undef,
    Optional[Array[String]]           $ssl_settings = undef,
    Boolean                           $read_only = false,
) {
    # for new enough python3-keystonemiddleware versions
    debian::codename::require('bullseye', '>=')

    file { '/usr/local/bin/invisible-unicorn.py':
        source => 'puppet:///modules/dynamicproxy/invisible-unicorn.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if debian::codename::eq('bullseye') {
        # see https://phabricator.wikimedia.org/T340881
        apt::pin { 'python3-flask-sqlalchemy-bullseye-bpo':
            pin      => 'release a=bullseye-backports',
            package  => 'python3-flask-sqlalchemy',
            priority => 1001,
            before   => Package['python3-flask-sqlalchemy'],
            notify   => Exec['python3-flask-sqlalchemy-apt-get-update'],
        }
        exec { 'python3-flask-sqlalchemy-apt-get-update':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

        Exec['python3-flask-sqlalchemy-apt-get-update'] -> Package <| |>
    }

    ensure_packages([
        'python3-flask',
        'python3-redis',
        'python3-flask-sqlalchemy',
        'python3-flask-keystone',  # this one is built and maintained by us
        'python3-oslo.context',
        'python3-oslo.policy',
        'sqlite3'
    ])

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
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Uwsgi::App['invisible-unicorn'],
    }

    file { '/etc/dynamicproxy-api/config.ini':
        content   => template('dynamicproxy/invisible-unicorn.ini.erb'),
        owner     => 'root',
        group     => 'root',
        mode      => '0444',
        show_diff => false,
        notify    => Uwsgi::App['invisible-unicorn'],
    }

    cinderutils::ensure { 'db_backups':
        min_gb      => 1,
        max_gb      => 20,
        mount_point => '/srv/backup',
        before      => File['/srv/backup/README'],
    }

    file { '/srv/backup/README':
        source => 'puppet:///modules/dynamicproxy/BackupReadme',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/sbin/proxydb-bak.sh':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dynamicproxy/proxydb-bak.sh',
    }

    systemd::timer::job { 'proxydb-backup':
        ensure             => present,
        user               => 'root',
        description        => 'run proxydb-bak.sh',
        command            => '/usr/local/sbin/proxydb-bak.sh',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    # Create initial db file if it doesn't exist, but don't clobber if it does.
    file { '/etc/dynamicproxy-api/data.db':
        ensure  => file,
        source  => 'puppet:///modules/dynamicproxy/initial-data.db',
        replace => false,
        require => File['/etc/dynamicproxy-api'],
        owner   => 'www-data',
        group   => 'www-data',
    }

    nginx::site { 'invisible-unicorn':
        content => template('dynamicproxy/api.conf.erb'),
        require => Uwsgi::App['invisible-unicorn'],
    }

    # This is a GET-only front end that sits on port 5669.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'proxygetter':
        source => 'puppet:///modules/dynamicproxy/proxygetter.conf',
    }
}
