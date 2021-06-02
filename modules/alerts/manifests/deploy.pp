# Deploy alerts from operations/alerts git repository checkout (in $git) to a "staging area" in
# $deploy_dir.
#
# The staging area is used because:
# * Prometheus doesn't support recursive globbing for rule files, thus we have to flatten directory trees.
# * It allows for further sanity checking pre-deployment, other than CI tests in the repo itself.

class alerts::deploy(
  Stdlib::Unixpath $deploy_dir = '/srv/alerts',
  Stdlib::Unixpath $git_dir = '/srv/alerts.git',
) {
    group { 'alerts-deploy':
        ensure => present,
        system => true,
    }

    user { 'alerts-deploy':
        gid        => 'alerts-deploy',
        shell      => '/bin/bash',
        system     => true,
        managehome => true,
        home       => '/var/lib/alerts-deploy',
        require    => Group['alerts-deploy'],
    }

    file { $deploy_dir:
        ensure => directory,
        owner  => 'alerts-deploy',
        group  => 'alerts-deploy',
        mode   => '0755',
    }

    file { '/usr/local/bin/alerts-deploy':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/alerts/deploy.py',
    }

    git::clone { 'operations/alerts':
        ensure    => latest,
        directory => $git_dir,
        branch    => 'master',
        notify    => Exec['deploy alerts'],
    }

    exec { 'deploy alerts':
        command     => "/usr/local/bin/alerts-deploy --cleanup --alerts-dir ${git_dir} ${deploy_dir}",
        user        => 'alerts-deploy',
        refreshonly => true,
        notify      => Exec['reload all prometheus instances'],
    }

    exec { 'reload all prometheus instances':
        command     => '/bin/systemctl reload prometheus@*',
        refreshonly => true,
    }
}
