# == Class profile::alluxio::worker
# Configures an alluxio worker node
#
class profile::alluxio::worker(

    Array[Stdlib::Fqdn] $alluxio_worker_hosts = lookup('profile::alluxio::worker_hosts'),
    Array[Stdlib::Fqdn] $alluxio_master_hosts = lookup('profile::alluxio::master_hosts')

) {
    require ::profile::alluxio::common

    $alluxio_host_srange = "@resolve((${join($alluxio_worker_hosts, ' ')})) @resolve((${join($alluxio_master_hosts, ' ')}))"

    # The /etc/init.d/alluxio-worker script isn't great, so
    # we're not defining the service for now and starting the services manually.
    # service { 'alluxio-worker':
    #     ensure => running,
    # }

    # Alluxio worker RPC port
    ferm::service { 'alluxio-worker-rpc':
        proto  => 'tcp',
        port   => '29999',
        srange => $alluxio_host_srange,
    }

    # Alluxio job worker RPC port
    ferm::service { 'alluxio-job-worker-rpc':
        proto  => 'tcp',
        port   => '30001',
        srange => $alluxio_host_srange,
    }

    # Alluxio job worker data port
    ferm::service { 'alluxio-job-worker-data':
        proto  => 'tcp',
        port   => '30002',
        srange => $alluxio_host_srange,
    }
}
