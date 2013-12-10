# setup Bugzilla instance for WMF
# also see README.md

class bugzilla {

    file { [ '/srv/org','/srv/org/wikimedia','/srv/org/wikimedia/bugzilla']:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

    # basic apache site and certs
    class {'bugzilla::apache':
        svc_name        => 'bugzilla.wikimedia.org',
        attach_svc_name => 'bug-attachment.wikimedia.org',
        docroot         => '/srv/org/wikimedia/bugzilla/',
    }

    # community metrics mail
    bugzilla::logmail {'communitymetrics':
        script_name  => 'bugzilla_community_metrics.sh',
        rcpt_address => 'communitymetrics@wikimedia.org',
        sndr_address => '3962@rt.wikimedia.org',
        monthday     => '1',
    }

    # audit log mail for admins
    bugzilla::logmail {'auditlog':
        script_name  => 'bugzilla_audit_log.sh',
        rcpt_address => 'bugzilla-admin@wikimedia.org',
        sndr_address => '4802@rt.wikimedia.org',
        monthday     => '*',
    }

    # bugzilla reporter PHP script
    class {'bugzilla::reporter':
        bz_report_user => 'reporter',
    }


    # whining - http://www.bugzilla.org/docs/tip/en/html/whining.html
    $bz_path = '/srv/org/wikimedia/bugzilla'
    $whine = 'whine.pl'

    cron { 'bugzilla_whine':
        command => "${bz_path}/${whine}",
        user    => 'root',
        minute  => '15',
    }

    # 2 cron jobs to generate charts data
    # See https://bugzilla.wikimedia.org/29203
    $collectstats = 'collectstats.pl'

    # 1) get statistics for the day:
    cron { 'bugzilla_collectstats':
        command => "${bz_path}/${collectstats}",
        user    => 'root',
        hour    => '0',
        minute  => '5',
        weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
    }

    # 2) on sunday, regenerates the whole statistics data
    cron { 'bugzilla_collectstats_regenerate':
        command => "${bz_path}/${collectstats} --regenerate",
        user    => root,
        hour    => 0,
        minute  => 5,
        weekday => 0  # Sunday
    }

}
