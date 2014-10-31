#

class { 'bacula::director':
    sqlvariant          => 'mysql',
    max_dir_concur_jobs => '10',
}

bacula::director::catalog { 'MYDB':
    dbname     => 'bacula',
    dbuser     => 'bacula',
    dbhost     => 'bacula-db.example.org',
    dbport     => '3306',
    dbpassword => 'bacula',
}

bacula::director::schedule { 'Monthly-Sat':
    runs => [
                { 'level' => 'Full', 'at' => '1st Sat at 06:00', },
                { 'level' => 'Differential', 'at' => '2nd Sat at 06:00', },
            ],
}

bacula::director::pool { 'mypool':
    max_vols         => 10,
    storage          => 'mystor',
    volume_retention => '20 days',
}

bacula::director::fileset { 'root-var':
    includes => [ '/', '/var',],
    excludes => [ '/tmp', ],
}

bacula::director::jobdefaults { '1st-sat-mypool':
    when => 'Monthly-Sat',
    pool => 'mypool',
}

