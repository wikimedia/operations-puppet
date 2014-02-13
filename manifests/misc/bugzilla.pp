# Bugzilla server - http://wikitech.wikimedia.org/view/Bugzilla

class misc::bugzilla::server {

    system::role { 'misc::bugzilla::server': description => 'Bugzilla server' }

    class {'webserver::php5': ssl => true; }

    install_certificate{ 'bugzilla.wikimedia.org': }
    install_certificate{ 'bug-attachment.wikimedia.org': }

    apache_site { 'bugzilla': name => 'bugzilla.wikimedia.org' }

    file {
        '/etc/apache2/sites-available/bugzilla.wikimedia.org':
            ensure  => present,
            source  => 'puppet:///files/apache/sites/bugzilla.wikimedia.org',
            owner   => 'root',
            group   => 'www-data',
            mode    => '0444';
    }

    file { [ '/srv/org','/srv/org/wikimedia','/srv/org/wikimedia/bugzilla']:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

}

class misc::bugzilla::crons {
    cron { 'bugzilla_whine':
        command => 'cd /srv/org/wikimedia/bugzilla/ ; ./whine.pl',
        user    => root,
        minute  => 15
    }

    # 2 cron jobs to generate charts data
    # See https://bugzilla.wikimedia.org/29203
    # 1) get statistics for the day:
    cron { 'bugzilla_collectstats':
        command => 'cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl',
        user    => root,
        hour    => 0,
        minute  => 5,
        weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
    }
    # 2) on sunday, regenerates the whole statistics data
    cron { 'bugzilla_collectstats_regenerate':
        command => 'cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl --regenerate',
        user    => root,
        hour    => 0,
        minute  => 5,
        weekday => 0  # Sunday
    }
}

# RT-3962 - mail bz user stats to community metrics
class misc::bugzilla::communitymetrics {

    file { 'bugzilla_communitymetrics_file':
        path    => '/srv/org/wikimedia/bugzilla/bugzilla_community_metrics.sh',
        owner   => root,
        group   => www-data,
        mode    => '0550',
        source  => 'puppet:///files/bugzilla/bugzilla_community_metrics.sh',
        ensure  => present,
    }

    cron { 'bugzilla_communitymetrics_cron':
        command     => 'cd /srv/org/wikimedia/bugzilla/ ; ./bugzilla_community_metrics.sh',
        user        => www-data,
        hour        => 0,
        minute      => 0,
        monthday    => 1,
    }
}

# RT-4802 - mail bz audit_log to bugzilla admins
class misc::bugzilla::auditlog {

    file { 'bugzilla_auditlog_file':
        path   => '/srv/org/wikimedia/bugzilla/bugzilla_audit_log.sh',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0550',
        source => 'puppet:///files/bugzilla/bugzilla_audit_log.sh',
        ensure => present,
    }

    cron { 'bugzilla_auditlog_cron':
        command => 'cd /srv/org/wikimedia/bugzilla/ ; ./bugzilla_audit_log.sh',
        user    => 'www-data',
        hour    => 0,
        minute  => 0,
    }
}
