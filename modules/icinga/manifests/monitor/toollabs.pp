# Tool Labs end points worth production monitoring
#
# * relevant cert expirary is monitored in
#   icinga::monitor::certs

class icinga::monitor::toollabs {

    # toolserver.org (redirect page to Tool Labs)
    @monitoring::host { 'www.toolserver.org':
        host_fqdn     => 'www.toolserver.org'
    }

    # monitoring of https://meta.wikimedia.org/wiki/PAWS
    @monitoring::host { 'paws.wmflabs.org':
        host_fqdn => 'paws.wmflabs.org',
    }

    monitoring::service { 'paws_main_page':
        description   => 'PAWS Main page',
        check_command => 'check_http_url!paws.wmflabs.org!/paws/hub/login',
        host          => 'paws.wmflabs.org',
        contact_group => 'team-paws',
    }

    # this homepage is served by a tool running within tools
    # itself. on a bastion 'become admin' to see source and
    # 'webservices restart' if needed.
    @monitoring::host { 'tools.wmflabs.org':
        host_fqdn => 'tools.wmflabs.org',
    }

    monitoring::service { 'tools.wmflabs.org':
        description   => 'tools homepage (admin tool)',
        check_command => 'check_http_slow!20',
        host          => 'tools.wmflabs.org',
    }

    # complex checks via a wsgi app running on a cluster for this purpose.
    # these checks are used to track uptime and availability via
    # catchpoint as well as for general alerting and administration.
    $test_entry_host = 'checker.tools.wmflabs.org'
    @monitoring::host { $test_entry_host:
        host_fqdn => $test_entry_host,
    }

    # tests are pass/fail based on string return check
    $checker="check_http_url_at_address_for_string!${test_entry_host}"

    monitoring::service { 'tools-checker-self':
        description   => 'toolschecker service itself needs to return OK',
        check_command => "${checker}!/self!OK",
        critical      => true,
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-dumps':
        description   => 'Make sure enwiki dumps are not empty',
        check_command => "${checker}!/dumps!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-redis':
        description   => 'Redis set/get',
        check_command => "${checker}!/redis!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-ldap':
        description   => 'Test LDAP for query',
        check_command => "${checker}!/ldap!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-puppetmaster-eqiad':
        description   => 'Puppet catalogue fetch',
        check_command => "${checker}!/labs-puppetmaster/eqiad!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-labs-dns-private':
        description   => 'Verify internal DNS from within Tools',
        check_command => "${checker}!/labs-dns/private!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-nfs-home':
        description   => 'NFS read/writeable on labs instances',
        check_command => "${checker}!/nfs/home!OK",
        critical      => true,
        host          => $test_entry_host,
    }

    # new instances will block on this for spinup if failing
    monitoring::service { 'tools-checker-nfs-showmount':
        description   => 'showmount succeeds on a labs instance',
        check_command => "${checker}!/nfs/showmount!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-toolscron':
        description   => 'check mtime mod from tools cron job',
        check_command => "${checker}!/toolscron!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-grid-start-trusty':
        description   => 'Start a job and verify on Trusty',
        check_command => "${checker}!/grid/start/trusty!OK",
        host          => $test_entry_host,
    }

    monitoring::service { 'tools-checker-grid-start-precise':
        description   => 'Start a job and verify on Precise',
        check_command => "${checker}!/grid/start/precise!OK",
        host          => $test_entry_host,
    }
}
