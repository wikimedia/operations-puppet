define postgresql::query(
    $sql,
    $database,
    $unless = undef,
    $user   = 'postgres',
) {
    $unlessCmd = $unless ? {
        undef   => undef,
        default => "/usr/bin/psql -d ${database} -c \"${unless}\"",
    }
    exec { $sql:
        command => "/usr/bin/psql -d ${database} -c \"${sql}\"",
        unless  => $unlessCmd,
        user    => $user,
    }
}
