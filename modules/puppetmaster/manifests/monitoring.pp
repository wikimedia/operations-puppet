# This class collects all alerts and metrics collection monitoring
# for the puppemaster module.

class puppetmaster::monitoring () {

    # Check for unmerged changes that have been sitting for more than one minute.
    # ref: RT #1658, #7427
    file { 'check_puppet-needs-merge':
        ensure => present,
        path   => '/usr/local/lib/nagios/plugins/check_puppet-needs-merge',
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/check_puppet-needs-merge';
    }

    nrpe::monitor_service { 'puppet_merged':
        description  => 'Unmerged changes on puppet master',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_puppet-needs-merge',
        require      => File['check_puppet-needs-merge']
    }

}
