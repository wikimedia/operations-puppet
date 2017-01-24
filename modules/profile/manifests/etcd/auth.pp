# == Class profile::etcd::auth
#
# Configures etcd's builtin auth system. Since this causes some performance issues,
# it is actually deprecated and profile::etcd::proxy should be used instead.
class profile::etcd::auth(
    $enabled = hiera('profile::etcd::auth::enabled', false),
    $root_password = hiera('etcd::auth::common::root_password', undef),
){
    class { '::etcd::auth::common':
        root_password => $root_password,
        active        => $enabled,
    }

    class { '::etcd::auth': }
    class { '::etcd::auth::users': }

}
