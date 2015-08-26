# = Class: icinga::monitor::legal
#
class icinga::monitor::legal {

    @monitoring::host { 'en.wikipedia.org':
        host_fqdn => 'en.wikipedia.org'
    }

    @monitoring::host { 'en.m.wikipedia.org':
        ip_address => 'en.m.wikipedia.org',
    }

    monitoring::service { 'en.wp.o-legal-html':
        description           => 'Ensure mandated html',
        check_command         => 'check_legal_html!https://en.wikipedia.org/wiki/Main_Page!desktop_enwp',
        host                  => 'en.wikipedia.org',
        normal_check_interval => 1440,
        retry_check_interval  => 30,
        contact_group         => 'admins',
    }

    monitoring::service { 'en.wp.o-legal-html':
        description           => 'Ensure mandated html',
        check_command         => 'check_legal_html!https://en.m.wikipedia.org/wiki/Main_Page!mobile',
        host                  => 'en.wikipedia.org',
        normal_check_interval => 1440,
        retry_check_interval  => 30,
        contact_group         => 'admins',
    }
}
