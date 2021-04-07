# === Class service::deploy::gitclone
#
# Allows configuring a git repository to check out
# at the same location as scap would check it out
#
# === Parameters
#
# [*repository*] is the (short) repository name on gerrit that
#   should be cloned. e.g. 'parsoid'.
#
define service::deploy::gitclone(
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

    git::clone { $repository:
        directory          => "${dir}/deploy",
        recurse_submodules => true,
        owner              => 'root',
        group              => 'wikidev',
        shared             => true,
        require            => File[$dir],
    }
}
