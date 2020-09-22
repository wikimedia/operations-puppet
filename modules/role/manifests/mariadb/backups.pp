# Create weekly mydumper logical backups and daily xtrabackup
# snapshots using the mariadb_backup.py script
# of all production core metadata (s*, x*) and misc (m*) hosts.
# Content (es) backups are done separately with
# mariadb::content_backups, as they don't do snapshotting and
# require additional space due to extra size.
# Do that using a cron job on all backup hosts, all datacenters +
# the cron on cluster management hosts.
# If we are on the active datacenter, also send the latest logical
# backups to the long-term storage. In the future, we will want
# to send them to both, in a cross-dc way.
class role::mariadb::backups {
    system::role { 'mariadb::backups':
        description => 'Databases dumps and backups',
    }

    include ::profile::base::firewall
    include ::profile::standard

    include ::profile::backup::host
    include ::profile::mariadb::wmfmariadbpy
    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::snapshot
    include ::profile::mariadb::backup::bacula
}
