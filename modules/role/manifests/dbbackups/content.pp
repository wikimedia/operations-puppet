# Class similar to dbbackups::metadata, except used for
# content (external storage database backups) only.
# They create regularly logical dumps of the configured
# set of sections (servers) for processing and Bacula.
# These, however, do not do snapshotting, and additionally
# are both client and storage daemons for Bacula.
class role::dbbackups::content {
    system::role { 'dbbackups::content':
        description => 'External store dumps and backups',
    }

    include ::profile::base::firewall
    include ::profile::standard

    include ::profile::dbbackups::mydumper
    include ::profile::dbbackups::snapshot
    include ::profile::backup::storage::es
    include ::profile::backup::host
    include ::profile::dbbackups::bacula_es
}
