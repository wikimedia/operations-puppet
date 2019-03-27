# Create weekly mydumper logical backups and daily xtrabackup
# snapshots using the mariadb_backup.py script
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters +
# the cron on cluster management hosts.
# If we are on the active datacenter, also send the latest logical
# backups to the long-term storage.
class role::mariadb::backups {
    system::role { 'mariadb::backups':
        description => 'Databases dumps and backups',
    }

    include ::profile::base::firewall
    include ::standard

    include ::profile::backup::host
    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::snapshot
    include ::profile::mariadb::backup::bacula
}
