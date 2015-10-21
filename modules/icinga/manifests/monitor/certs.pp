# = Class: icinga::monitor::certs
# monitoring for SSL cert expiry for services that are not
# associated with a single host via a role class but are either
# external or live on a cluster.
class icinga::monitor::certs {

    @monitoring::host { 'virtual-ssl-host':
        host_fqdn => 'icinga.wikimedia.org'
    }

    # blog.wikimedia.org (external, Wordpress/Automattic)
    monitoring::service { 'https_blog':
        description   => 'HTTPS-blog',
        check_command => 'check_ssl_http!blog.wikimedia.org',
        host          => 'virtual-ssl-host',
    }

    # policy.wikimedia.org (external, Wordpress/Automattic)
    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http!policy.wikimedia.org',
        host          => 'virtual-ssl-host',
    }

    # eventdonations.wikimedia.org (Fundraising)
    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http!eventdonations.wikimedia.org',
        host          => 'virtual-ssl-host',
    }

    # toolserver.org (redirect page to Tool Labs)
    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http!www.toolserver.org',
        host          => 'virtual-ssl-host',
    }

}
