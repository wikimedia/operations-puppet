# mediabackup storage hosts expose the api and store
# the files generated from the media backup workers.
class profile::mediabackup::storage (
    Hash $mediabackup_config = lookup('mediabackup', Hash, 'hash'),
){
    class { 'mediabackup::storage': }

    # Do not open the firewall to everyone if there are no available storage hosts
    if length($mediabackup_config['worker_hosts']) > 0 {
        $workers = $mediabackup_config['worker_hosts'].map |Stdlib::Fqdn $host| { "@resolve((${host}))" }
        $srange = join($workers, ' ')
        ferm::service { 'mediabackup-workers':
            proto   => 'tcp',
            port    => $mediabackup_config['storage_port'],
            notrack => true,
            srange  => $srange,
        }
    }
}
