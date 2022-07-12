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

    # PAWS cert is separate and the host is defined in icinga::monitor::toollabs
    monitoring::service { 'https_paws':
        description   => 'HTTPS-paws',
        check_command => 'check_ssl_http_letsencrypt!paws.wmcloud.org',
        host          => 'paws.wmcloud.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Acme-chief/Cloud_VPS_setup#Troubleshooting',
        contact_group => 'team-paws',
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
