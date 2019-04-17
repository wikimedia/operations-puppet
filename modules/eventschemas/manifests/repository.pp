# == Define eventschemas::repository
# Clones a git repository into /srv/schemas/repositories/$title
#
# == Parameters
# [*title*]
#   Name of repository, will be used in path to clone.
#
# [*origin*]
#   Git origin to clone
#
# [*ensure*]
#   Passed to git::clone.  Default: latest
#
define eventschemas::repository(
    String $origin,
    String $ensure = 'latest',
) {
    require ::eventschemas

    $path = "${::eventschemas::repositories_path}/${title}"
    git::clone { $origin:
        ensure    => $ensure,
        directory => $path,
    }
}
