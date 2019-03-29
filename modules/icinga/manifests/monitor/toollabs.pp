# Toolforge end points worth production monitoring
#
# * relevant cert expiry is monitored in icinga::monitor::certs
class icinga::monitor::toollabs {

    # toolserver.org (redirect page to Toolforge)
    @monitoring::host { 'www.toolserver.org':
        host_fqdn     => 'www.toolserver.org',
    }

    # monitoring of https://meta.wikimedia.org/wiki/PAWS
    @monitoring::host { 'paws.wmflabs.org':
        host_fqdn => 'paws.wmflabs.org',
    }

    monitoring::service { 'paws_main_page':
        description    => 'PAWS Main page',
        check_command  => 'check_http_url!paws.wmflabs.org!/paws/hub/login',
        host           => 'paws.wmflabs.org',
        contact_group  => 'team-paws',
        check_interval => 5,
        retry_interval => 5,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PAWS',
    }

    # this homepage is served by a tool running within tools
    # itself. On a bastion 'become admin' to see source and
    # 'webservice restart' if needed.
    @monitoring::host { 'tools.wmflabs.org':
        host_fqdn => 'tools.wmflabs.org',
    }

    monitoring::service { 'tools.wmflabs.org':
        description   => 'toolschecker: tools homepage (admin tool)',
        check_command => 'check_http_slow!20',
        host          => 'tools.wmflabs.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    # Monitors the tools nginx proxy by hitting the health endpoint
    # defined in dynamicproxy nginx.conf
    monitoring::service {'tools-proxy':
        description   => 'toolschecker: tools nginx proxy health',
        check_command => 'check_http_url!tools.wmflabs.org!/.well-known/healthz',
        host          => 'tools.wmflabs.org',
        contact_group => 'wmcs-team,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    # Complex checks via a wsgi app running on a cluster for this purpose.
    # See profile::toolforge::checker for more details.
    $test_entry_host = 'checker.tools.wmflabs.org'
    @monitoring::host { $test_entry_host:
        host_fqdn => $test_entry_host,
    }

    # Toolschecker tests are pass/fail based on string return check
    $checker="check_http_url_at_address_for_string_with_timeout!300!${test_entry_host}"

    # become toolschecker
    # crontab -e (from a bastion)
    monitoring::service { 'tools-checker-toolscron':
        description   => 'toolschecker: check mtime mod from tools cron job',
        check_command => "${checker}!/cron!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-toolsdb':
        description   => 'toolschecker: toolsdb read/write',
        check_command => "${checker}!/db/toolsdb!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-wikilabelsrw':
        description   => 'toolschecker: wikilabels read/write',
        check_command => "${checker}!/db/wikilabelsrw!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-labs-dns-private':
        description   => 'toolschecker: Verify internal DNS from within Tools',
        check_command => "${checker}!/dns/private!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-etcd-flannel':
        description    => 'toolschecker: All Flannel etcd nodes are healthy',
        check_command  => "${checker}!/etcd/flannel!OK",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-team,admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-etcd-k8s':
        description    => 'toolschecker: All k8s etcd nodes are healthy',
        check_command  => "${checker}!/etcd/k8s!OK",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-team,admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-grid-continuious-stretch':
        description    => 'toolschecker: expect a long running job on stretch',
        check_command  => "${checker}!/grid/continuous/stretch!ok",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-bots,admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/portal:toolforge/admin/toolschecker',
    }

    # The mechanism for this test is too flaky to page.  We need to revise
    # if persisting with SMS notification.
    monitoring::service { 'tools-checker-grid-start-stretch':
        description    => 'toolschecker: start a job and verify on stretch',
        check_command  => "${checker}!/grid/start/stretch!ok",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-bots,admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/portal:toolforge/admin/toolschecker',
    }

    monitoring::service { 'tools-checker-k8s-node-ready':
        description    => 'toolschecker: All k8s worker nodes are healthy',
        check_command  => "${checker}!/k8s/nodes/ready!OK",
        host           => $test_entry_host,
        check_interval => 5,
        retry_interval => 5,
        contact_group  => 'wmcs-team,admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-ldap':
        critical      => true,
        description   => 'toolschecker: Test LDAP for query',
        check_command => "${checker}!/ldap!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-dumps':
        description   => 'toolschecker: Make sure enwiki dumps are not empty',
        check_command => "${checker}!/nfs/dumps!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-nfs-home':
        critical      => true,
        description   => 'toolschecker: NFS read/writeable on labs instances',
        check_command => "${checker}!/nfs/home!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    # new instances will block on this for spinup if failing
    monitoring::service { 'tools-checker-nfs-showmount':
        description   => 'toolschecker: showmount succeeds on a labs instance',
        check_command => "${checker}!/nfs/secondary_cluster_showmount!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-redis':
        description   => 'toolschecker: Redis set/get',
        check_command => "${checker}!/redis!OK",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-self':
        critical      => true,
        description   => 'toolschecker service itself needs to return OK',
        check_command => "${checker}!/self!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-webservice-gridengine':
        critical      => true,
        description   => 'toolschecker: gridengine webservice running',
        check_command => "${checker}!/webservice/gridengine!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    monitoring::service { 'tools-checker-webservice-kubernetes':
        critical      => true,
        description   => 'toolschecker: kubernetes webservice running',
        check_command => "${checker}!/webservice/kubernetes!OK",
        host          => $test_entry_host,
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Toolschecker',
    }

    # TODO (T219243) Remove after the legacy config is purged
    monitoring::service { 'tools-checker-grid-start-trusty':
        ensure        => 'absent',
        description   => 'toolschecker: start a job and verify on trusty',
        check_command => "${checker}!/grid/start/trusty!ok",
        host          => $test_entry_host,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/portal:toolforge/admin/toolschecker',
    }
}
