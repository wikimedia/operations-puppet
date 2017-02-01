# Sets up a cron to send weekly nag emails to precise users
# to migrate their tools before precise deprecation in March 2017
#
# This is temporary role, being applied to tools-bastion-03
# and can be removed after the Precise deprecation

class role::toollabs::precise_nagger {

    file { '/usr/local/sbin/precise-nagger':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/precise_nagger.py',
    }

    cron { 'precise-nagger':
        ensure      => 'present',
        user        => 'root',
        command     => 'tail -500000 /data/project/.system/accounting | /usr/local/sbin/precise-nagger',
        weekday     => 3,
        hour        => 22,
        minute      => 0,
        environment => 'MAILTO=labs-admin@lists.wikimedia.org',
        require     => File['/usr/local/sbin/precise-nagger'],
    }

}
