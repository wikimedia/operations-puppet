
class profile::waf::apache2::administrative {

    # Not using require_package so apt::pin may be applied
    # before attempting to install package.
    package { 'libapache2-mod-security2':
        ensure => absent,
    }

    # Ensure that the CRS modsecurity ruleset is not used.
    file { '/etc/apache2/mods-available/security2.conf':
        ensure  => absent,
    }

    httpd::conf { 'modsecurity_admin':
        ensure   => absent,
    }

    file { '/etc/apache2/admin1':
        ensure  => absent,
    }

    file { '/etc/apache2/admin2':
        ensure  => absent,
    }

    file { '/etc/apache2/admin3':
        ensure  => absent,
    }

    # TBD: add link from /etc/apache/modsec_rules
    # to deploy location.  Requires change to
    # modsec template
    # file { '/etc/apache/modsec_rules':
    #     ensure  => 'link',
    #     target  => '/srv/deployment/apache2modsec',
    # }
    scap::target { 'apache2modsec/apache2modsec':
        ensure      => absent,
        deploy_user => 'apache2modsec',
        key_name    => 'apache2modsec',
    }
}
