# Create weekly mydumper logical backups and daily xtrabackup
# snapshots using the mariadb_backup.py script
# of all production core metadata (s*, x*) and misc (m*) hosts.
# Content (es) backups are done separately with
# dbbackups::content, as they don't do snapshotting and
# require additional space due to extra size.
# Do that using a cron job on all backup hosts, all datacenters +
# the cron on cluster management hosts.
# If we are on the active datacenter, also send the latest logical
# backups to the long-term storage. In the future, we will want
# to send them to both, in a cross-dc way.
class role::dbbackups::metadata {
    include profile::firewall
    include profile::base::production

    include profile::backup::host
    include profile::mariadb::wmfmariadbpy
    include profile::dbbackups::mydumper
    include profile::dbbackups::snapshot
    include profile::dbbackups::bacula
}
