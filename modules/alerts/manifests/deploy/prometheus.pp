# Deploy alerts from operations/alerts to $deploy_dir for Prometheus to pick up.

class alerts::deploy::prometheus(
  Stdlib::Unixpath $deploy_dir = '/srv/alerts',
  Stdlib::Unixpath $git_dir = '/srv/alerts.git',
  Array[String] $instances = [],
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
        notify    => Exec['deploy alerts'],
    }

    exec { 'deploy alerts':
        command     => "/usr/local/bin/alerts-deploy --cleanup --alerts-dir ${git_dir} ${deploy_dir}",
        user        => 'alerts-deploy',
        refreshonly => true,
        notify      => Exec['reload all prometheus instances'],
    }

    # Deploy instance-specific alerts
    $instances.each |$instance| {
        file { "${deploy_dir}/${instance}":
            ensure => directory,
            owner  => 'alerts-deploy',
            group  => 'alerts-deploy',
            mode   => '0755',
        }

        exec { "deploy alerts for instance ${instance}":
            command     => "/usr/local/bin/alerts-deploy --cleanup --alerts-dir ${git_dir} ${deploy_dir}/${instance} --deploy-tag ${instance}",
            user        => 'alerts-deploy',
            refreshonly => true,
            notify      => Exec['reload all prometheus instances'],
        }
    }

    exec { 'reload all prometheus instances':
        command     => '/bin/systemctl reload prometheus@*',
        refreshonly => true,
    }
}
