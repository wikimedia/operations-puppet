# mediabackup storage hosts expose the api and store
# the files generated from the media backup workers.
class profile::mediabackup::storage (
    Hash $mediabackup_config = lookup('mediabackup', Hash, 'hash'),
){
    class { 'mediabackup::storage':
        storage_path  => $mediabackup_config['storage_path'],
        port          => $mediabackup_config['storage_port'],
        root_user     => $mediabackup_config['storage_root_user'],
        root_password => $mediabackup_config['storage_root_password'],
    }
    nrpe::monitor_service { 'minio_server':
        description   => 'MinIO server processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C "/usr/local/bin/minio server"',
        critical      => false,
        contact_group => 'admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Media_storage/Backups',
    }

    # Do not open the firewall to everyone if there are no available storage hosts
    if length($mediabackup_config['worker_hosts']) > 0 {
        $workers = join($mediabackup_config['worker_hosts'], ' ')
        $srange = join(['@resolve((', $workers, '))'], ' ')
        ferm::service { 'mediabackup-workers':
            proto   => 'tcp',
            port    => $mediabackup_config['storage_port'],
            notrack => true,
            srange  => $srange,
        }
    }
}
