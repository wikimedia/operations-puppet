# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::toolsdb_apt_pinning (
) {
    apt::pin { 'toolsdb_no_debian_package':
        package  => 'mariadb-server',
        pin      => 'version *',
        priority => -1,
    }

    apt::unattendedupgrades::exclude { 'wmf-mariadb106': }
}
