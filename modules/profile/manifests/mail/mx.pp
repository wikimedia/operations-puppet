# @summary profile to configure exim on mx hosts
# @param dkim_domain Configure dkim for this domain
# @param verp_domains configure verp for theses domains
# @param verp_post_connect_server the server to post verp bounces too
# @param verp_bounce_post_url the url top post verp bounces to
# @param sender_discards
#   Sender address patterns to silently discard, these patterns should conform to the Exim syntax:
#   http://www.exim.org/exim-html-current/doc/html/spec_html/ch-domain_host_address_and_local_part_lists.html
class profile::mail::mx (
    Stdlib::Host          $gmail_smtp_server        = lookup('profile::mail::mx::gmail_smtp_server'),
    Stdlib::Host          $otrs_mysql_server        = lookup('profile::mail::mx::otrs_mysql_server'),
    Stdlib::Host          $otrs_mysql_user          = lookup('profile::mail::mx::otrs_mysql_user'),
    Stdlib::Host          $otrs_mysql_dbname        = lookup('profile::mail::mx::otrs_mysql_dbname'),
    Stdlib::Host          $dkim_domain              = lookup('profile::mail::mx::dkim_domain'),
    Array[Stdlib::Host]   $verp_domains             = lookup('profile::mail::mx::verp_domains'),
    Stdlib::Host          $verp_post_connect_server = lookup('profile::mail::mx::verp_post_connect_server'),
    String[1]             $verp_bounce_post_url     = lookup('profile::mail::mx::verp_bounce_post_url'),
    Stdlib::Unixpath      $alias_file               = lookup('profile::mail::mx::alias_file'),
    String[1]             $alias_file_mail_rcpt     = lookup('profile::mail::mx::alias_file_mail_rcpt'),
    String[1]             $alias_file_mail_subject  = lookup('profile::mail::mx::alias_file_mail_subject'),
    Boolean               $enable_ldap              = lookup('profile::mail::mx::enable_ldap'),
    Array[String[1]]      $sender_discards          = lookup('profile::mail::mx::sender_discards', {'default_value' => []})
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
    $otrs_aliases_file = '/etc/exim4/otrs_emails'

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
    $disable_taint_check = true

    # enable dkim_verbose logs, needed for mtail metric collection
    $log_selector_extra = '+dkim_verbose'

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

    file { "${exim4::config_dir}/sender_discards":
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        content => $sender_discards.join("\n"),
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

    # mails the wikimedia.org mail alias file to ITS once per week
    file { '/etc/mail-exim-aliases':
        ensure  => present,
        mode    => '0444',
        content => template('profile/mail/mx/mail-exim-aliases-config.erb'),
    }

    file { '/usr/local/bin/mail-exim-aliases':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/profile/mail/mx/mail-exim-aliases.sh',
    }

    systemd::timer::job { 'mail-exim-aliases':
        ensure             => present,
        user               => 'Debian-exim',
        description        => 'send a copy of the exim alias file somewhere',
        command            => '/usr/local/bin/mail-exim-aliases',
        interval           => {'start' => 'OnCalendar', 'interval' => 'weekly'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    # Customize logrotate settings to support longer retention (T167333)
    logrotate::conf { 'exim4-base':
        ensure => 'present',
        source => 'puppet:///modules/role/exim/logrotate/exim4-base.mx',
    }

    # monitor mail queue size (T133110)
    nrpe::plugin { 'check_exim_queue':
        ensure => absent,
    }

    sudo::user { 'nagios_exim_queue':
        ensure     => absent,
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/exipick -bpc -o [[\:digit\:]][[\:digit\:]][mh]'],
    }

    class { 'prometheus::node_exim_queue':
        ensure => present,
    }

    mtail::program { 'exim':
        ensure => present,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/exim.mtail',
    }

    ensure_packages(['python3-pymysql'])
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
        ensure              => 'present',
        description         => 'Generate OTRS aliases file for Exim',
        command             => '/usr/local/bin/otrs_aliases',
        user                => 'root',
        ignore_errors       => true,
        # We should set this to true once T284145 is resolved
        send_mail           => false,
        interval            => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        max_runtime_seconds => 1800,
    }

    ensure_packages(['swaks'])
}
