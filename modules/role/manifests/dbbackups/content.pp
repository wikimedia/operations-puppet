# Class similar to dbbackups::metadata, except used for
# content (external storage database backups) only.
# They create regularly logical dumps of the configured
# set of sections (servers) for processing and Bacula.
# These, however, do not do snapshotting.
# Additionally, add the client daemon for Bacula and
# setup its backup to the corresponding long term storage.
class role::dbbackups::content {
    system::role { 'dbbackups::content':
        description => 'External Storage dumps',
    }

    include ::profile::base::firewall
    include ::profile::standard

    include ::profile::dbbackups::mydumper
    include ::profile::dbbackups::snapshot
    include ::profile::backup::host
    include ::profile::dbbackups::bacula_es
}
