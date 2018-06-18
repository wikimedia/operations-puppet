class profile::ci::kubernetes_config(
    $user = hiera('profile::ci::kubernetes_config::user'),
    $namespace = hiera('profile::ci::kubernetes_config::namespace'),
    $master = hiera('profile::ci::kubernetes_config::master'),
    $token = hiera('profile::ci::kubernetes_config::token')
) {
    # the file is visible to jenkins-slave and to contint-admins
    k8s::kubeconfig { '/etc/kubernetes/ci- staging.config':
        master_host => $master,
        username    => $user,
        token       => $token,
        owner       => 'jenkins-slave',
        group       => 'contint-admins',
        mode        => '0440',
        namespace   => $namespace,
    }
}
