class profile::openstack::eqiad1::galera::backup(
    String              $back_user             = lookup('profile::openstack::eqiad1::galera::backup_user'),
    String              $back_pass             = lookup('profile::openstack::eqiad1::galera::backup_password'),
    ) {

    class {'::profile::openstack::base::galera::backup':
        back_user => $back_user,
        back_pass => $back_pass,
    }
}
