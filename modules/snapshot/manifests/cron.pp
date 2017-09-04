class snapshot::cron(
    $user = undef,
) {
    file { '/usr/local/etc/dump_functions.sh':
        ensure => 'present',
        path   => '/usr/local/etc/dump_functions.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump_functions.sh',
    }

    class { '::snapshot::cron::mediaperprojectlists': user => $user }
    class { '::snapshot::cron::pagetitles': user   => $user }
    class { '::snapshot::cron::cirrussearch': user   => $user }
    class { '::snapshot::cron::categoriesrdf': user   => $user }
    class { '::snapshot::cron::dumplists': user   => $user }
    class { '::snapshot::cron::dump_global_blocks': user   => $user }
    class { '::snapshot::cron::wikidatadumps::json': user   => $user }
    class { '::snapshot::cron::wikidatadumps::rdf': user   => $user }
    class { '::snapshot::cron::contentxlation': user   => $user }
    class { '::snapshot::addschanges': user   => $user }
}
