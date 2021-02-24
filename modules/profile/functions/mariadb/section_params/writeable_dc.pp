function profile::mariadb::section_params::writeable_dc(
    Profile::Mariadb::Valid_section $section,
) >> Profile::Mariadb::Writeable_DC {
    profile::mariadb::section_params::load_param($section, 'writeable_dc')
}
