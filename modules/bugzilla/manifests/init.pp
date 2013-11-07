# setup Bugzilla instance for WMF
# also see README.md

class bugzilla {

    # system role for motd
    system::role { 'role::bugzilla': description => 'Bugzilla server' }

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

    # whine / collectstats crons
    class {'bugzilla::crons':
        bz_path      => '/srv/org/wikimedia/bugzilla',
        whine        => 'whine.pl',
        collectstats => 'collectstats.pl',
    }

    # community metrics mail
    class {'bugzilla::communitymetrics':
        bz_path      => '/srv/org/wikimedia/bugzilla',
        script_user  => 'www-data',
        script_name  => 'bugzilla_community_metrics.sh',
        rcpt_address => 'communitymetrics@wikimedia.org',
        sndr_address => '3962@rt.wikimedia.org',
    }

    # bugzilla reporter PHP script
    class {'bugzilla::reporter':
        bz_report_user => 'reporter',
    }

    # audit log mail for admins
    class {'bugzilla::auditlog':
        bz_path      => '/srv/org/wikimedia/bugzilla',
        script_user  => 'www-data',
        script_name  => 'bugzilla_audit_log.sh',
        rcpt_address => 'bugzilla-admin@wikimedia.org',
        sndr_address => '4802@rt.wikimedia.org',
    }

}
