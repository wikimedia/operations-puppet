class snapshot::cron(
    $depr_user = undef,
    $miscdumpsuser = undef,
    $group = undef,
) {
    # these jobs all run as a deprecated user on the web server.
    # we will move them all to the new user on the internal nfs
    # server one at a time.

    file { '/usr/local/etc/dump_functions.sh':
        ensure => 'present',
        path   => '/usr/local/etc/dump_functions.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump_functions.sh',
    }

    class { '::snapshot::cron::mediaperprojectlists': user => $miscdumpsuser }
    class { '::snapshot::cron::pagetitles': user   => $miscdumpsuser }
    class { '::snapshot::cron::cirrussearch': user   => $miscdumpsuser }
    class { '::snapshot::cron::categoriesrdf': user   => $miscdumpsuser }
    class { '::snapshot::cron::dump_global_blocks': user   => $miscdumpsuser }
    class { '::snapshot::cron::wikidatadumps':
        user  => $depr_user,
        group => $group,
    }
    class { '::snapshot::cron::contentxlation': user   => $depr_user }
    class { '::snapshot::addschanges': user   => $miscdumpsuser }
}
