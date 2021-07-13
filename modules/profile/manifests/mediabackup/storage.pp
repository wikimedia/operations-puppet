# mediabackup storage hosts expose the api and store
# the files generated from the media backup workers.
class profile::mediabackup::storage (
    Hash $mediabackup_config = lookup('mediabackup', Hash, 'hash'),
){
    class { 'mediabackup::storage': }

    # we will likely want to open the firewall based on worker_hosts
}
