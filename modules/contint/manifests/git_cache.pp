# == Define contint::git_cache
#
# Creates a bare repo in /srv/git so that the repo can be used by CI as a
# --reference for git clone operations.
#
# === Parameters
#
# [*repo*] repo that we need to cache on the docker hosts
#

define contint::git_cache(
    $repo = $title,
) {
    $repo_path = "/srv/git/${repo}.git"

    exec { "mkdir ${repo_path}":
        command => "/bin/mkdir -p ${repo_path}",
        creates => $repo_path,
        before  => Git::Clone[$repo],
    }

    # This is here to prevent the git::clone module from attempting to create
    # multi-level repos directory before the parent directories are created by
    # the exec in this definition
    file { $repo_path:
        ensure  => 'directory',
        require => Exec["mkdir ${repo_path}"],
    }

    git::clone{ $repo:
        bare      => true,
        directory => $repo_path,
        shared    => true,
    }
}
