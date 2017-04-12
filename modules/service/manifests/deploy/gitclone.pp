# === Class service::deploy::gitclone
#
# Allows configuring a git repository to check out
# at the same location as trebuchet/scap would check it out
#
# === Parameters
#
# [*repository*] is the repository name on gerrit that should
#   be cloned.
#
define service::deploy::gitclone( $repository ) {
    $dir = "/srv/deployment/${title}/deploy"
    require ::service::deploy::common

    if ! defined(Git::Clone[$repository]) {
        git::clone { $repository:
            directory          => $dir,
            recurse_submodules => true,
        }
    }
}
