function profile::mariadb::section_params::is_repl_client(
    Profile::Mariadb::Valid_section $section,
    Profile::Mariadb::Role $role,
) >> Boolean {
    case $role {
        'standalone': {
            false
        }
        'slave': {
            true
        }
        'master': {
            $repl_type = profile::mariadb::section_params::replication_type($section)
            $repl_type ? {
                'none' => false,
                'bidir' => true,
                'unidir' => !profile::mariadb::section_params::is_writeable_dc($section),
                default => fail("Unsupported inter-dc replication type: ${repl_type}"),
            }
        }
        default: {
            fail("Unsupported mysql_role: ${role}")
        }
    }
}
