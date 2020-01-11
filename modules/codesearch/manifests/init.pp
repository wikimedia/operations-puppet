# = Class: codesearch
#
# This class sets up the basics needed for MediaWiki code search
# hosted at codesearch.wmflabs.org
#
class codesearch(
    Optional[Stdlib::Unixpath] $base_dir = undefined,
){
    $hound_dir  = "${base_dir}/hound"
    $clone_dir  = "${base_dir}/codesearch"
    $puppet_dir = "${base_dir}/puppet"

    apt::package_from_component { 'thirdparty-kubeadm-k8s':
        components => 'thirdparty/kubeadm-k8s',
        packages   => 'docker-ce',
    }

    require_package([
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
    ])

    group { 'codesearch':
        ensure => present,
        name   => 'codesearch',
        system => true,
    }

    user { 'codesearch':
        ensure  => present,
        system  => true,
        groups  => 'docker',
        require => Package['docker-ce'],
    }

    git::clone {'labs/codesearch':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
        require   => User['codesearch'],
        owner     => 'codesearch',
        group     => 'codesearch',
    }

    git::clone {'operations/puppet':
        ensure    => latest,
        directory => $puppet_dir,
        branch    => 'production',
        require   => User['codesearch'],
        owner     => 'codesearch',
        group     => 'codesearch',
    }
    # TODO: Alias production to master on initial clone with:
    #  git symbolic-ref refs/remotes/origin/master refs/remotes/origin/production
    #  git symbolic-ref refs/heads/master refs/heads/production

    # TODO: Migrate to a systemd timer
    cron { 'codesearch-write-config':
        command => "${clone_dir}/write_config.py",
        user    => 'codesearch',
        minute  => '0',
        hour    => '0',
        require => [
            Git::Clone['labs/codesearch'],
            User['codesearch'],
        ],
    }

    systemd::service { 'hound_proxy':
        ensure  => present,
        content => template('codesearch/initscripts/hound_proxy.service.erb'),
        restart => true,
        require => [Git::Clone['labs/codesearch'], Package['gunicorn3']]
    }
}
