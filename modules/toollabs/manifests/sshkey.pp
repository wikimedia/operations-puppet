include stdlib

define toollabs::sshkey {
    $sshkeys = hiera('toollabs::sshkey')

    if has_key($sshkeys, $name) {
        ssh::userkey { $name:
            ensure => present,
            content => $sshkeys[$name]
        }
    }
}
