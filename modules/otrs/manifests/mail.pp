class otrs::mail(
    $otrs_mysql_password,
    $trusted_networks,
){
    include clamav
    include exim4::ganglia

    class { 'exim4':
        variant => 'heavy',
        config  => template('otrs/exim4.conf.otrs.erb'),
        filter  => template('otrs/system_filter.conf.otrs.erb'),
        require => [
            Class['spamassassin'],
            Class['clamav'],
        ]
    }
    class { 'spamassassin':
        required_score        => '3.5',# (5.0)
        use_bayes             => '1',  # 0|(1)
        bayes_auto_learn      => '0',  # 0|(1)
        short_report_template => true, # true|(false)
        trusted_networks      => $trusted_networks,
        custom_scores         => {
            'RP_MATCHES_RCVD'   => '-0.500',
            'SPF_SOFTFAIL'      => '2.000',
            'SUSPICIOUS_RECIPS' => '2.000',
            'DEAR_SOMETHING'    => '1.500',
        },
        debug_logging         => '--debug spf',
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
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
        source  => 'puppet:///files/exim/wikimedia_domains',
        require => Class['exim4'],
    }

    file { '/usr/local/bin/train_spamassassin':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/otrs/train_spamassassin',
    }

    cron { 'otrs_train_spamassassin':
        ensure  => 'present',
        user    => 'root',
        minute  => '5',
        command => '/usr/local/bin/train_spamassassin',
    }

    file { '/var/spool/spam':
        ensure => 'directory',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0775',
    }
}
