# Scripts to set up shell environment for openstack commandline
class openstack::envscripts(
    $novaconfig,
    $designateconfig
    ) {

    # Handy script to set up environment for commandline nova magic
    file { '/root/novaenv.sh':
        content => template('openstack/novaenv.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    # Handy script to set up environment for commandline nova magic
    file { '/root/designateenv.sh':
        content => template('openstack/designateenv.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }
}
