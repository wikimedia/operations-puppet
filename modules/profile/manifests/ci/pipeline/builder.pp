# == profile::ci::pipeline::builder
#
# Pipeline server that can build and test Docker images.
#
class profile::ci::pipeline::builder(
    $minikube_user = hiera('jenkins_agent_username'),
    $minikube_user_home = hiera('jenkins_agent_home'),
) {
    include ::profile::ci::docker

    require_package('blubber')
    require_package('helm')
    require_package('kubernetes-client')
    require_package('minikube')
    require_package('socat')

    sudo::user { $minikube_user:
        privileges => ['ALL=(root) NOPASSWD: SETENV: /usr/bin/minikube'],
        require    => Package['minikube'],
    }

    file { "${minikube_user_home}/.kube":
        ensure => directory,
        owner  => $minikube_user,
        mode   => '0755',
    }

    file { "${minikube_user_home}/.helm":
        ensure => directory,
        owner  => $minikube_user,
        mode   => '0755',
    }

    file { "${minikube_user_home}/.kube/config":
        ensure => present,
        owner  => $minikube_user,
        mode   => '0644',
    }

    exec { 'start minikube':
        command     => '/usr/bin/sudo -E /usr/bin/minikube start --vm-driver none --bootstrapper=localkube',
        user        => 'jenkins-deploy',
        unless      => '/bin/systemctl is-active localkube',
        environment => [
            "MINIKUBE_HOME=${minikube_user_home}",
            "KUBECONFIG=${minikube_user_home}/.kube/config",
            'CHANGE_MINIKUBE_NONE_USER=true',
        ],
        require     => [
            Package['minikube'],
            File["${minikube_user_home}/.kube/config"],
            Sudo::User[$minikube_user],
        ],
    }

    exec { 'initialize helm':
        command     => '/usr/bin/helm init --tiller-image=gcr.io/kubernetes-helm/tiller:v2.8.1',
        environment => [
            "HELM_HOME=${minikube_user_home}/.helm",
            "KUBECONFIG=${minikube_user_home}/.kube/config",
        ],
        creates     => "${minikube_user_home}/.helm/repository",
        user        => 'jenkins-deploy',
        require     => [
            File["${minikube_user_home}/.helm"],
            Exec['start minikube'],
        ]
    }
}
