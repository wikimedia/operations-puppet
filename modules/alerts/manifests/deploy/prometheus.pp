# SPDX-License-Identifier: Apache-2.0
# Deploy alerts from $git_repo to $deploy_dir for Prometheus to pick up.
class alerts::deploy::prometheus (
    Stdlib::Unixpath $deploy_dir = '/srv/alerts',
    Stdlib::Unixpath $git_dir    = '/srv/alerts.git',
    String[1]        $git_repo   = 'operations/alerts',
    String[1]        $git_source = 'gerrit',
    String[1]        $git_branch = 'master',
    Array[String[1]] $instances  = [],
) {
    require ::alerts

    alerts::deploy::instance { 'local':
        alerts_dir    => $git_dir,
        deploy_dir    => $deploy_dir,
        deploy_site   => $::site,
        git_repo_name => $git_repo,
    }

    # Deploy instance-specific alerts
    $instances.each |$instance| {
        alerts::deploy::instance { $instance:
            alerts_dir    => $git_dir,
            deploy_dir    => "${deploy_dir}/${instance}",
            deploy_tag    => $instance,
            deploy_site   => $::site,
            git_repo_name => $git_repo,
        }
    }

    git::clone { $git_repo:
        ensure    => latest,
        directory => $git_dir,
        source    => $git_source,
        branch    => $git_branch,
        notify    => Exec['start alerts-deploy'],
    }

    exec { 'start alerts-deploy':
        command     => '/bin/systemctl start alerts-deploy.target',
        refreshonly => true,
        notify      => Exec['reload all prometheus instances'],
    }

    exec { 'reload all prometheus instances':
        command     => '/bin/systemctl reload prometheus@*',
        refreshonly => true,
    }
}
