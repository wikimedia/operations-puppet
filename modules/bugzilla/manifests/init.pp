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

    # db pass and site secret from private repo
    include passwords::bugzilla

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
        svc_name        => 'old-bugzilla.wikimedia.org',
        attach_svc_name => 'bug-attachment.wikimedia.org',
        docroot         => '/srv/org/wikimedia/bugzilla/',
    }

    # Perl modules needed by Bugzilla
    # mostly per https://wiki.mozilla.org/Bugzilla:Prerequisites#Ubuntu
    package { [
        'libdatetime-perl', # manipulating dates, times and timestamps
        'libappconfig-perl', # configuration file and command line handling
        'libdate-calc-perl', # provides a variety of date calculations
        'libtemplate-perl', # template processing system
        'libmime-tools-perl', # MIME-compliant messages (formerly libmime-perl)
        'liburi-perl', # manipulate and access URI strings
        'libdatetime-timezone-perl', # framework exposing the Olson time zone database
        'libemail-send-perl', # deprecated, but we can't use libemail-sender-perl just yet
        'libemail-messageid-perl', # unique mail Message-ID generation
        'libemail-mime-perl', # for easily handling MIME-encoded messages
        'libmime-types-perl', # determining MIME types and Transfer Encoding
        'libdbi-perl', #  Perl Database Interface (DBI)
        'libdbd-mysql-perl', # Perl5 database interface to the MySQL database
        'libcgi-pm-perl', # module for CGI applications (creating/parsing web forms)
        'libmath-random-isaac-perl', # Perl interface to the ISAAC PRNG algorithm
        'libmath-random-isaac-xs-perl', # ISAAC PRNG (C/XS Accelerated) (faster)
        'libxml-twig-perl', # processing huge XML documents
        'libgd-graph-perl', # Graph Plotting Module for Perl 5
        'libchart-perl', # collection of chart creation modules (GD)
        'libjson-rpc-perl', # Perl implementation of JSON-RPC 1.1 protocol
        'libjson-xs-perl', # manipulating JSON-formatted data (C/XS-accelerated)
        'libtest-taint-perl', # test taintedness of data from an unsafe source
        'libsoap-lite-perl', # SOAP client and server
        'libtemplate-plugin-gd-perl', # GD plugin(s) for the Template Toolkit
        'libhtml-scrubber-perl', # scrubbing/sanitizing HTML
        'libencode-detect-perl', # detects the encoding of data
        'libtheschwartz-perl', # reliable job queue
        'libapache2-mod-perl2', # Apache2 Perl ('400% to 2000% speed increase':)
        'graphviz', # graph drawing tools
        ]: ensure => present,
    }

    # community metrics mail (T81784)
    bugzilla::logmail {'communitymetrics':
        script_name  => 'bugzilla_community_metrics.sh',
        rcpt_address => 'communitymetrics@wikimedia.org',
        sndr_address => 'bugzilla-daemon@wikimedia.org',
        monthday     => '1',
    }

    # audit log mail for admins (T82310)
    bugzilla::logmail {'auditlog':
        script_name  => 'bugzilla_audit_log.sh',
        rcpt_address => 'bugzilla-admin@wikimedia.org',
        sndr_address => 'bugzilla-daemon@wikimedia.org',
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
        ensure  => 'absent',
        command => "cd ${bz_path}; ./${whine}",
        user    => 'root',
        minute  => '15',
    }

    # 2 cron jobs to generate charts data
    # See https://bugzilla.wikimedia.org/29203
    $collectstats = 'collectstats.pl'

    # 1) get statistics for the day:
    cron { 'bugzilla_collectstats':
        ensure  => 'absent',
        command => "cd ${bz_path}; ./${collectstats} > /dev/null 2>&1",
        user    => 'root',
        hour    => '0',
        minute  => '5',
        weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
    }

    # 2) on sunday, regenerates the whole statistics data
    cron { 'bugzilla_collectstats_regenerate':
        ensure  => 'absent',
        command => "cd ${bz_path}; ./${collectstats} --regenerate > /dev/null 2>&1",
        user    => root,
        hour    => 0,
        minute  => 5,
        weekday => 0  # Sunday
    }

}
