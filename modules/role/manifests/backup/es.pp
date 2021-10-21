# Storage daemons for Bacula, specific to ES database backups.
class role::backup::es {
    system::role { 'backup::es':
        description => 'External Storage database backups',
    }

    include ::profile::base::firewall
    include ::profile::base::production

    include ::profile::backup::storage::es
}
