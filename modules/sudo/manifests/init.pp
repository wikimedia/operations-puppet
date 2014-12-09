class sudo {
    if $::realm == 'labs' {
        # We use sudo-ldap, defined elsewhere.
    } else {
        package { 'sudo':
            ensure => installed,
        }
    }
}
