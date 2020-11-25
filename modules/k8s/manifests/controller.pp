# Class that sets up and configures kube-controller-manager
class k8s::controller(
    Boolean $use_service_account_credentials=false,
    Boolean $logtostderr=true,
    Integer $v_log_level=0,
    Optional[String] $service_account_private_key_file=undef,
    Optional[String] $kubeconfig=undef,
){

    if $use_service_account_credentials and !$service_account_private_key_file {
        fail('Need service_account_private_key_file set if use_service_account_credentials is to be used')
    }

    require_package('kubernetes-master')

    file { '/etc/default/kube-controller-manager':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-controller-manager.default.erb'),
        notify  => Service['kube-controller-manager'],
    }

    service { 'kube-controller-manager':
        ensure => running,
        enable => true,
    }
}
