# SPDX-License-Identifier: Apache-2.0
# == Define eventschemas::repository
# Clones a git repository into /srv/eventschemas/repositories/$title
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
# [*git_source*]
#   The Git platform to request the repository from. Default: gitlab
#
# [*sparse_paths*]
#   When set, only these top-level directories of the repository are checked
#   out (git sparse-checkout, cone mode), instead of the whole repository.
#   See git::clone for caveats. Default: undef (full checkout)
#
define eventschemas::repository(
    String $origin,
    String $ensure = 'latest',
    String $git_source = 'gitlab',
    Optional[Array[String[1]]] $sparse_paths = undef,
) {
    require ::eventschemas

    $path = "${::eventschemas::repositories_path}/${title}"
    git::clone { $origin:
        ensure       => $ensure,
        directory    => $path,
        source       => $git_source,
        sparse_paths => $sparse_paths,
    }
}
