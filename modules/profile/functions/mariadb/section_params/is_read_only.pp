function profile::mariadb::section_params::is_read_only(
    Profile::Mariadb::Valid_section $section,
    Profile::Mariadb::Role $role,
) >> Boolean {
    if profile::mariadb::section_params::writeable_dc($section) == 'none' {
        true
    } else {
        $writeable_dc = profile::mariadb::section_params::is_writeable_dc($section)
        $role ? {
            'standalone' => $writeable_dc,
            'slave' => true,
            'master' => !$writeable_dc,
            default => fail("Unsupported mysql_role: ${role}"),
        }
    }
}
