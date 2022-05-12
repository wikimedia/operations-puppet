# @summary class to managed ssh client config
# @param manage_ssh_keys indicate if we should manage the known_hosts file
class ssh::client (
    Boolean $manage_ssh_keys = true,
) {
    package { 'openssh-client':
        ensure => present,
    }

    if $manage_ssh_keys and $::use_puppetdb {
        file { '/etc/ssh/ssh_known_hosts':
            content => template('ssh/known_hosts.erb'),
            backup  => false,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
        }
    }
}
