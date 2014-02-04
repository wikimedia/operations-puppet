#class for sudo on labs
class sudo::labs{

    if $::realm == 'labs' {
        include sudo::default

        # Was handled via sudo ldap, now handled via puppet
        sudo::group { 'ops':
            privileges => ['ALL=(ALL) NOPASSWD: ALL'],
        }
    }
}

