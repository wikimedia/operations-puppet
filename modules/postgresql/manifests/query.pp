define postgresql::query(
    $sql,
    $db,
    $unless = undef,
    $user   = 'postgres',
) {
    $unlessCmd = $unless ? {
        undef   => undef,
        default => "/usr/bin/psql -d ${db} -c \"${unless}\"",
    }
    exec { $sql:
        command => "/usr/bin/psql -d ${db} -c \"${sql}\"",
        unless  => $unlessCmd,
        user    => $user,
    }
}
