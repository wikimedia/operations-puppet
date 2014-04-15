# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the
# manifests
class puppetmaster::scripts {
    file {
        '/usr/local/bin/uuid-generator':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/puppetmaster/uuid-generator';
        '/usr/local/bin/naggen':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/puppetmaster/naggen';
        '/usr/local/sbin/puppetstoredconfigclean.rb':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/puppetmaster/puppetstoredconfigclean.rb';
        '/usr/local/bin/puppet-merge':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/puppetmaster/puppet-merge';
    }

    # Clear out reports older than 36 hours.
    cron { 'removeoldreports':
        ensure  => present,
        command => 'find /var/lib/puppet/reports -type f -mmin +2160 -delete',
        user    => puppet,
        hour    => [4,16],
        minute  => 27,
    }

}
