function profile::mariadb::section_params::replication_type(
    Profile::Mariadb::Valid_section $section,
) >> Profile::Mariadb::InterDC_Replication_Type {
    profile::mariadb::section_params::load_param($section, 'replication_type')
}
