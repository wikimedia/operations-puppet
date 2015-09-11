# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the k8s apiserver
class k8s::apiserver_ssl($puppet_cert_name = $::fqdn, $ssldir = '/var/lib/puppet/ssl') {

    file { [
        '/var/lib/kubernetes',
        '/var/lib/kubernetes/ssl',
        '/var/lib/kubernetes/ssl/certs',
        '/var/lib/kubernetes/ssl/private_keys',
    ]:
        ensure => directory,
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0500',
    }


    file { '/var/lib/kubernetes/ssl/certs/ca.pem':
        ensure  => present,
        owner   => 'kube-apiserver',
        group   => 'kube-apiserver',
        mode    => '0400',
        source  => "${ssldir}/certs/ca.pem",
        require => File['/var/lib/kubernetes/ssl/certs'],
    }

    file { '/var/lib/kubernetes/ssl/certs/cert.pem':
        ensure  => present,
        owner   => 'kube-apiserver',
        group   => 'kube-apiserver',
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File['/var/lib/kubernetes/ssl/certs/ca.pem'],
    }

    file { '/var/lib/kubernetes/ssl/private_keys/server.key':
        ensure  => present,
        owner   => 'kube-apiserver',
        group   => 'kube-apiserver',
        mode    => '0400',
        source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
        require => File['/var/lib/kubernetes/ssl/private_keys'],
    }
}
