# filtertags: labs-project-deployment-prep
class role::mail::mx(
    $verp_domains = [
        'wikimedia.org'
    ],
    $verp_post_connect_server = 'meta.wikimedia.org',
    $verp_bounce_post_url = 'api-rw.discovery.wmnet/w/api.php',
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {
    include network::constants
    include privateexim::aliases::private
    include ::base::firewall

    system::role { 'mail::mx':
        description => 'Mail router',
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    sslcert::certificate { 'mail.wikimedia.org':
        group  => 'Debian-exim',
        before => Class['exim4'],
    }

    letsencrypt::cert::integrated { $facts['hostname']:
        subjects   => $facts['fqdn'],
        key_group  => 'Debian-exim',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    class { 'nginx':
        variant => 'light',
    }

    nginx::site { 'letsencrypt-standalone':
        content => template('letsencrypt/cert/integrated/standalone.nginx.erb'),
    }

    ferm::service { 'nginx-http':
        proto => 'tcp',
        port  => '80',
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '1',
        bayes_auto_learn => '1',
        max_children     => 32,
        trusted_networks => $network::constants::all_networks,
    }

    include passwords::exim
    $otrs_mysql_password = $passwords::exim::otrs_mysql_password
    $smtp_ldap_password  = $passwords::exim::smtp_ldap_password

    class { 'exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.mx.erb'),
        filter  => template('role/exim/system_filter.conf.erb'),
        require => Class['spamassassin'],
    }

    file { '/etc/exim4/defer_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        require => Class['exim4'],
    }

    file { '/etc/exim4/wikimedia_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/wikimedia_domains',
        require => Class['exim4'],
    }

    file { '/etc/exim4/legacy_mailing_lists':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/legacy_mailing_lists',
        require => Class['exim4'],
    }

    file { '/etc/exim4/bounce_message_file':
        ensure => present,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0444',
        source => 'puppet:///modules/role/exim/bounce_message_file',
    }
    file { '/etc/exim4/warn_message_file':
        ensure => present,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0444',
        source => 'puppet:///modules/role/exim/warn_message_file',
    }

    exim4::dkim { 'wikimedia.org':
        domain   => 'wikimedia.org',
        selector => 'wikimedia',
        content  => secret('dkim/wikimedia.org-wikimedia.key'),
    }
    exim4::dkim { 'wiki-mail':
        domain   => 'wikimedia.org',
        selector => 'wiki-mail',
        content  => secret('dkim/wikimedia.org-wiki-mail.key'),
    }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls',
    }

    ferm::service { 'exim-smtp':
        proto => 'tcp',
        port  => '25',
    }

    # mails the wikimedia.org mail alias file to OIT once per week
    $alias_file = '/etc/exim4/aliases/wikimedia.org'
    $recipient  = 'officeit@wikimedia.org'
    $subject    = "wikimedia.org mail aliases from ${::hostname}"
    cron { 'mail_exim_aliases':
        user    => 'Debian-exim',
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => "/usr/bin/mail -s '${subject}' ${recipient} < ${alias_file} >/dev/null 2>&1",
    }

    # Customize logrotate settings to support longer retention (T167333)
    logrotate::conf { 'exim4-base':
        ensure => 'present',
        source => 'puppet:///modules/role/exim/logrotate/exim4-base.mx',
    }

    # monitor mail queue size (T133110)
    file { '/usr/local/lib/nagios/plugins/check_exim_queue':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/icinga/check_exim_queue.sh',
    }

    ::sudo::user { 'nagios_exim_queue':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/exipick -bpc -o [[\:digit\:]][[\:digit\:]][mh]'],
    }

    nrpe::monitor_service { 'check_exim_queue':
        description    => 'exim queue',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_exim_queue -w 1000 -c 3000',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 20,
    }

    mtail::program { 'exim':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/exim.mtail',
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    ferm::service { 'mtail':
        proto  => 'tcp',
        port   => '3903',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
