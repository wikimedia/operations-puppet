class snapshot::cron(
    $miscdumpsuser = undef,
    $group = undef,
) {
    file { '/usr/local/etc/dump_functions.sh':
        ensure => 'present',
        path   => '/usr/local/etc/dump_functions.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump_functions.sh',
    }

    class { '::snapshot::cron::mediaperprojectlists': user => $miscdumpsuser }
    class { '::snapshot::cron::pagetitles': user => $miscdumpsuser }
    class { '::snapshot::cron::cirrussearch': user => $miscdumpsuser }
    class { '::snapshot::cron::categoriesrdf': user => $miscdumpsuser }
    class { '::snapshot::cron::dump_global_blocks': user => $miscdumpsuser }
    class { '::snapshot::cron::wikidatadumps':
        user  => $miscdumpsuser,
        group => $group,
    }
    class { '::snapshot::cron::contentxlation': user => $miscdumpsuser }
    class { '::snapshot::addschanges': user => $miscdumpsuser }
}
