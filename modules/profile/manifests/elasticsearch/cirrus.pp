#
# This class configures elasticsearch
#
# == Parameters:
#
# For documentation of parameters, see the elasticsearch profile.
#
class profile::elasticsearch::cirrus(
    String $cluster_name = hiera('profile::elasticsearch::cluster_name'),
    Wmflib::IpPort $http_port = hiera('profile::elasticsearch::http_port'),
    Wmflib::IpPort $tls_port = hiera('profile::elasticsearch::cirrus::tls_port'),
    String $ferm_srange = hiera('profile::elasticsearch::cirrus::ferm_srange'),
    String $certificate_name = hiera('profile::elasticsearch::cirrus::certificate_name'),
    String $storage_device = hiera('profile::elasticsearch::cirrus::storage_device'),
) {
    include ::profile::elasticsearch

    package {'wmf-elasticsearch-search-plugins':
        ensure => present,
        before => Service['elasticsearch'],
    }

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => $http_port,
        notrack => true,
        srange  => $ferm_srange,
    }

    ferm::service { 'elastic-https':
        proto  => 'tcp',
        port   => $tls_port,
        srange => $ferm_srange,
    }

    file { '/etc/udev/rules.d/elasticsearch-readahead.rules':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"128\"",
        notify  => Exec['elasticsearch_udev_reload'],
    }

    exec { 'elasticsearch_udev_reload':
        command     => '/sbin/udevadm control --reload && /sbin/udevadm trigger',
        refreshonly => true,
    }

    elasticsearch::tlsproxy { $cluster_name:
        certificate_name => $certificate_name,
        upstream_port    => $http_port,
        tls_port         => $tls_port,
    }

    # Install the hot threads collector
    elasticsearch::log::hot_threads_cluster { $cluster_name:
        http_port => $http_port,
    }
}
