# mark_tool is a simple script for marking a tool as disabled, deleted, or enabledin ldap.
#
# Installing this in cloudcontrol nodes because that's a safe place to keep the global ldap
#  password.
#
class profile::toolforge::mark_tool (
    String $novaadmin_bind_dn = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    String $novaadmin_bind_pass = lookup('profile::openstack::base::ldap_user_dn')
) {
    file { '/etc/mark_tool.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('profile/toolforge/mark_tool.conf.erb'),
    }

    file { '/usr/local/bin/mark_tool':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/profile/toolforge/mark_tool.py',
    }
}
