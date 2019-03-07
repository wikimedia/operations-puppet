# = Class: icinga::monitor::gerrit
#
# Monitor Gerrit (T215033)
class icinga::monitor::gerrit {

    @monitoring::host { 'gerrit.wikimedia.org':
        host_fqdn => 'gerrit.wikimedia.org',
    }

    monitoring::service { 'gerrit-healthcheck':
        description   => 'Gerrit Health Check',
        check_command => 'check_https_url!gerrit.wikimedia.org!"/r/config/server/healthcheck~status"',
        contact_group => 'admins,gerrit',
        host          => 'gerrit.wikimedia.org',
        notes_url     => 'https://gerrit.wikimedia.org/r/config/server/healthcheck~status',
    }

    monitoring::service { 'gerrit-json':
        description   => 'Gerrit JSON',
        check_command => 'check_https_url_at_address_for_minsize!gerrit.wikimedia.org!"/r/changes/?n=25&O=81"!10000',
        contact_group => 'admins,gerrit',
        host          => 'gerrit.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Gerrit#Monitoring',
    }

}
