# miscellaneous services clusters
class role::mariadb::misc {
    include profile::base::production
    include profile::firewall
    include profile::mariadb::misc
}
