# === Class etcd::auth::users
#
# Creates the base users.
#
# Should be applied to a single host, as there is no need for
# redundance of this class
class etcd::auth::users {
    require ::etcd::auth::common
    if $::etcd::auth::common::active {
        etcd_user { 'root':
            password => $::etcd::auth::common::root_password,
            roles    => ['root'],
            require  => Etcd::Client::Config['/root/.etcdrc'],
            before   => Exec['Etcd enable auth'],
        }

        # Guests should be read-only
        etcd_role { 'guest':
            ensure => present,
            acls   => {
                '*' => 'R',
            },
            before => Exec['Etcd enable auth'],
        }
    } else {
        etcd_user { 'root':
            ensure  => absent,
            require => Exec['Etcd disable auth'],
        }

    }
}
