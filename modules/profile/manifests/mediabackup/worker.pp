# mediabackup worker installs the software and sets up
# the schedule needed to trigger the generation and
# recovery of media (swift) backups for wikis.
class profile::mediabackup::worker (
    Hash $mediabackup_config = lookup('mediabackup', Hash, 'hash'),
){
    class { 'mediabackup::worker':
        db_host       => $mediabackup_config['db_host'],
        db_port       => $mediabackup_config['db_port'],
        db_user       => $mediabackup_config['db_user'],
        db_password   => $mediabackup_config['db_password'],
        db_schema     => $mediabackup_config['db_schema'],
        storage_hosts => $mediabackup_config['storage_hosts'],
    }
}
