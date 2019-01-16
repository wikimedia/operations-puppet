# === Class service::deploy::gitclone
#
# Allows configuring a git repository to check out
# at the same location as scap would check it out
#
# === Parameters
#
# [*prefix*] is the prefix used to logically group
#   repositories on gerrit. e.g. 'mediawiki/services'.
#
# [*repository*] is the (short) repository name on gerrit that
#   should be cloned. e.g. 'parsoid'.
#
define service::deploy::gitclone(
    String[1] $prefix = 'mediawiki/services',
    String[1] $repository = $title,
){

    $dir = "/srv/deployment/${title}"
    require ::service::deploy::common

    file { $dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    git::clone { "${prefix}/${repository}":
        directory          => $dir,
        recurse_submodules => true,
        require            => File[$dir],
    }
}
