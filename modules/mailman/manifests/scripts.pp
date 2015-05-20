# helper scripts for mailman admins
class mailman::scripts {

    file { '/var/lib/mailman/bin/remove_from_private':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0540',
        source => 'puppet:///modules/mailman/remove_from_private.sh'
    }

}
