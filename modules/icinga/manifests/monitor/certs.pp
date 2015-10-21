# = Class: icinga::monitor::certs
# monitoring for SSL cert expiry for services that are not
# associated with a single host via a role class but are either
# external or live on a cluster.
class icinga::monitor::certs {

    # blog.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'blog.wikimedia.org':
        host_fqdn => 'blog.wikimedia.org'
    }

    monitoring::service { 'https_blog':
        description   => 'HTTPS-blog',
        check_command => 'check_ssl_http!blog.wikimedia.org',
        host          => 'blog.wikimedia.org',
    }

    # policy.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'policy.wikimedia.org':
        host_fqdn => 'policy.wikimedia.org'
    }

    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http!policy.wikimedia.org',
        host          => 'policy.wikimedia.org',
    }
}
