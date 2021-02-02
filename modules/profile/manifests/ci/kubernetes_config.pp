class profile::ci::kubernetes_config(
    String $user = lookup('profile::ci::kubernetes_config::user'),
    String $namespace = lookup('profile::ci::kubernetes_config::namespace'),
    Stdlib::Fqdn $master = lookup('profile::ci::kubernetes_config::master'),
    String $token = lookup('profile::ci::kubernetes_config::token')
) {

    ensure_resource('file', '/etc/kubernetes', {'ensure' => 'directory' })

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
