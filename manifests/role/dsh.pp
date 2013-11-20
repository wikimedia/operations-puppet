# manifests/role/dsh.pp
# this sets up package and files for:
# dsh - distributed shell or dancer's shell
class role::dsh {

    system::role { 'role::dsh': description => 'dsh (distributed/dancer shell) server' }

    class { '::dsh': }

}
