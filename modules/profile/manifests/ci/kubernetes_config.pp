class profile::ci::kubernetes_config(
    String $user = hiera('profile::ci::kubernetes_config::user'),
    String $namespace = hiera('profile::ci::kubernetes_config::namespace'),
    Stdlib::Fqdn $master = hiera('profile::ci::kubernetes_config::master'),
    String $token = hiera('profile::ci::kubernetes_config::token')
) {
    # the file is visible to jenkins-slave and to contint-admins
    k8s::kubeconfig { '/etc/kubernetes/ci-staging.config':
        master_host => $master,
        username    => $user,
        token       => $token,
        owner       => 'jenkins-slave',
        group       => 'contint-admins',
        mode        => '0440',
        namespace   => $namespace,
    }
}
