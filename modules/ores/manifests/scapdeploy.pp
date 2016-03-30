class ores::scapdeploy(
    $deploy_user = 'deploy-service',
    $deploy_group = 'deploy-service',
    $public_key_path = 'puppet:///private/ssh/tin/servicedeploy_rsa.pub',
) {
    require ores::base

    # Deployment configurations
    include scap
    scap::target { 'ores/deploy':
        deploy_user       => $deploy_user,
        public_key_source => $public_key_path,
        sudo_rules        => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores-web *',
            'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
        ],
    }

    file { '/srv/ores':
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_group,
        mode   => '0775',
    }

    file { '/srv/ores/deploy-cache':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
    }

    file { '/srv/deployment/ores':
        ensure  => directory,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
    }

    file { '/srv/ores/deploy':
        ensure  => present,
        owner   => $deploy_user,
        group   => $deploy_group,
        mode    => '0775',
        recurse => true,
    }
}
