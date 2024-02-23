# Toolforge end points worth production monitoring
class icinga::monitor::toollabs () {
    # Complex checks via a wsgi app running on a cluster for this purpose.
    # See profile::toolforge::checker for more details.
    $test_entry_host = 'checker.tools.wmflabs.org'
    @monitoring::host { $test_entry_host:
        host_fqdn     => $test_entry_host,
        contact_group => 'wmcs-team',
    }

    # Toolschecker tests are pass/fail based on string return check
    $checker="check_http_url_at_address_for_string_with_timeout!300!${test_entry_host}"

    monitoring::service { 'tools-checker-labs-dns-private':
        description   => 'toolschecker: Verify internal DNS from within Tools',
        check_command => "${checker}!/dns/private!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-etcd-k8s':
        description    => 'toolschecker: All k8s etcd nodes are healthy',
        check_command  => "${checker}!/etcd/k8s!OK",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-team-email,wmcs-bots',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-ldap':
        description   => 'toolschecker: Test LDAP for query',
        check_command => "${checker}!/ldap!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team-email,wmcs-bots',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-dumps':
        description   => 'toolschecker: Make sure enwiki dumps are not empty',
        check_command => "${checker}!/nfs/dumps!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
        contact_group => 'wmcs-team-email',
    }

    monitoring::service { 'tools-checker-nfs-home':
        description   => 'toolschecker: NFS read/writeable on labs instances',
        check_command => "${checker}!/nfs/home!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-redis':
        description   => 'toolschecker: Redis set/get',
        check_command => "${checker}!/redis!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
        contact_group => 'wmcs-team',
    }

    monitoring::service { 'tools-checker-self':
        description   => 'toolschecker service itself needs to return OK',
        check_command => "${checker}!/self!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }
}
