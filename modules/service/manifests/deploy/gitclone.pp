# === Class service::deploy::gitclone
#
# Allows configuring a git repository to check out
# at the same location as scap would check it out
#
# === Parameters
#
# [*repository*] is the repository name on gerrit that should
#   be cloned.
#
define service::deploy::gitclone( $repository ) {
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
        require            => File[$dir],
    }
}
