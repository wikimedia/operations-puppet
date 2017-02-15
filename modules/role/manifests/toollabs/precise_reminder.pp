# Sets up a cron to send weekly nag emails to precise users
# to migrate their tools before precise deprecation in March 2017
#
# This is temporary role, being applied to tools-bastion-03
# and can be removed after the Precise deprecation
#
# filtertags: labs-project-tools
class role::toollabs::precise_reminder {

    file { '/usr/local/sbin/precise-reminder':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/precise_reminder.py',
    }

    cron { 'precise-reminder':
        ensure      => 'present',
        user        => 'root',
        command     => '/usr/local/sbin/precise-reminder',
        weekday     => 3,
        hour        => 22,
        minute      => 15,
        environment => 'MAILTO=labs-admin@lists.wikimedia.org',
        require     => File['/usr/local/sbin/precise-reminder'],
    }

}
