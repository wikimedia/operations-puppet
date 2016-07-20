# Allows configuring a git repository to check out
# at the same location as trebuchet/scap would check it out

define service::deploy::gitclone( $repository ) {
    $dir = "/srv/deployment/${title}/deploy"
    require ::service::deploy::common

    git::clone { $repository:
        directory          => $dir,
        recurse_submodules => true,
    }
}
