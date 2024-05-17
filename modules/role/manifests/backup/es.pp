# Storage daemons for Bacula, specific to ES database backups.
class role::backup::es {
    include profile::firewall
    include profile::base::production

    include profile::backup::storage::es
}
