# mediawiki base mw deploy user
class mediawiki::users::mwdeploy {

    ## mwdeploy user
    if $::realm != 'labs' {
        generic::systemuser { 'mwdeploy': name => 'mwdeploy' }
    } else {
        # User created in LDAP
        file { '/var/lib/mwdeploy':
            ensure => directory,
            owner  => 'mwdeploy',
            group  => 'mwdeploy',
            mode   => '0755',
        }
    }

}
