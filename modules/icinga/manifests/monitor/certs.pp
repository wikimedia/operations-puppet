# = Class: icinga::monitor::certs
# monitoring for SSL cert expiry for services that are not
# associated with a single host via a role class but are either
# external or live on a cluster. T114059
class icinga::monitor::certs {

    # blog.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'blog.wikimedia.org':
        host_fqdn     => 'blog.wikimedia.org',
    }
    monitoring::service { 'https_blog':
        description   => 'HTTPS-blog',
        check_command => 'check_ssl_http_letsencrypt!blog.wikimedia.org',
        host          => 'blog.wikimedia.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/wikimedia-blog/',
    }

    # policy.wikimedia.org (external, Wordpress/Automattic)
    @monitoring::host { 'policy.wikimedia.org':
        host_fqdn     => 'policy.wikimedia.org',
    }
    monitoring::service { 'https_policy':
        description   => 'HTTPS-policy',
        check_command => 'check_ssl_http_letsencrypt!policy.wikimedia.org',
        host          => 'policy.wikimedia.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/wmf-legal/',
    }

    monitoring::service { 'https_toolserver':
        description   => 'HTTPS-toolserver',
        check_command => 'check_ssl_http_letsencrypt!www.toolserver.org',
        host          => 'www.toolserver.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/toolforge/',
    }

    # *.wmflabs.org (labs wildcard cert, testing tools.wmflabs.org)
    monitoring::service { 'https_wmflabs':
        description   => 'HTTPS-wmflabs',
        check_command => 'check_ssl_http!tools.wmflabs.org',
        host          => 'tools.wmflabs.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/toolforge/',
    }

    # *.wmfusercontent.org (wildcard cert, testing phab.wmfusercontent.org)
    @monitoring::host { 'phab.wmfusercontent.org':
        host_fqdn     => 'phab.wmfusercontent.org',
    }
    monitoring::service { 'https_wmfusercontent':
        description   => 'HTTPS-wmfusercontent',
        check_command => 'check_ssl_http!phab.wmfusercontent.org',
        host          => 'phab.wmfusercontent.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/phabricator/',
    }

    # wikitech-static.wikimedia.org (external, Rackspace)
    @monitoring::host { 'wikitech-static.wikimedia.org':
        host_fqdn     => 'wikitech-static.wikimedia.org',
        contact_group => 'wmcs-bots,admins',
    }
    monitoring::service { 'https_wikitech-static':
        description   => 'HTTPS-wikitech-static',
        check_command => 'check_ssl_http_letsencrypt!wikitech-static.wikimedia.org',
        host          => 'wikitech-static.wikimedia.org',
        contact_group => 'wmcs-bots,admins',
        notes_url     => 'https://phabricator.wikimedia.org/project/view/2773/',
    }

    monitoring::service { 'https_status-wikimedia':
        description   => 'HTTPS-status-wikimedia-org',
        check_command => 'check_ssl_http_letsencrypt!status.wikimedia.org',
        host          => 'wikitech-static.wikimedia.org',
        contact_group => 'wikitech-static',
        notes_url     => 'https://phabricator.wikimedia.org/project/view/2773/',
    }
}
