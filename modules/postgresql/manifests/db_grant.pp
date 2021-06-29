# @summary This class allows you to give a user table,
#   sequence and function privs for all entries in a db schema
# @param db The db to act on
# @param table_privs list of table_privs to grant
# @param role the role to grant table_privs to
# @param ensure ensurable parameter
define postgresql::db_grant(
    String                     $db,
    String                     $pg_role,
    Wmflib::Ensure             $ensure        = 'present',
    Postgresql::Priv::Table    $table_priv    = 'SELECT',
    Postgresql::Priv::Sequence $sequence_priv = 'USAGE',
    Postgresql::Priv::Function $function_priv = 'EXECUTE',
    String                     $schema        = 'public',
) {
    $grant_base = "%s ${table_priv} ON ALL %s IN SCHEMA \"${schema}\" %s ${pg_role}"
    $unless_table_priv = $table_priv ? {
        # has_table_privileges can't check for ALL so we assume INSERT is equivalent
        'ALL'   => 'INSERT',
        default => $table_priv,
    }
    $unless_sequence_priv = $table_priv ? {
        # has_sequences_privileges can't check for ALL so we assume UPDATE is equivalent
        'ALL'   => 'UPDATE',
        default => $sequence_priv,
    }
    $unless_execute_priv = 'EXECUTE'

    $grant_table_sql = $ensure ? {
        'absent' => $grant_base.sprintf('REVOKE', 'TABLES', 'FROM'),
        default  => $grant_base.sprintf('GRANT', 'TABLES', 'TO'),
    }
    $grant_sequence_sql = $ensure ? {
        'absent' => $grant_base.sprintf('REVOKE', 'SEQUENCES', 'FROM'),
        default  => $grant_base.sprintf('GRANT', 'SEQUENCES', 'TO'),
    }
    $grant_function_sql = $ensure ? {
        'absent' => $grant_base.sprintf('REVOKE', 'FUNCTIONS', 'FROM'),
        default  => $grant_base.sprintf('GRANT', 'FUNCTIONS', 'TO'),
    }
    $unless_table_sql = @("UNLESS_SQL"/L)
    SELECT 1 FROM pg_tables WHERE schemaname='public' AND \
    has_table_privilege('${pg_role}', schemaname || '.' || tablename, '${unless_table_priv}' ) = true;
    | UNLESS_SQL

    $unless_sequence_sql = @("SEQUENCE_SQL")
    SELECT 1 FROM information_schema.sequences WHERE schemaname='public' AND \
    has_sequence_privilege('${pg_role}', schemaname || '.' || tablename, '${unless_sequence_priv}' ) = true;
    | SEQUENCE_SQL

    $unless_function_sql = @("FUNCTION_SQL")
    SELECT 1 FROM pg_catalog.pg_proc p
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname='public' AND
    has_function_privilege('${pg_role}', p.oid, '${unless_sequence_priv}' ) = true;
    | FUNCTION_SQL

    $command_base = "/usr/bin/psql --tuples-only --no-align  -c '%s' ${db}"
    $unless_base  = "/usr/bin/psql --tuples-only --no-align  -c '%s' ${db} | grep 1"


    exec {"db_grant: exec table grants ${title}":
        user    => 'postgres',
        command => $command_base.sprintf($grant_table_sql),
        unless  => $unless_base.sprintf($unless_table_sql)
    }
    exec {"db_grant: exec sequence grants ${title}":
        user    => 'postgres',
        command => $command_base.sprintf($grant_sequence_sql),
        unless  => $unless_base.sprintf($unless_sequence_sql)
    }
    exec {"db_grant: exec function grants ${title}":
        user    => 'postgres',
        command => $command_base.sprintf($grant_function_sql),
        unless  => $unless_base.sprintf($unless_function_sql)
    }
}
