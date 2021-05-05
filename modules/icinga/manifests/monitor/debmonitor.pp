# = Class: icinga::monitor::debmonitor
#
# Monitor Debmonitor (T215033)
class icinga::monitor::debmonitor {

    @monitoring::host { 'debmonitor.wikimedia.org':
        host_fqdn => 'debmonitor.wikimedia.org',
    }

    monitoring::service { 'debmonitor-healthcheck':
        description   => 'Debmonitor Health Check',
        check_command => 'check_https_redirect!443!debmonitor.wikimedia.org!/!302!https://idp.wikimedia.org/',
        contact_group => 'admins',
        host          => 'debmonitor.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debmonitor',
    }

}
