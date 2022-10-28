# SPDX-License-Identifier: Apache-2.0
# mediabackup worker installs the software and sets up
# the schedule needed to trigger the generation and
# recovery of media (swift) backups for wikis.
class profile::mediabackup::worker (
    Hash $mediabackup_config = lookup('mediabackup'),
){
    # Setup the media backups worker in production.
    # Some of the static configuration used here should probably
    # be moved later to the db to allow for more dynamic
    # configuration.
    class { 'mediabackup::worker':
        mw_db_host            => $mediabackup_config['mw_db_host'],
        mw_db_port            => $mediabackup_config['mw_db_port'],
        mw_db_user            => $mediabackup_config['mw_db_user'],
        mw_db_password        => $mediabackup_config['mw_db_password'],
        dblist                => $mediabackup_config['dblist'],
        wiki                  => $mediabackup_config['wiki'],
        batchsize             => $mediabackup_config['batchsize'],
        db_host               => $mediabackup_config['db_host'],
        db_port               => $mediabackup_config['db_port'],
        db_user               => $mediabackup_config['db_user'],
        db_password           => $mediabackup_config['db_password'],
        db_schema             => $mediabackup_config['db_schema'],
        encryption_key        => $mediabackup_config['encryption_key'],
        storage_root_user     => $mediabackup_config['storage_root_user'],
        storage_root_password => $mediabackup_config['storage_root_password'],
        storage_hosts         => $mediabackup_config['storage_hosts'],
        storage_port          => $mediabackup_config['storage_port'],
        access_key            => $mediabackup_config['access_key'],
        secret_key            => $mediabackup_config['secret_key'],
        recovery_access_key   => $mediabackup_config['recovery_access_key'],
        recovery_secret_key   => $mediabackup_config['recovery_secret_key'],
    }
}
