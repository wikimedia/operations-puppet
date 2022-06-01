# SPDX-License-Identifier: Apache-2.0
# @summary class to configure the primary reposync server
# @param ensure ensureable parameter
# @param manage_base set to false if the base directory is managed else where
# @param owner the user to use as owner of the repos
# @param group the group to use as owner of the repos
# @param target_only only configure repos dont install spicerack config
# @param repos list of repositories
# @param remotes list of remotes
class reposync (
    Wmflib::Ensure      $ensure      = 'present',
    Boolean             $manage_base = true,
    String[1]           $owner       = 'root',
    String[1]           $group       = 'root',
    Boolean             $target_only = false,
    Array[String[1]]    $repos       = [],
    Array[Stdlib::Host] $remotes     = [],
) {

    # config file used by spicerack
    $config_file = '/etc/spicerack/reposync/config.yaml'
    $base_dir = '/srv/reposync'
    $config = {'base_dir' => $base_dir, 'repos' => $repos, 'remotes' => $remotes}

    if $manage_base {
        wmflib::dir::mkdir_p([$base_dir])
    }
    unless $target_only {
        wmflib::dir::mkdir_p([$config_file.dirname])
        file {$config_file:
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            content => $config.to_yaml,
        }
    }
    $repos.each |$repo| {
        $repo_path = "${base_dir}/${repo}"
        file { $repo_path:
            ensure  => stdlib::ensure($ensure, 'directory'),
            owner   => $owner,
            group   => $group,
            recurse => true,
        }
        exec { "git_init_${repo}":
            command => "/usr/bin/git -C ${repo_path} init --bare",
            user    => $owner,
            creates => "${repo_path}/HEAD",
            require => File[$repo_path],
        }
        file {
            default:
                owner   => $owner,
                group   => $group,
                require => Exec["git_init_${repo}"];
            "${repo_path}/hooks":
                ensure  => stdlib::ensure($ensure, 'directory');
            "${repo_path}/hooks/post-update":
                ensure  => stdlib::ensure($ensure, 'file'),
                mode    => '0550',
                content => "#!/bin/sh\nexec /usr/bin/git update-server-info\n";
            "${repo_path}/config":
                ensure  => stdlib::ensure($ensure, 'file'),
                mode    => '0440',
                content => epp('reposync/config.epp', {'repo_path' => $repo_path, 'remotes' => $remotes});
        }
    }
}
