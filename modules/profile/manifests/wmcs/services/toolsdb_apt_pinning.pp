# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::toolsdb_apt_pinning (
) {
    apt::pin { 'toolsdb_no_debian_package':
        package  => 'mariadb-server',
        pin      => 'version *',
        priority => -1,
    }

    if debian::codename::eq('bullseye') {
        # A pin with priority between 0 and 100 will allow the package to be installed
        # but will not allow upgrading it (unless manually asked to do so).
        apt::pin { 'toolsdb_mariadb_104_no_auto_updates':
            package  => 'wmf-mariadb104',
            pin      => 'version *',
            priority => 90,
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
