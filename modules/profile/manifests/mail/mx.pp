# @summary profile to configure exim on mx hosts
# @param prometheus_nodes The set of Prometheus servers which will query for metrics
# @param dkim_domain Configure dkim for this domain
# @param verp_domains configure verp for theses domains
# @param verp_post_connect_server the server to post verp bounces too
# @param verp_bounce_post_url the url top post verp bounces to
class profile::mail::mx (
    Array[Stdlib::Host]   $prometheus_nodes         = lookup('prometheus_nodes'),
    Stdlib::Host          $gmail_smtp_server        = lookup('profile::mail::mx::gmail_smtp_server'),
    Stdlib::Host          $otrs_mysql_server        = lookup('profile::mail::mx::otrs_mysql_server'),
    Stdlib::Host          $otrs_mysql_user          = lookup('profile::mail::mx::otrs_mysql_user'),
    Stdlib::Host          $otrs_mysql_dbname        = lookup('profile::mail::mx::otrs_mysql_dbname'),
    Stdlib::Host          $dkim_domain              = lookup('profile::mail::mx::dkim_domain'),
    Array[Stdlib::Host]   $verp_domains             = lookup('profile::mail::mx::verp_domains'),
    Stdlib::Host          $verp_post_connect_server = lookup('profile::mail::mx::verp_post_connect_server'),
    String[1]             $verp_bounce_post_url     = lookup('profile::mail::mx::verp_bounce_post_url'),
) {
    mailalias { 'root':
        recipient => 'root@wikimedia.org',
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

    # Exim 4.94 introduces a new tainting mechanism. We're not adapting our configs
    # to his new scheme since the mail servers will be switched to Postfix anyway
    if debian::codename::eq('bullseye') {
        $disable_taint_check = true
    }

    class { 'exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.mx.erb'),
        filter  => template('role/exim/system_filter.conf.erb'),
        require => Class['spamassassin'],
    }

    file { "${exim4::config_dir}/defer_domains":
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        require => Class['exim4'],
    }

    $wikimedia_domains_path = "${exim4::config_dir}/wikimedia_domains"
    file { $wikimedia_domains_path:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/wikimedia_domains',
        require => Class['exim4'],
    }

    file { "${exim4::config_dir}/legacy_mailing_lists":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/legacy_mailing_lists',
        require => Class['exim4'],
    }

    file { "${exim4::config_dir}/bounce_message_file":
        ensure => present,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0444',
        source => 'puppet:///modules/role/exim/bounce_message_file',
    }
    file { "${exim4::config_dir}/warn_message_file":
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
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mail#Troubleshooting',
    }

    ferm::service { 'exim-smtp':
        proto => 'tcp',
        port  => '25',
    }

    # mails the wikimedia.org mail alias file to OIT once per week
    $alias_file = "${exim4::aliases_dir}/wikimedia.org"
    $recipient  = 'its@wikimedia.org'
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

    sudo::user { 'nagios_exim_queue':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/exipick -bpc -o [[\:digit\:]][[\:digit\:]][mh]'],
    }

    nrpe::monitor_service { 'check_exim_queue':
        description    => 'exim queue',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_exim_queue -w 2000 -c 4000',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 20,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Exim',
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

    ensure_packages(['python3-pymysql'])
    $otrs_aliases_file = '/etc/exim4/otrs_emails'
    file { "${exim4::config_dir}/otrs.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        content => template('profile/mail/mx/otrs.conf.erb')
    }
    file {'/usr/local/bin/otrs_aliases':
        ensure => file,
        owner  => 'root',
        group  => 'Debian-exim',
        mode   => '0550',
        source => 'puppet:///modules/profile/mail/otrs_aliases.py',
    }
    systemd::timer::job {'generate_otrs_aliases':
        ensure        => 'present',
        description   => 'Generate OTRS aliases file for Exim',
        command       => '/usr/local/bin/otrs_aliases',
        user          => 'root',
        ignore_errors => true,
        # We should set this to true once T284145 is resolved
        send_mail     => false,
        interval      => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
    }
}
