# = Class: icinga::monitor::gerrit
#
# Monitor Gerrit (T215033)
class icinga::monitor::gerrit {

    @monitoring::host { 'gerrit.wikimedia.org':
        host_fqdn => 'gerrit.wikimedia.org',
    }

    monitoring::service {
        default:
            contact_group => 'admins,gerrit',
            host          => 'gerrit.wikimedia.org',
            notes_url     => 'https://gerrit.wikimedia.org/r/config/server/healthcheck~status';
        'gerrit-healthcheck':
            description   => 'Gerrit Health Check',
            check_command => 'check_https_url!gerrit.wikimedia.org!"/r/config/server/healthcheck~status"';
        'gerrit-json':
            description   => 'Gerrit JSON',
            check_command => 'check_https_url_at_address_for_minsize!gerrit.wikimedia.org!/r/changes/?n=25&O=81!10000';
        'gerrit-healthcheck-expiry':
            description   => 'Gerrit Health Check SSL Expiry',
            check_command => 'check_https_expiry!gerrit.wikimedia.org!443';
    }
}
