#TODO rethink this entire class
class profile::kubernetes::deployment_server(
    $admin_token='TODO',
    $mathoid_token='TODO',
){
    package { 'helm':
        ensure => installed,
    }
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Create the admin configs
    k8s::kubeconfig { '/etc/kubernetes/admin-eqiad.config':
        master_host => 'kubemaster.svc.eqiad.wmnet',
        username    => 'client-infrastructure',
        token       => $admin_token,
    }

    k8s::kubeconfig { '/etc/kubernetes/admin-codfw.config':
        master_host => 'kubemaster.svc.codfw.wmnet',
        username    => 'client-infrastructure',
        token       => $admin_token,
    }

    k8s::kubeconfig { '/etc/kubernetes/admin-staging.config':
        master_host => 'neon.eqiad.wmnet',
        username    => 'client-infrastructure',
        token       => $admin_token,
    }

    # mathoid
    k8s::kubeconfig { '/etc/kubernetes/mathoid-eqiad.config':
        master_host => 'kubemaster.svc.eqiad.wmnet',
        username    => 'mathoid',
        token       => $mathoid_token,
        group       => 'wikidev',
        mode        => '640',
    }
    k8s::kubeconfig { '/etc/kubernetes/mathoid-codfw.config':
        master_host => 'kubemaster.svc.codfw.wmnet',
        username    => 'mathoid',
        token       => $mathoid_token,
        group       => 'wikidev',
        mode        => '640',
    }
    k8s::kubeconfig { '/etc/kubernetes/mathoid-staging.config':
        master_host => 'neon.eqiad.wmnet',
        username    => 'mathoid',
        token       => $mathoid_token,
        group       => 'wikidev',
        mode        => '640',
    }
}
