# A module that gets installed on the backup metadata database
# And checks backups are being generated regularly and correctly,
# they are "fresh" (last backup isn't too old) and seemingly
# correct. Generate an icinga alert if not.
# Only metadata checks are done- full backup tests are to be
# done on a separate class.
class profile::mariadb::backup::check (
    $backups              = lookup('profile::mariadb::backup::check::backups', Hash, ),
    $freshness            = lookup('profile::mariadb::backup::check::freshness', Hash[String, Integer], ),
    $warn_size_percentage = lookup('profile::mariadb::backup::check::warn_size_percentage', Float[0, 100]),
    $crit_size_percentage = lookup('profile::mariadb::backup::check::crit_size_percentage', Float[0, 100]),
) {
    class { 'mariadb::monitor_backup_script': }

    $backups.each |String $section, Hash $section_hash| {
        $section_hash.each |String $type, Array[String] $type_array| {
            $type_array.each |String $dc| {
                mariadb::monitor_backup { "${dc}-${section}-${type}":
                    section              => $section,
                    datacenter           => $dc,
                    type                 => $type,
                    freshness            => $freshness[$type],
                    warn_size_percentage => $warn_size_percentage,
                    crit_size_percentage => $crit_size_percentage,
                }
            }
        }
    }
}

