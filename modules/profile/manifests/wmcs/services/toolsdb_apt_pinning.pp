class profile::wmcs::services::toolsdb_apt_pinning (
) {
    # if you are hitting this assert, you likely need to refresh package pins
    requires_os('debian == stretch')

    apt::pin { 'toolsdb_fixed_mariadb_version':
        package  => 'wmf-mariadb101',
        pin      => 'version 10.1.39-1',
        priority => '1002',
    }

    apt::pin { 'toolsdb_no_debian_package':
        package  => 'mariadb-server',
        pin      => 'version *',
        priority => '-1',
    }

    apt::pin { 'toolsdb_no_mariadb_103':
        package  => 'wmf-mariadb103',
        pin      => 'version *',
        priority => '-1',
    }
}
