# == Define scap::source
#
# Sets up scap3 deployment source on a deploy server.
# This will clone $repository at $path.  If $scap_repository is set
# it will clone it at $path/scap.
#
# TODO: more WIP docs!
#
# == Parameters
#
# [*package_name*]
#   Repository name in gerrit.  Default: $title
#
# [*scap_repository_name]
#   Default: scap/$title. IF you set this to undef, a scap repo
#   will not be cloned into the scap/ directory in your source path in
#   /srv/deployment.
#
# [*path*]
#   Default: /srv/deployment/$title
#
# [*owner*]
#   Default: trebuchet
#
# [*group*]
#   Default: wikidev
#
# [*recurse_submodules*]
#   Default: false
#
# == Usage
#
#   # Clones the eventlogging repository into
#   # /srv/deployment/eventlogging/eventbus and
#   # clones the scap/eventlogging/eventbus repository
#   # into /srv/deployment/eventlogging/eventbus/scap
#   scap::source { 'eventlogging/eventbus':
#       repository         => 'eventlogging',
#       recurse_submodules => true,
#   }
#
#   # Clone the 'thing/without/external/scap' repsitory into
#   # /srv/deployment/thing/without/external/scap and
#   # don't clone any scap repo.
#   scap::source { 'thing/without/external/scap':
#       scap_repository => undef,
#   }
#
define scap::source(
    $repository           = $title,
    $scap_repository      = "scap/${title}",
    $path                 = "/srv/deployment/${title}"
    # TODO: change scap repo owner when scap figures out
    # how to bootstrap itself properly without trebuchet.
    $owner                = 'trebuchet'
    $group                = 'wikidev',
    $recurse_submodules   = false,
) {
    # We can't rely on puppet to manage arbitrary subdirectories.
    # Use an exec to just make sure that $path's parent directories exist.
    exec { "mkdir_scap_source_path_${title}":
        command => "mkdir $(dirname ${path}) && chmod 775 $(dirname ${path}) && chown ${owner}:${group} $(dirname ${path})",
        path    => '/bin:/usr/bin',
        unless  => "test -d $(dirname ${path})",
        user    => 'root',
    }

    # Clone the source repository at $path.
    git::clone { "${repository} for ${title}":
        # Since this define might result in multiple clones of the same
        # $repository, it is necessary to title the git::clones with unique
        # names.  If we aren't using the repository name as the $title of
        # git::clone, then we need to set $origin, and if provided $origin
        # must be a full git URL. This means we can't yet use phabricator
        # git URLs.  TODO: Fix git::clone to support repository_names
        # without specificing full git $origin URLs.
        origin             => "https://gerrit.wikimedia.org/r/p/${repository}.git"
        directory          => $path,
        owner              => $owner,
        group              => $group,
        shared             => true,
        recurse_submodules => $recurse_submodules,
        require            => Exec["mkdir_scap_source_path_${title}"],
    }

    if $scap_repository {
        # Clone the scap repository at $path/scap
        git::clone { "${scap_repository} for ${title}":
            origin             => "https://gerrit.wikimedia.org/r/p/${scap_repository}.git"
            directory          => "${path}/scap",
            owner              => $owner,
            group              => $group,
            shared             => true,
            recurse_submodules => $recurse_submodules,
            require            => Git::Clone[$repository],
        }
    }
}
