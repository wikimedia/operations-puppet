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

    require_package([
        'docker-engine',
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
    ])

    user { 'codesearch':
        ensure     => present,
        system     => true,
        membership => ['docker'],
        require    => Package['docker-engine'],
    }

    file { [$hound_dir, $clone_dir]:
        ensure => directory,
        owner  => 'codesearch',
        group  => 'codesearch',
        mode   => '0755',
    }

    git::clone {'labs/codesearch':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
        require   => [File[$clone_dir], User['codesearch']],
        owner     => 'codesearch',
        group     => 'codesearch',
    }

    git::clone {'operations/puppet':
        ensure    => latest,
        directory => $puppet_dir,
        branch    => 'production',
        require   => [File[$puppet_dir], User['codesearch']],
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
