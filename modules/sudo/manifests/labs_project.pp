class sudo::labs_project {
    require sudo

    if $::realm != 'labs' {
        fail('This class is labs-specific')
    }

    # Was handled via sudo ldap, now handled via puppet
    sudo::group { 'ops': privileges => ['ALL=(ALL) NOPASSWD: ALL'] }
    # Old way of handling this.
    sudo::group { $instanceproject: ensure => absent }
    # Another old way, before per-project sudo
    sudo::group { $projectgroup: ensure => absent }
}
