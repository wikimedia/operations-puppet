class profile::wmcs::services::toolsdb_apt_pinning (
) {
    apt::pin { 'toolsdb_no_debian_package':
        package  => 'mariadb-server',
        pin      => 'version *',
        priority => -1,
    }

    if debian::codename::eq('stretch') {
        apt::pin { 'toolsdb_fixed_mariadb_version':
            package  => 'wmf-mariadb101',
            pin      => 'version 10.1.39-1',
            priority => 1002,
        }

        apt::pin { 'toolsdb_no_mariadb_103':
            package  => 'wmf-mariadb103',
            pin      => 'version *',
            priority => -1,
        }
    } elsif debian::codename::eq('bullseye') {
        apt::pin { 'toolsdb_fixed_mariadb_version':
            package  => 'wmf-mariadb104',
            pin      => 'version 10.4.25+deb11u1',
            priority => 1002,
        }

        apt::pin { 'toolsdb_no_mariadb_106':
            package  => 'wmf-mariadb106',
            pin      => 'version *',
            priority => -1,
        }
    } else {
        fail("${debian::codename()}: not supported by profile::wmcs::services::toolsdb_apt_pinning")
    }
}
