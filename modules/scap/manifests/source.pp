# == Define scap::source
#
# Sets up scap3 deployment source on a deploy server.
# This will clone $repository at /srv/deployment/$title.
# If $scap_repository is set it will clone it at
# /srv/deployment/$title/scap.  If you set $scap_repository to true,
# this will assume that your scap repository is named $title/scap.
#
# To use this in conjunction with scap::target, make sure the $title here
# matches a scap::target's $title on your target hosts, or at least matches
# the $package_name provided to scap::target (which defaults to $title).
#
# NOTE: This define is compatible with trebuchet's deployment.yaml file.
# If trebuchet has already cloned a source repository in /srv/deployment,
# this clone will do nothing, as it only executes if .git/config
# doesn't already exist.
#
# == Parameters
#
# [*repository*]
#   Repository name in gerrit.  Default: $title
#
# [*scap_repository*]
#   String or boolean.
#
#   If you set this to a string, it will be assumed to be a repository name
#   This scap repository will then be cloned into /srv/deployment/$title/scap.
#   If this is set to true your scap_repository will be assumed to
#   live at $title/scap in gerrit.
#
#   You can use this keep your scap configs separate from your source
#   repositories.
#
#   Default: false.
#
# [*owner*]
#   Owner of cloned repository,
#   Default: trebuchet
#
# [*group*]
#   Group owner of cloned repository.
#   Default: wikidev
#
# == Usage
#
#   # Clones the 'repo/without/external/scap' repsitory into
#   # /srv/deployment/repo/without/external/scap.
#
#   scap::source { 'repo/without/external/scap': }
#
#
#   # Clones the 'eventlogging' repository into
#   # /srv/deployment/eventlogging/eventbus and
#   # clones the 'eventlogging/eventbus/scap' repository
#   # into /srv/deployment/eventlogging/eventbus/scap
#
#   scap::source { 'eventlogging/eventbus':
#       repository         => 'eventlogging',
#       scap_repository    => true,
#   }
#
#
#   # Clones the 'myproject/myrepo' repository into
#   # /srv/deployment/myproject/myrepo, and
#   # clones the custom scap repository at
#   # 'my/custom/scap/repo' from gerrit into
#   # /srv/deployment/myproject/myrepo/scap
#
#   scap::source { 'myproject/myrepo':
#       scap_repository    => 'my/custom/scap/repo',
#   }
#
define scap::source(
    $repository           = $title,
    $scap_repository      = false,
    # TODO: change scap repo owner when scap figures out
    # how to bootstrap itself properly without trebuchet.
    $owner                = 'trebuchet',
    $group                = 'wikidev',
) {
    # Path at which $repository should be cloned.
    $path                 = "/srv/deployment/${title}"

    # We can't rely on puppet to manage arbitrary subdirectories.
    # Use an exec to just make sure that $path's parent directories exist.
    exec { "mkdir_scap_source_path_${title}":
        command => "mkdir -p $(dirname ${path}) && chmod 775 $(dirname ${path}) && chown ${owner}:${group} $(dirname ${path})",
        path    => '/bin:/usr/bin',
        unless  => "test -d $(dirname ${path})",
        user    => 'root',
    }

    # Clone the source repository at $path.
    git::clone { "scap::source ${repository} for ${title}":
        # Since usage of this define might result in multiple clones of the
        # same $repository, it is necessary to title the git::clones with
        # unique names.  If we aren't using the repository name as the $title
        # of git::clone, then we need to set $origin, and a $origin
        # must be a full git URL. This means we can't yet use phabricator
        # git URLs.  TODO: Fix git::clone to support custom repository names
        # without specificing full git $origin URLs.
        origin             => "https://gerrit.wikimedia.org/r/p/${repository}.git",
        directory          => $path,
        owner              => $owner,
        group              => $group,
        shared             => true,
        recurse_submodules => true,
        require            => Exec["mkdir_scap_source_path_${title}"],
    }

    if $scap_repository {
        # Clone the scap repository at $path/scap
        $scap_clone_path = "${path}/scap"
        git::clone { "scap::source ${scap_repository} for ${title}":
            origin             => "https://gerrit.wikimedia.org/r/p/${scap_repository}.git",
            directory          => $scap_clone_path,
            owner              => $owner,
            group              => $group,
            shared             => true,
            recurse_submodules => true,
            require            => Git::Clone["scap::source ${repository} for ${title}"],
        }

        # Go ahead and init the DEPLOY_HEAD too
        exec{ "init ${scap_repository} for ${title}":
            creates => "${scap_clone_path}/.git/DEPLOY_HEAD",
            command => 'scap deploy --init',
            cwd     => $scap_clone_path,
            user    => $owner,
            group   => $group,
            require => Git::Clone["scap::source ${scap_repository} for ${title}"],
        }
    }
}
