# @summary class to managed ssh client config
# @param manage_ssh_keys indicate if we should manage the known_hosts file
class profile::ssh::client (
    Boolean $manage_ssh_keys = lookup('profile::ssh::client::manage_ssh_keys'),
) {
    class { 'ssh::client':
        * => wmflib::dump_params(),
    }
}
