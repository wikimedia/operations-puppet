# https://policy.wikimedia.org/
# T97329
class role::policy_www {
    system::role { 'role::policy_www':
        description => 'policy.wikimedia.org',
    }

    file { '/srv/org/wikimedia/policy':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    apache::static_site { 'policy.wikimedia.org':
        docroot => '/srv/org/wikimedia/policy',
    }
}
