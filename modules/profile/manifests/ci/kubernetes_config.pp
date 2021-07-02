class profile::ci::kubernetes_config(
    String $user = lookup('profile::ci::kubernetes_config::user'),
    String $namespace = lookup('profile::ci::kubernetes_config::namespace'),
    Stdlib::Fqdn $master = lookup('profile::ci::kubernetes_config::master'),
    String $token = lookup('profile::ci::kubernetes_config::token'),
    String $owner = lookup('profile::ci::kubernetes_config::owner'),
    String $group = lookup('profile::ci::kubernetes_config::group')
) {

    # the file is visible to jenkins-slave and to contint-admins
    k8s::kubeconfig { '/etc/kubernetes/ci-staging.config':
        master_host => $master,
        username    => $user,
        token       => $token,
        owner       => $owner,
        group       => $group,
        mode        => '0440',
        namespace   => $namespace,
    }
}
