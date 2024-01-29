class profile::toolforge::mailrelay (
    String         $external_hostname = lookup('profile::toolforge::mailrelay::external_hostname', {'default_value' => 'mail.tools.wmcloud.org'}),
    String         $srs_secret        = lookup('profile::toolforge::mailrelay::srs_secret',        {'default_value' => 'dummy'}),
    String         $primary_domain    = lookup('profile::toolforge::mail_domain',                  {'default_value' => 'toolforge.org'}),
    Array[String]  $mail_domains      = lookup('profile::toolforge::mail_domains',                 {'default_value' => ['tools.wmflabs.org', 'toolforge.org']}),
    String         $cert_name         = lookup('profile::toolforge::cert_name',                    {'default_value' => 'tools_mail'}),
) {
    acme_chief::cert { $cert_name:
        key_group  => 'Debian-exim',
        puppet_rsc => Service['exim4'],
    }

    class { '::spamassassin':
        required_score   => '4.0',
        use_bayes        => '1',
        bayes_auto_learn => '1',
        max_children     => 32,
        trusted_networks => ['255.255.255.255/32'], # hope this means 'nothing is trusted'
    }

    # This is using profile::base as a Puppet class applied to all hosts.
    # The query is done against the project-specific PuppetDB server so
    # everything works fine.
    $all_toolforge_servers = wmflib::class::ips('profile::base')

    class { '::exim4':
        queuerunner => 'combined',
        config      => template('profile/toolforge/mail-relay.exim4.conf.erb'),
        filter      => template('profile/toolforge/mail-relay-spam-filter.conf.erb'),
        variant     => 'heavy',
        require     => File['/usr/local/sbin/localuser',
                            '/usr/local/sbin/maintainers'],
    }

    ['toolforge', 'toolforge-rsa'].each |String[1] $dkim_selector| {
        exim4::dkim { "${primary_domain}-${dkim_selector}":
            domain   => $primary_domain,
            selector => $dkim_selector,
            content  => secret("dkim/wmcs/${primary_domain}-${dkim_selector}.key"),
        }
    }

    # Manually maintained outbound sender blocklist
    file { '/etc/exim4/deny_senders.list':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        replace => false,
        content => '# Add MAIL FROM address to block. One per line',
        require => Package['exim4-config'],
        notify  => Service['exim4'],
    }

    file { '/etc/exim4/ratelimits':
        ensure  => directory,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0550',
        require => Package['exim4-config'],
    }

    file { '/etc/exim4/ratelimits/sender_hourly_limits':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        require => File['/etc/exim4/ratelimits'],
        source  => 'puppet:///modules/profile/toolforge/mailrelay/sender_hourly_limits',
    }

    file { '/etc/exim4/ratelimits/host_hourly_limits':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        require => File['/etc/exim4/ratelimits'],
        source  => 'puppet:///modules/profile/toolforge/mailrelay/host_hourly_limits',
    }

    file { '/usr/local/sbin/localuser':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/mailrelay/localuser',
    }

    file { '/usr/local/sbin/maintainers':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/mailrelay/maintainers',
    }

    file { '/usr/local/sbin/match-tool-alias':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/mailrelay/match-tool-alias.py',
    }

    file { '/etc/aliases':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/toolforge/mailrelay/aliases',
    }

    # prometheus exim monitoring using mtail
    mtail::program { 'exim':
        ensure => present,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/exim.mtail',
    }

    # to know about the exim queue length
    class { 'prometheus::node_exim_queue':
        ensure => present,
    }
}
