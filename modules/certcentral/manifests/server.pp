class certcentral::server (
    Hash[String, Hash[String, String]] $accounts = {},
    Hash[String, Hash[String, Any]] $certificates = {},
    Hash[String, Hash[String, Any]] $challenges = {},
    String $http_proxy = '',
    Wmflib::Ensure $http_challenge_support = absent,
    String $active_host = '',
    String $passive_host = '',
) {
    $is_active = $::fqdn == $active_host

    if os_version('debian == stretch') {
        apt::pin { 'acme':
            package  => 'python3-acme',
            pin      => 'release a=stretch-backports',
            priority => '1001',
            notify   => Exec['apt-get update'],
            before   => Package['certcentral'],
        }
    }

    user { 'certcentral':
        ensure => present,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/bash',
        before => Package['certcentral'],
    }

    ssh::userkey { 'certcentral':
        content => secret('keyholder/authdns_certcentral.pub'),
    }

    package { 'certcentral':
        ensure  => present,
        require => Exec['apt-get update'],
    }

    file { '/etc/certcentral/conf.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        require => Package['certcentral']
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'strong')
    file { '/etc/certcentral/config.yaml':
        owner   => 'certcentral',
        group   => 'certcentral',
        mode    => '0444',
        content => template('certcentral/certcentral.config.yaml.erb'),
        notify  => [
            Base::Service_unit['uwsgi-certcentral'],
            Service['certcentral'],
        ],
        require => Package['certcentral'],
    }

    $live_certs_path = '/var/lib/certcentral/live_certs'
    file { '/etc/certcentral/cert-sync.conf':
        owner   => 'certcentral',
        group   => 'certcentral',
        mode    => '0444',
        content => template('certcentral/cert-sync.conf.erb'),
        require => Package['certcentral'],
    }

    $accounts.each |String $account_id, Hash $account_details| {
        file { "/etc/certcentral/accounts/${account_id}":
            ensure  => directory,
            require => Package['certcentral'],
            owner   => 'certcentral',
            group   => 'certcentral',
            mode    => '0555',
        }
        file { "/etc/certcentral/accounts/${account_id}/regr.json":
            require => File["/etc/certcentral/accounts/${account_id}"],
            before  => Service['certcentral'],
            owner   => 'certcentral',
            group   => 'certcentral',
            mode    => '0444',
            content => $account_details['regr'],
        }
        file { "/etc/certcentral/accounts/${account_id}/private_key.pem":
            require => File["/etc/certcentral/accounts/${account_id}"],
            before  => Service['certcentral'],
            owner   => 'certcentral',
            group   => 'certcentral',
            mode    => '0400',
            content => secret("certcentral/accounts/${account_id}/private_key.pem"),
        }
    }

    $ensure = $is_active? {
        true    => 'present',
        default => 'absent',
    }
    systemd::service { 'certcentral':
        ensure         => $ensure,
        require        => Package['certcentral'],
        content        => template('certcentral/certcentral.service.erb'),
        override       => true,
        service_params => {
            restart   => '/bin/systemctl reload certcentral',
        },
    }


    cron { 'reload-certcentral-backend':
        ensure   => $ensure, # TODO: replace with https://gerrit.wikimedia.org/r/460397
        command  => '/bin/systemctl reload certcentral',
        user     => 'root',
        minute   => '0',
        hour     => '*',
        weekday  => '*',
        month    => '*',
        monthday => '*',
        require  => Service['certcentral'],
    }

    uwsgi::app { 'certcentral':
        settings => {
            uwsgi => {
                plugins        => 'python3',
                'wsgi-file'    => '/usr/lib/python3/dist-packages/certcentral/uwsgi.py',
                callable       => 'app',
                socket         => '/run/uwsgi/certcentral.sock',
                'chmod-socket' => 600,
            }
        },
        require  => Package['certcentral'],
    }

    base::service_auto_restart { 'uwsgi-certcentral': }

    require sslcert::dhparam
    nginx::site { 'certcentral':
        content => template('certcentral/central.nginx.conf.erb'),
        require => [
            Uwsgi::App['certcentral'],
            File['/etc/ssl/dhparam.pem'],
        ],
    }

    ferm::service { 'certcentral-api':
        proto  => 'tcp',
        port   => '8140',
        srange => '$DOMAIN_NETWORKS',
    }

    nginx::site { 'certcentral-http-challenges':
        ensure  => $http_challenge_support,
        content => template('certcentral/central-http-challenges.nginx.conf.erb'),
        require => Package['certcentral'],
    }
    ferm::service { 'certcentral-http-challenges':
        ensure => $http_challenge_support,
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    $ensure_passive = (!$is_active)? {
        true    => present,
        default => absent,
    }
    ferm::service { 'certcentral-ssh-rsync':
        ensure => $ensure_passive,
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${active_host})) @resolve((${active_host}), AAAA))",
    }

    keyholder::agent { 'authdns_certcentral':
        trusted_groups => ['certcentral'],
    }
    file { '/usr/local/bin/certcentral-gdnsd-sync.py':
        ensure  => present,
        owner   => 'certcentral',
        group   => 'certcentral',
        mode    => '0544',
        source  => 'puppet:///modules/certcentral/gdnsd-sync.py',
        require => Package['certcentral'],
    }

    file { '/usr/local/bin/certcentral-certs-sync':
        ensure => present,
        owner  => 'certcentral',
        group  => 'certcentral',
        mode   => '0544',
        source => 'puppet:///modules/certcentral/certs-sync',
    }

    $cc_backend_process = $is_active? {
        true    => '1:1',
        default => '0:0',
    }
    nrpe::monitor_service { 'certcentral_backend':
        description  => 'Ensure certcentral-backend is running only in the active node',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c ${cc_backend_process} -a certcentral-backend",
        require      => Package['certcentral'],
    }

    nrpe::monitor_service { 'certcentral_api':
        description  => 'Ensure certcentral-api is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/uwsgi --die-on-term --ini /etc/uwsgi/apps-enabled/certcentral.ini'",
        require      => Package['certcentral'],
    }

    sudo::user { 'nagios_certcentral_fileage_checks':
        user       => 'nagios',
        privileges => ['ALL = (certcentral) NOPASSWD: /usr/lib/nagios/plugins/check_file_age'],
    }

    nrpe::monitor_service { 'cert_sync_active_node':
        ensure       => $ensure,
        description  => 'Ensure cert-sync script runs successfully in the active node',
        nrpe_command => "sudo -u certcentral /usr/lib/nagios/plugins/check_file_age -w 3600 -c 7200 ${live_certs_path}/.rsync.done",
    }

    nrpe::monitor_service { 'cert_sync_passive_node':
        ensure       => $ensure_passive,
        description  => 'Ensure that passive node gets the certificates from the active node as expected',
        nrpe_command => "sudo -u certcentral /usr/lib/nagios/plugins/check_file_age -w 3600 -c 7200 ${live_certs_path}/.rsync.status",
    }

    if $is_active {
        exec { '/usr/local/bin/certcentral-certs-sync':
            user    => 'certcentral',
            timeout => 60,
            require => [User['certcentral'], File['/etc/certcentral/cert-sync.conf']],
        }
    }
}
