# Monitoing checks that live in icinga and page people
class toollabs::monitoring::icinga {
    # Paging checks!
    @monitoring::host { 'tools.wmflabs.org':
        host_fqdn => 'tools.wmflabs.org',
    }

    monitoring::service { 'tools_main_page':
        description   => 'tools-home',
        check_command => 'check_http_slow!20',
        host          => 'tools.wmflabs.org',
        critical      => true,
    }

    monitoring::service { 'nfs-on-labs-instances':
        description   => 'NFS read/writeable on labs instances',
        check_command => 'check_http_url_at_address_for_string!tools-checker.wmflabs.org!/nfs/home!OK',
        critical      => true,
        host          => 'tools.wmflabs.org',
    }
}
