class profile::mail::mx (
    $verp_domains             = hiera('profile::mail::mx::verp_domains'),
    $verp_post_connect_server = hiera('profile::mail::mx::verp_post_connect_server'),
    $verp_bounce_post_url     = hiera('profile::mail::mx::verp_bounce_post_url'),
    $prometheus_nodes         = hiera('prometheus_nodes', []),
    $cert_name                = hiera('profile::mail::mx::cert_name', $facts['hostname']),
    $cert_subjects            = hiera('profile::mail::mx::cert_subjects', $facts['fqdn']),
    $dkim_domain              = hiera('profile::mail::mx::dkim_domain', 'wikimedia.org'),
) {
    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    certcentral::cert { 'mx':
        puppet_svc => undef,
        key_group  => 'Debian-exim',
    }
    acme_chief::cert { 'mx':
        puppet_svc => undef,
        key_group  => 'Debian-exim',
    }

    $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
        $x !~ /127.0.0.0|::1/
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '1',
        bayes_auto_learn => '1',
        max_children     => 32,
        trusted_networks => $trusted_networks,
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
        domain   => $dkim_domain,
        selector => 'wikimedia',
        content  => secret("dkim/${dkim_domain}-wikimedia.key"),
    }
    exim4::dkim { 'wiki-mail':
        domain   => $dkim_domain,
        selector => 'wiki-mail',
        content  => secret("dkim/${dkim_domain}-wiki-mail.key"),
    }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
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
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/exim.mtail',
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    ferm::service { 'mtail':
        proto  => 'tcp',
        port   => '3903',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
