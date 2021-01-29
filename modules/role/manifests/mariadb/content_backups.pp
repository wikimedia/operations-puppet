# Class similar to mariadb::backups, except used for
# content (external storage database backups) only.
# They create regularly logical dumps of the configured
# set of sections (servers) for processing and Bacula.
# These, however, do not do snapshotting, and additionally
# are both client and storage daemons for Bacula.
class role::mariadb::content_backups {
    system::role { 'mariadb::content_backups':
        description => 'External store dumps and backups',
    }

    include ::profile::base::firewall
    include ::profile::standard

    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::snapshot
    include ::profile::backup::storage::es
    include ::profile::backup::host
    include ::profile::mariadb::backup::bacula_es
}
