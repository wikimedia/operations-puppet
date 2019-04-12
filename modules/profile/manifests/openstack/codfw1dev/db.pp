# at some point this class should inherit all the code currently present
# in profile::openstack::base::keystone::db
class profile::openstack::codfw1dev::db(
    Stdlib::Fqdn $cloudcontrol_fqdn = lookup('profile::openstack::codfw1dev::keystone_host'),
) {
    class { '::standard': }
    class { '::mariadb': }

    ferm::rule { 'cloudcontrol_mysql':
        ensure => 'present',
        rule   => "saddr (@resolve(${cloudcontrol_fqdn}) @resolve(${cloudcontrol_fqdn}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }
}
