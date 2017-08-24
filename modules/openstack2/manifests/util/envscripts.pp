# Scripts to set up shell environment for openstack commandline
class openstack2::util::envscripts(
    $ldap_user_pass,
    $nova_controller,
    $region,
    $nova_db_pass,
    $wmflabsdotorg_admin,
    $wmflabsdotorg_pass,
    $wmflabsdotorg_project,
    ) {

    # Handy script to set up environment for commandline nova magic
    file { '/root/novaenv.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('openstack2/util/novaenv.sh.erb'),
    }

    # Handy script to set up environment for commandline glance magic
    file { '/root/wmflabsorg-domainadminenv.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('openstack2/util/wmflabsorg-domainadminenv.sh.erb'),
    }
}
