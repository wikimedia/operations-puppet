# vim: set ts=4 et sw=4:               =>
# role/otrs.pp

class role::otrs (
        $otrs_database_host = 'm2-master.eqiad.wmnet',
        $otrs_database_name = 'otrs',
    ) {

    system::role { 'role::otrs::webserver':
        description => 'OTRS Web Application Server',
    }

    include standard-noexim
    include webserver::apache
    include network::constants
    include passwords::mysql::otrs

    $otrs_database_user = $::passwords::mysql::otrs::user
    $otrs_database_pw   = $::passwords::mysql::otrs::pass

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    ferm::service { 'otrs_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'otrs_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'otrs_smtp':
        proto  => 'tcp',
        port   => '25',
        srange => '($EXTERNAL_NETWORKS)',
    }

    user { 'otrs':
        home       => '/var/lib/otrs',
        groups     => 'www-data',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    $packages = [
        'libapache-dbi-perl',
        'libdbd-mysql-perl',
        'libgd-graph-perl',
        'libgd-text-perl',
        'libio-socket-ssl-perl',
        'libjson-xs-perl',
        'libnet-dns-perl',
        'libnet-ldap-perl',
        'libpdf-api2-perl',
        'libsoap-lite-perl',
        'libtext-csv-xs-perl',
        'libtimedate-perl',
        'mysql-client',
        'perl-doc',
    ]

    package { $packages:
        ensure => 'present',
    }

    file { '/opt/otrs/Kernel/Config.pm':
        ensure  => 'file',
        owner   => 'otrs',
        group   => 'www-data',
        mode    => '0440',
        content => template('otrs/Config.pm.erb'),
    }

    apache::site { 'ticket.wikimedia.org':
        content => template('apache/sites/ticket.wikimedia.org.erb'),
    }

    file { '/etc/cron.d/otrs':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/otrs/crontab.otrs',
    }

    file { '/var/spool/spam':
        ensure => 'directory',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0775',
    }

    file { '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///files/otrs/otrs.TicketExport2Mbox.pl',
    }

    file { '/opt/otrs/bin/cgi-bin/idle_agent_report':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///files/otrs/idle_agent_report',
    }

    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///files/otrs/wmf.ico',
    }

    file { '/usr/local/bin/train_spamassassin':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/otrs/train_spamassassin',
    }

    file { '/opt/otrs/Kernel/Output/HTML/OTRS':
        ensure => link,
        target => '/opt/otrs/Kernel/Output/HTML/Standard',
    }

    install_certificate{ 'ticket.wikimedia.org': ca => 'RapidSSL_CA.pem' }
    include ::apache::mod::perl
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    include ::apache::mod::headers

    include clamav
    class { 'spamassassin':
        required_score        => '3.5',# (5.0)
        use_bayes             => '1',  # 0|(1)
        bayes_auto_learn      => '0',  # 0|(1)
        short_report_template => true, # true|(false)
        trusted_networks      => $network::constants::all_networks,
        custom_scores         => {
            'RP_MATCHES_RCVD'   => '-0.500',
            'SPF_SOFTFAIL'      => '2.000',
            'SUSPICIOUS_RECIPS' => '2.000',
            'DEAR_SOMETHING'    => '1.500',
        },
        debug_logging         => '--debug spf',
    }

    # warning: don't unquote these booleans until exim::roled is fixed
    class { 'exim::roled':
        local_domains        => [
            '+system_domains',
            '+wikimedia_domains',
            ],
        enable_clamav        => true,
        enable_otrs_server   => true,
        enable_spamassassin  => true,
        enable_external_mail => false,
        smart_route_list     => $::mail_smarthost,
    }

    Class['spamassassin'] -> Class['exim::roled']
    Class['clamav'] -> Class['exim::roled']

    cron { 'otrs_train_spamassassin':
        ensure  => 'present',
        user    => 'root',
        minute  => '5',
        command => '/usr/local/bin/train_spamassassin',
    }

    monitor_service { 'smtp':
        description   => 'OTRS SMTP',
        check_command => 'check_smtp',
    }

    monitor_service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_cert!ticket.wikimedia.org',
    }

    monitor_ganglia { 'exim_messages_in':
        ensure                => 'present',
        description           => 'exim incoming message rate',
        metric                => 'exim_messages_in',
        contact_group         => 'admins',
        warning               => ':1',
        critical              => ':0.9',
        normal_check_interval => '30',
        retry_check_interval  => '1',
        retries               => '60',
        require               => Class['exim4::ganglia'],
    }

}
