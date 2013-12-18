# Bugzilla module for Wikimedia
#
# this module sets up parts of a custom
# Bugzilla installation for Wikimedia
#
# production: https://bugzilla.wikimedia.org
# labs/testing: https://wikitech.wikimedia.org/wiki/Nova Resource:Bugzilla
# docs: http://wikitech.wikimedia.org/view/Bugzilla
#
# requirements: a basic Apache setup on the node
#              class {'webserver::php5': ssl => true; }
#
# this sets up:
#
# - the apache site config
# - the SSL certs
# - the /srv/org/wikimedia dir
# - the bugzilla localconfig file
# - cronjobs and scripts:
#  - auditlog mail for bz admins, bash
#  - mail report for community metrics, bash
#  - whine / collectstats statistics, perl
#  - bugzilla reporter, php
#
# you still have to copy upstream bugzilla itself
# to the bugzilla path and clone our modifications
# from the wikimedia/bugzilla/modifcations repo
#
class bugzilla ( $db_host, $db_name, $db_user ) {

    # document root
    file { [ '/srv/org','/srv/org/wikimedia','/srv/org/wikimedia/bugzilla']:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

    # bugzilla localconfig
    file { '/srv/org/wikimedia/bugzilla/localconfig':
        ensure  => present,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => template('bugzilla/localconfig.erb'),
    }

    # basic apache site and certs
    class {'bugzilla::apache':
        svc_name        => 'bugzilla.wikimedia.org',
        attach_svc_name => 'bug-attachment.wikimedia.org',
        docroot         => '/srv/org/wikimedia/bugzilla/',
    }

    # perl modules
    package { 'libdatetime-perl':
        ensure => present;
    }

    # community metrics mail
    #bugzilla::logmail {'communitymetrics':
    #    script_name  => 'bugzilla_community_metrics.sh',
    #    rcpt_address => 'communitymetrics@wikimedia.org',
    #    sndr_address => '3962@rt.wikimedia.org',
    #    monthday     => '1',
    #}

    # audit log mail for admins
    #bugzilla::logmail {'auditlog':
    #    script_name  => 'bugzilla_audit_log.sh',
    #    rcpt_address => 'bugzilla-admin@wikimedia.org',
    #    sndr_address => '4802@rt.wikimedia.org',
    #    monthday     => '*',
    #}

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
