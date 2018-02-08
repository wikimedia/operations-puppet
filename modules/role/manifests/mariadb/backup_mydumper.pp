# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# If we are on the active datacenter, also send the backups to the
# long-term storage.
class role::mariadb::backup_mydumper {
    include ::profile::backup::host
    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::bacula
}
