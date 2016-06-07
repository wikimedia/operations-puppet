define postgresql::grant(
    $user,
    $database,
    $privileges,
    $tables      = undef,
    $schema      = undef,
    $options     = '',
    $unless      = undef,
    $ensure      = 'present',
) {
    if ($tables and !$schema) {
        $tablesSql = join($tables, ', ')
    } elsif (!$tables and $schema) {
        $tablesSql = 'TABLES'
    } elsif (!$tables and !$schema) {
        $tablesSql = "DATABASE ${database}"
    } else {
        fail('postgresql::grant cannot be passed both $tables and $schema parameters')
    }
    $op = $ensure ? {
        'present' => 'GRANT',
        default   => 'REVOKE',
    }
    $fromTo = $ensure ? {
        'present' => 'TO',
        default   => 'FROM',
    }
    $query = "${preOp}${op} ${privileges} ON ${tablesSql} ${fromTo} ${user} ${options}"

    postgresql::query { $query:
        sql      => $query,
        database => $database,
        unless   => $unless,
    }
}
