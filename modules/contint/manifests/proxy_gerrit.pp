# A http proxy in front of Gerrit page
# Only meant to be used on labs
class contint::proxy_gerrit {

    if $::realm != 'labs' {
        fail( "contint::proxy_gerrit must only be used on labs")
    }

    file { '/etc/apache2/gerrit_proxy':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/contint/apache/proxy_gerrit',
    }
}

