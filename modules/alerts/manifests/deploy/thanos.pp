# SPDX-License-Identifier: Apache-2.0
# Deploy alerts from operations/alerts to $deploy_dir for Thanos to pick up.

class alerts::deploy::thanos(
  Stdlib::Unixpath $deploy_dir = '/srv/alerts-thanos',
  Stdlib::Unixpath $git_dir = '/srv/alerts.git',
) {
    require ::alerts

    alerts::deploy::instance { 'global':
        alerts_dir => $git_dir,
        deploy_dir => $deploy_dir,
        deploy_tag => 'global',
    }

    git::clone { 'operations/alerts':
        ensure    => latest,
        directory => $git_dir,
        branch    => 'master',
        notify    => Exec['start alerts-deploy for thanos'],
    }

    exec { 'start alerts-deploy for thanos':
        command     => '/bin/systemctl start alerts-deploy.target',
        refreshonly => true,
        notify      => Exec['reload thanos-rule for alerts'],
    }

    exec { 'reload thanos-rule for alerts':
        command     => '/bin/systemctl reload thanos-rule',
        refreshonly => true,
    }
}
