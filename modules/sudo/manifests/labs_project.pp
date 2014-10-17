class sudo::labs_project {
    if $::realm != 'labs' {
        fail('This class is labs-specific')
    }
    # labs specific sudo default
    file { '/etc/sudoers':
        owner  => root,
        group  => root,
        mode   => '0440',
        source => 'puppet:///modules/sudo/sudoers.labs';
    }

    # Was handled via sudo ldap, now handled via puppet
    sudo::group { 'ops': privileges => ['ALL=(ALL) NOPASSWD: ALL'] }
    # Old way of handling this.
    sudo::group { $instanceproject: ensure => absent }
    # Another old way, before per-project sudo
    sudo::group { $projectgroup: ensure => absent }
}
