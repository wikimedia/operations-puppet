# Deploy alerts from operations/alerts to $deploy_dir for Thanos to pick up.

class alerts::deploy::thanos(
  Stdlib::Unixpath $deploy_dir = '/srv/alerts-thanos',
  Stdlib::Unixpath $git_dir = '/srv/alerts.git',
) {
    require ::alerts

    file { $deploy_dir:
        ensure => directory,
        owner  => 'alerts-deploy',
        group  => 'alerts-deploy',
        mode   => '0755',
    }

    git::clone { 'operations/alerts':
        ensure    => latest,
        directory => $git_dir,
        branch    => 'master',
        notify    => Exec['deploy thanos alerts'],
    }

    exec { 'deploy thanos alerts':
        command     => "/usr/local/bin/alerts-deploy --deploy-tag global --cleanup --alerts-dir ${git_dir} ${deploy_dir}",
        user        => 'alerts-deploy',
        refreshonly => true,
        notify      => Exec['reload thanos-rule'],
    }

    exec { 'reload thanos-rule':
        command     => '/bin/systemctl reload thanos-rule',
        refreshonly => true,
    }
}
