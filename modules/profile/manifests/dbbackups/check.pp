# Check backups are being generated regularly and correctly,
# they are "fresh" (last backup isn't too old) and seemingly
# correct. Generate an icinga alert if not.
# Only metadata checks are done- full backup tests are to be
# done on a separate class.
class profile::dbbackups::check (
    $backups              = lookup('profile::dbbackups::check::backups', Hash, ),
    $freshness            = lookup('profile::dbbackups::check::freshness', Hash[String, Integer], ),
    $warn_size_percentage = lookup('profile::dbbackups::check::warn_size_percentage', Float[0.0, 100.0]),
    $crit_size_percentage = lookup('profile::dbbackups::check::crit_size_percentage', Float[0.0, 100.0]),
    $db_host              = lookup('profile::dbbackups::check::db_host', String, ),
    $db_user              = lookup('profile::dbbackups::check::db_user', String, ),
    $db_password          = lookup('profile::dbbackups::check::db_password', String, ),
    $db_database          = lookup('profile::dbbackups::check::db_database', String, ),
) {
    require ::profile::mariadb::wmfmariadbpy
    class { 'dbbackups::check_common':
        valid_sections_file => 'puppet:///modules/profile/dbbackups/valid_sections.txt',
    }

    $backups.each |String $section, Hash $section_hash| {
        $section_hash.each |String $type, Array[String] $type_array| {
            $type_array.each |String $dc| {
                dbbackups::check { "${dc}-${section}-${type}":
                    section              => $section,
                    datacenter           => $dc,
                    type                 => $type,
                    freshness            => $freshness[$type],
                    warn_size_percentage => $warn_size_percentage,
                    crit_size_percentage => $crit_size_percentage,
                    db_user              => $db_user,
                    db_host              => $db_host,
                    db_password          => $db_password,
                    db_database          => $db_database,
                }
            }
        }
    }
}

