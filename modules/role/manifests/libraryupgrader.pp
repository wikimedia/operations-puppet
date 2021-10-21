# sets up libraryupgrader
# https://www.mediawiki.org/wiki/Libraryupgrader
class role::libraryupgrader {

    system::role { 'libraryupgrader':
        description => 'libraryupgrader instance'
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::libraryupgrader
}
