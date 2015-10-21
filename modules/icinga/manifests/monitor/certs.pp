# = Class: icinga::monitor::certs
# monitoring for SSL cert expiry for services that are not
# associated with a single host via a role class but are either
# external or live on a cluster. T114059
class icinga::monitor::certs {

    # blog.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'blog.wikimedia.org':
        host_fqdn     => 'blog.wikimedia.org'
    }
    monitoring::service { 'https_blog':
        description   => 'HTTPS-blog',
        check_command => 'check_ssl_http!blog.wikimedia.org',
        host          => 'blog.wikimedia.org',
    }

    # policy.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'policy.wikimedia.org':
        host_fqdn     => 'policy.wikimedia.org'
    }
    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http!policy.wikimedia.org',
        host          => 'policy.wikimedia.org',
    }

    # eventdonations.wikimedia.org (Fundraising)
    @monitoring::host { 'eventdonations.wikimedia.org':
        host_fqdn     => 'eventdonations.wikimedia.org'
    }
    monitoring::service { 'https_eventdonations':
        description   => 'HTTPS-eventdonations',
        check_command => 'check_ssl_http!eventdonations.wikimedia.org',
        host          => 'eventdonations.wikimedia.org',
    }

    # toolserver.org (redirect page to Tool Labs)
    @monitoring::host { 'www.toolserver.org':
        host_fqdn     => 'www.toolserver.org'
    }
    monitoring::service { 'https_toolserver':
        description   => 'HTTPS-toolserver',
        check_command => 'check_ssl_http!www.toolserver.org',
        host          => 'www.toolserver.org',
    }

    # *.planet.wikimedia.org (has its own wildcard cert on misc cp cluster)
    @monitoring::host { 'en.planet.wikimedia.org':
        host_fqdn     => 'en.planet.wikimedia.org'
    }
    monitoring::service { 'https_planet':
        description   => 'HTTPS-planet',
        check_command => 'check_ssl_http!en.planet.wikimedia.org',
        host          => 'en.planet.wikimedia.org',
    }

}
