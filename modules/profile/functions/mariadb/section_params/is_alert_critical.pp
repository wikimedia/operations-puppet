function profile::mariadb::section_params::is_alert_critical(
    Profile::Mariadb::Valid_section $section,
    Profile::Mariadb::Role $role,
) >> Boolean {
    case $role {
        'slave', 'master': {
            profile::mariadb::section_params::is_writeable_dc($section)
        }
        'standalone': {
            # Hack for es{1,2,3}
            $::site == mediawiki::state('primary_dc')
        }
        default: {
            fail("Unsupported mysql_role: ${role}")
        }
    }
}
