class profile::toolforge::disable_tool (
    Hash   $ldap_config = lookup('ldap'),
    String $novaadmin_bind_dn = lookup('profile::openstack::base::ldap_user_dn'),
    String $novaadmin_bind_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    String $db_host = lookup('profile::toolforge::disable_tool::disable_tool_db_host'),
    String $db_password = lookup('profile::toolforge::disable_tool::disable_tool_db_password'),
) {
    $ldap_uri = "ldap://${ldap_config['rw-server']}:389"
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
