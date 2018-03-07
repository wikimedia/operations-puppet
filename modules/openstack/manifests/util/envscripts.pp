# Scripts to set up shell environment for openstack commandline
class openstack::util::envscripts(
    $ldap_user_pass,
    $nova_controller,
    $region,
    $nova_db_pass,
    $wmflabsdotorg_admin,
    $wmflabsdotorg_pass,
    $wmflabsdotorg_project,
    ) {

    # Keystone credentials for novaadmin
    file { '/etc/novaadmin.yaml':
        content => template('openstack/util/novaadmin.yaml.erb'),
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
    }

    # Handy script to set up environment for commandline nova magic
    file { '/root/novaenv.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/openstack/util/novaenv.sh',
        require => File['/etc/novaadmin.yaml'],
    }

    # Handy script to set up environment for commandline glance magic
    # TODO: convert to yaml + wrapper script
    file { '/root/wmflabsorg-domainadminenv.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('openstack/util/wmflabsorg-domainadminenv.sh.erb'),
    }
}
