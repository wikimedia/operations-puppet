# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::toolsdb_apt_pinning (
) {
    apt::pin { 'toolsdb_no_debian_package':
        package  => 'mariadb-server',
        pin      => 'version *',
        priority => -1,
    }

    # A pin with priority between 0 and 100 will allow the package to be installed
    # but will not allow upgrading it (unless manually asked to do so).
    apt::pin { 'toolsdb_mariadb_106_no_auto_updates':
      package  => 'wmf-mariadb106',
      pin      => 'version *',
      priority => 90,
    }
}
