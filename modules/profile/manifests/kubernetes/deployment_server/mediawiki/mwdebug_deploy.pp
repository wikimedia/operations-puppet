# @summary This profile handles deploying automatically to the mwdebug namespace.
#
class profile::kubernetes::deployment_server::mediawiki::mwdebug_deploy(
    String $deployment_server                           = lookup('deployment_server'),
    Stdlib::Unixpath $general_dir                       = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    String $docker_password                             = lookup('kubernetes_docker_password'),
    Stdlib::Fqdn $docker_registry                       = lookup('docker::registry'),
){
    # "Automatic" deployment to mw on k8s. See T287570

    # Install docker-report in order to be able to list tags remotely
    package { 'python3-docker-report':
        ensure => present,
    }

    # Now install the credentials for the kubernetes docker user so that we can list tags
    # in the restricted namespace. This is ok since the credentials will be guarded by
    # being ran as mwbuilder, and that is the user that builds the images in the first
    # place.
    docker::credentials { '/srv/mwbuilder/.docker/config.json':
        owner             => 'mwbuilder',
        group             => 'mwbuilder',
        registry          => $docker_registry,
        registry_username => 'kubernetes',
        registry_password => $docker_password,
        allow_group       => false,
    }
    # TODO: remove once T305729 is resolved.
    docker::credentials { '/root/.docker/config.json':
        owner             => 'root',
        group             => 'root',
        registry          => $docker_registry,
        registry_username => 'kubernetes',
        registry_password => $docker_password,
        allow_group       => false,
    }
    # Directory where the file lock and error file are stored.
    file { '/var/lib/deploy-mwdebug':
        ensure => directory,
        owner  => 'mwbuilder',
        group  => 'mwdeploy',
        mode   => '0755'
    }

    # Add a script that updates the mediawiki images.
    file { '/usr/local/sbin/deploy-mwdebug':
        source => 'puppet:///modules/profile/kubernetes/deployment_server/deploy-mwdebug.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    $ensure_deploy = $deployment_server ? {
        $facts['networking']['fqdn'] => 'present',
        default => 'absent'
    }
    # Run the deployment check every 5 minutes
    systemd::timer::job { 'deploy_to_mwdebug':
        ensure            => $ensure_deploy,
        description       => 'Deploy the latest available set of images to mw on k8s',
        command           => '/usr/local/sbin/deploy-mwdebug --noninteractive',
        user              => 'mwbuilder',
        interval          => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '300s',
        },
        environment       => {
            'HELM_CONFIG_HOME' => '/etc/helm',
            'HELM_CACHE_HOME'  => '/var/cache/helm',
            'HELM_DATA_HOME'   => '/usr/share/helm',
            # This is what will get to SAL
            'SUDO_USER'        => 'mwdebug-deploy',
        },
        syslog_identifier => 'deploy-mwdebug',
    }
}
