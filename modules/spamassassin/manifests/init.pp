# SpamAssassin http://spamassassin.apache.org/

class spamassassin(
    $required_score = '5.0',
    $max_children = 8,
    $nicelevel = 10,
    $use_bayes = 1,
    $bayes_auto_learn = 1,
    $short_report_template = false,
    $otrs_rule_scores = false,
    $spamd_user  = 'spamd',
    $spamd_group = 'spamd'
) {
    include network::constants

    package { 'spamassassin':
        ensure => latest,
    }

    # this seems broken, especially since /var/spamd is unused
    # and spamd's homedir is created as /var/lib/spamd
    if ( $spamd_user == 'spamd' ) {
        generic::systemuser { 'spamd': name => 'spamd' }
        file { '/var/spamd':
            ensure  => directory,
            owner   => 'spamd',
            group   => 'spamd',
            mode    => '0700',
            require => Generic::Systemuser['spamd'],
        }
    }

    File {
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['spamassassin'],
    }
    file { '/etc/spamassassin/local.cf':
        content => template('spamassassin/local.cf'),
    }
    file { '/etc/default/spamassassin':
        content => template('spamassassin/spamassassin.default.erb'),
    }

    service { 'spamassassin':
        ensure    => running,
        require   => [
            File['/etc/default/spamassassin'],
            File['/etc/spamassassin/local.cf'],
            Package['spamassassin']
        ],
        subscribe => [
            File['/etc/default/spamassassin'],
            File['/etc/spamassassin/local.cf']
        ],
    }

    nrpe::monitor_service { 'spamd':
        description   => 'spamassassin',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 1:20 -c 1:40 -a spamd',
    }
}
