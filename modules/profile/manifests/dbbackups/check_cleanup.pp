# Temporary profile to cleanup leftovers of the
# dbbackups::check and wmfmariadbpy modules
# SPDX-License-Identifier: Apache-2.0
class profile::dbbackups::check_cleanup (
    $backups              = lookup('profile::dbbackups::check::backups', Hash, ),
    $freshness            = lookup('profile::dbbackups::check::freshness', Hash[String, Integer], ),
    $warn_size_percentage = lookup('profile::dbbackups::check::warn_size_percentage', Float[0.0, 100.0]),
    $crit_size_percentage = lookup('profile::dbbackups::check::crit_size_percentage', Float[0.0, 100.0]),
    $db_host              = lookup('profile::dbbackups::check::db_host', String, ),
    $db_user              = lookup('profile::dbbackups::check::db_user', String, ),
    $db_password          = lookup('profile::dbbackups::check::db_password', String, ),
    $db_database          = lookup('profile::dbbackups::check::db_database', String, ),
) {
    package { [
            'wmfmariadbpy', 'python3-wmfmariadbpy',
            'wmfbackups', 'wmfbackups-check', 'python3-wmfbackups',
        ]:
        ensure => purged,
    }
    file { [
            '/etc/wmfbackups/valid_sections.txt',
            '/etc/wmfbackups',
            '/etc/wmfmariadbpy/section_ports.csv',
            '/etc/wmfmariadbpy',
        ]:
        ensure => absent,
    }

    $backups.each |String $section, Hash $section_hash| {
        $section_hash.each |String $type, Array[String] $type_array| {
            $type_array.each |String $dc| {
                file { "/etc/nagios/nrpe.d/check_mariadb_${type}_${section}_${dc}.cfg":
                    ensure => absent,
                }
            }
        }
    }
}

