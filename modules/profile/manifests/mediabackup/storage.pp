# mediabackup storage hosts expose the api and store
# the files generated from the media backup workers.
class profile::mediabackup::storage (
    Hash $mediabackup_config              = lookup('mediabackup', Hash, 'hash'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
){
    class { 'mediabackup::storage':
        storage_path  => $mediabackup_config['storage_path'],
        port          => $mediabackup_config['storage_port'],
        root_user     => $mediabackup_config['storage_root_user'],
        root_password => $mediabackup_config['storage_root_password'],
    }
    nrpe::monitor_service { 'minio_server':
        description   => 'MinIO server processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C minio -a server',
        critical      => false,
        contact_group => 'admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Media_storage/Backups',
    }

    # Do not open the firewall to everyone if there are no available storage hosts
    if length($mediabackup_config['worker_hosts']) > 0 {
        $workers = join($mediabackup_config['worker_hosts'], ' ')
        $srange_workers = join(['@resolve((', $workers, '))'], ' ')
        ferm::service { 'minio-mediabackup-workers':
            proto   => 'tcp',
            port    => $mediabackup_config['storage_port'],
            notrack => true,
            srange  => $srange_workers,
        }
    }
    # firewall for prometheus metrics - metrics will require no authentication
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    $srange_prometheus = join(['@resolve((', $prometheus_nodes_ferm, '))'], ' ')
    ferm::service { 'minio-prometheus-monitoring':
        proto   => 'tcp',
        port    => $mediabackup_config['storage_port'],
        notrack => true,
        srange  => $srange_prometheus,
    }
}
