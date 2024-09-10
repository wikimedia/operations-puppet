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
define eventschemas::repository(
    String $origin,
    String $ensure = 'latest',
    String $git_source = 'gitlab',
) {
    require ::eventschemas

    $path = "${::eventschemas::repositories_path}/${title}"
    git::clone { $origin:
        ensure    => $ensure,
        directory => $path,
        source    => $git_source,
    }
}
