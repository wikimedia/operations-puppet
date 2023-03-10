# SPDX-License-Identifier: Apache-2.0
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
        ensure => absent,
    }

    file { '/srv/mwbuilder/.docker/config.json':
        ensure => absent,
    }

    file { '/root/.docker/config.json':
        ensure => absent,
    }

    # Directory where the file lock and error file are stored.
    file { '/var/lib/deploy-mwdebug':
        ensure  => absent,
        owner   => 'mwbuilder',
        group   => 'deployment',
        mode    => '0775',
        force   => true,
        recurse => true,
        purge   => true
    }

    # Add a script that updates the mediawiki images.
    file { '/usr/local/sbin/deploy-mwdebug':
        ensure => absent,
        source => 'puppet:///modules/profile/kubernetes/deployment_server/deploy-mwdebug.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Run the deployment check every 5 minutes
    systemd::timer::job { 'deploy_to_mwdebug':
        ensure            => absent,
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
