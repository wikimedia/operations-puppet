# @summary class to configure the primary reposync server
# @param ensure ensureable parameter
# @param base_dir The base directory to store config
# @param repos list of repositories
# @param remotes list of remotes
class reposync (
    Wmflib::Ensure      $ensure   = 'present',
    Stdlib::Unixpath    $base_dir = '/srv/reposync',
    Array[String[1]]    $repos    = [],
    Array[Stdlib::Host] $remotes  = [],
) {

    # config file used by spicerack
    $config_file = '/etc/spicerack/reposync/config.yaml'
    $config = {'base_dir' => $base_dir, 'repos' => $repos, 'remotes' => $remotes}

    wmflib::dir::mkdir_p([$base_dir, $config_file.dirname])

    file {$config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'root',
        content => $config.to_yaml,
    }
    $repos.each |$repo| {
        $repo_path = "${base_dir}/${repo}"
        file { $repo_path:
            ensure  => stdlib::ensure($ensure, 'directory'),
        }
        exec { "git_init_${repo}":
            command => "/usr/bin/git --bare -C ${repo_path} init",
            creates => "${repo_path}/HEAD",
            require => File[$repo_path],
        }
        file { "${repo_path}/hooks":
            ensure  => stdlib::ensure($ensure, 'directory'),
            require => Exec["git_init_${repo}"],
        }
        file { "${repo_path}/hooks/post-update":
            ensure  => stdlib::ensure($ensure, 'file'),
            mode    => '0550',
            content => "#!/bin/sh\nexec /usr/bin/git update-server-info\n",
            require => Exec["git_init_${repo}"],
        }
        file { "${repo_path}/config":
            ensure  => stdlib::ensure($ensure, 'file'),
            mode    => '0440',
            content => epp('reposync/config.epp', {'repo_path' => $repo_path, 'remotes' => $remotes}),
            require => Exec["git_init_${repo}"],
        }
    }
}
