define postgresql::grant(
    $user,
    $database,
    $privileges,
    $schema            = undef,
    $in_database_scope = false,
    $options           = '',
    $ensure            = 'present',
) {
    $tables = $in_database_scope ? {
        true  => "DATABASE ${database}",
        false => "ALL TABLES IN SCHEMA ${schema}",
    }
    $op = $ensure ? {
        'present' => 'GRANT',
        default   => 'REVOKE',
    }
    $fromTo = $ensure ? {
        'present' => 'TO',
        default   => 'FROM',
    }
    $query_grant = "${op} ${privileges} ON ${tables} ${fromTo} ${user} ${options}"
    $query_defaults = "ALTER DEFAULT PRIVILEGES ${op} ${privileges} ON TABLES ${fromTo} ${user} ${options}"

    $query = $in_database_scope ? {
        true  => $query_grant,
        false => "${query_grant}; ${query_defaults};"
    }

    postgresql::query { $query:
        sql      => $query,
        database => $database,
    }
}
