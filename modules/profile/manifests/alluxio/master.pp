# == Class profile::alluxio::master
# Configures an alluxio master node
#
class profile::alluxio::master(

    Array[Stdlib::Fqdn] $alluxio_worker_hosts = lookup('profile::alluxio::worker_hosts')

) {
    require ::profile::alluxio::common

    $alluxio_worker_host_srange = "@resolve((${join($alluxio_worker_hosts, ' ')}))"

    # The /etc/init.d/alluxio-master script isn't great, so
    # we're disabling the service for now and starting the services manually.
    # service { 'alluxio-master':
    #     ensure => running,
    # }

    # Alluxio master RPC port
    ferm::service { 'alluxio-master-rpc':
        proto  => 'tcp',
        port   => '19998',
        srange => $alluxio_worker_host_srange,
    }

    # Alluxio job master RPC port
    ferm::service { 'alluxio-job-master-rpc':
        proto  => 'tcp',
        port   => '20001',
        srange => $alluxio_worker_host_srange,
    }
}
