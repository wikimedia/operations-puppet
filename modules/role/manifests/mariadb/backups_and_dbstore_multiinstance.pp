# Create mydumper logical backups using the dump_sections.py script
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# If we are on the active datacenter, also send the backups to the
# long-term storage.
# Additionally, host one or more local replicas of production
# databases
class role::mariadb::backups_and_dbstore_multiinstance {
    system::role { 'mariadb::backups':
        description => 'Databases dumps and backups plus dbstore multiinstance',
    }

    include ::profile::base::firewall
    include ::standard

    include ::profile::backup::host
    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::bacula

    include ::profile::mariadb::dbstore_multiinstance
}
