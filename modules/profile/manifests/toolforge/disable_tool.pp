class profile::toolforge::disable_tool (
    String $novaadmin_bind_dn = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    String $novaadmin_bind_pass = lookup('profile::openstack::base::ldap_user_dn')
) {
    file { '/etc/disable_tool.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('profile/toolforge/disable_tool.conf.erb'),
    }

    git::clone { 'cloud/toolforge/disable-tool':
        ensure    => latest,
        directory => '/srv/disable-tool',
    }
}
