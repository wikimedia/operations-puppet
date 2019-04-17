# == Class eventschemas
# Base class, just ensures /srv/schemas/repositories exists.
#
# == Parameters
# [*ensure*] Passed directly to git::clone.  Default: latest.
#
class eventschemas {
    $base_path = '/srv/eventschemas'
    $repositories_path = "${base_path}/repositories"

    file { [$base_path, $repositories_path]:
        ensure => 'directory',
    }
}
