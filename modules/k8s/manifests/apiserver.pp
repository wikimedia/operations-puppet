# == Class: k8s::apiserver
#
# This class sets up and configures kube-apiserver
#
# === Parameters
# [*additional_admission_plugins*] Admission plugins that should be enabled in
#   addition to default enabled ones (the defaults depend on the kubernetes
#   version, see `kube-apiserver -h | grep admission-plugins`).
#
# [*disable_admission_plugins*] Admission plugins that should be disabled
#   although they are in the default enabled plugins list (which depends on
#   the kubernetes version, see `kube-apiserver -h | grep admission-plugins`).
#
class k8s::apiserver(
    String $etcd_servers,
    Stdlib::Unixpath $ssl_cert_path,
    Stdlib::Unixpath $ssl_key_path,
    Hash[String, Any] $users,
    String $authz_mode = 'RBAC',
    Boolean $allow_privileged = false,
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $packages_from_future = false,
    Optional[Stdlib::IP::Address] $service_cluster_ip_range = undef,
    Optional[String] $service_node_port_range = undef,
    Optional[Integer] $apiserver_count = undef,
    Optional[String] $runtime_config = undef,
    Optional[K8s::AdmissionPlugins] $admission_plugins = undef,
) {

    group { 'kube':
        ensure => present,
        system => true,
    }
    user { 'kube':
        ensure => present,
        gid    => 'kube',
        system => true,
        home   => '/nonexistent',
        shell  => '/usr/sbin/nologin',
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kube',
        group  => 'kube',
        mode   => '0700',
    }

    if $packages_from_future {
        apt::package_from_component { 'apiserver-kubernetes-future':
            component => 'component/kubernetes-future',
            packages  => ['kubernetes-master'],
        }
    } else {
        require_package('kubernetes-master')
    }

    file { '/etc/kubernetes/infrastructure-users':
        content => template('k8s/infrastructure-users.csv.erb'),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        notify  => Service['kube-apiserver'],
    }

    file { '/etc/default/kube-apiserver':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-apiserver.default.erb'),
        notify  => Service['kube-apiserver'],
    }

    service { 'kube-apiserver':
        ensure => running,
        enable => true,
    }
}
