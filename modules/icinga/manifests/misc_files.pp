
class icinga::misc_files {
# Required files and directories
# Must be loaded last

    file { '/etc/icinga/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/cache/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0775',
    }

    file { '/var/lib/nagios/rw':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0777',
    }

    file { '/var/lib/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0755',
    }

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///files/icinga/purge-nagios-resources.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # fix permissions on all individual service files
    exec { 'fix_nagios_perms':
        command => '/bin/chmod -R a+r /etc/nagios';
    }
    exec { 'fix_icinga_perms':
        command => '/bin/chmod -R a+r /etc/icinga';
    }
    exec { 'fix_icinga_temp_files':
        command => '/bin/chown -R icinga /var/lib/icinga';
    }
    exec { 'fix_nagios_plugins_files':
        command => '/bin/chmod -R a+w /var/lib/nagios';
    }
    exec { 'fix_icinga_command_file':
        command => '/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd';
    }
}

