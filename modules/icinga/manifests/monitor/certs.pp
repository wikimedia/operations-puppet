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

    # toolforge.org and wmcloud.org wildcard certs
    @monitoring::host { 'admin.toolforge.org':
        host_fqdn     => 'admin.toolforge.org',
        contact_group => 'wmcs-bots',
    }
    monitoring::service { 'https_toolforge':
        description   => 'HTTPS-toolforge',
        check_command => 'check_ssl_http_letsencrypt!admin.toolforge.org',
        host          => 'admin.toolforge.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Acme-chief/Cloud_VPS_setup#Troubleshooting',
        contact_group => 'wmcs-team',
    }

    @monitoring::host { 'codesearch.wmcloud.org':
        host_fqdn     => 'codesearch.wmcloud.org',
        contact_group => 'wmcs-bots',
    }
    monitoring::service { 'https_vpsproxy':
        description   => 'HTTPS-cloud-vps-proxy',
        check_command => 'check_ssl_http_letsencrypt!codesearch.wmcloud.org',
        host          => 'codesearch.wmcloud.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Acme-chief/Cloud_VPS_setup#Troubleshooting',
        contact_group => 'wmcs-team-email',
    }

    # *.wmfusercontent.org (wildcard cert, testing phab.wmfusercontent.org)
    @monitoring::host { 'phab.wmfusercontent.org':
        host_fqdn     => 'phab.wmfusercontent.org',
    }
    monitoring::service { 'https_wmfusercontent':
        description   => 'HTTPS-wmfusercontent',
        check_command => 'check_ssl_http_letsencrypt!phab.wmfusercontent.org',
        host          => 'phab.wmfusercontent.org',
        notes_url     => 'https://phabricator.wikimedia.org/tag/phabricator/',
    }
}
