# sets up libraryupgrader
# https://www.mediawiki.org/wiki/Libraryupgrader
class role::libraryupgrader {
    include profile::base::production
    include profile::firewall
    include profile::libraryupgrader
}
