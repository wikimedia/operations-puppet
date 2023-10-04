class profile::toolforge::disable_tool (
    Hash   $ldap_config = lookup('ldap'),
    String $novaadmin_bind_dn = lookup('profile::openstack::base::ldap_user_dn'),
    String $novaadmin_bind_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    String $tools_db_host = lookup('profile::toolforge::disable_tool::disable_tool_db_host'),
    String $tools_db_password = lookup('profile::toolforge::disable_tool::disable_tool_db_password'),
) {
    $ldap_uri = "ldap://${ldap_config['rw-server']}:389"

    ensure_packages(['python3-pymysql'])

    file { '/etc/disable_tool.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('profile/toolforge/disable_tool.conf.erb'),
    }
    git::clone { 'repos/cloud/toolforge/disable-tool':
        ensure    => latest,
        source    => 'gitlab',
        directory => '/srv/disable-tool',
    }
}
