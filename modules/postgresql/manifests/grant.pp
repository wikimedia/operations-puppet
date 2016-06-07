define postgresql::grant(
    $user,
    $db,
    $privileges,
    $tables      = undef,
    $schema      = undef,
    $options     = [],
    $unless      = undef,
    $ensure      = 'present',
) {
    if ($tables and !$schema) {
        $tablesSql = join($tables, ', ')
    } elsif (!$tables and $schema) {
        $tablesSql = "ALL TABLES IN SCHEMA ${schema}"
    } else {
        fail('postgresql::grant must receive either $tables or $schema parameters, not both or none')
    }
    $op = $ensure ? {
        'present' => 'GRANT',
        default   => 'REVOKE',
    }
    $fromTo = $ensure ? {
        'present' => 'TO',
        default   => 'FROM',
    }
    $query = "${op} " + join($privileges, ', ') + " ON ${tablesSql} ${fromTo} ${user} " + join($options, ' ')

    postgresql::query { $query:
        sql    => $query,
        unless => $unless,
    }
}
