function profile::mariadb::section_params::load_param(
    Profile::Mariadb::Valid_section $section,
    String $param,
) >> String {
    $all_sections = lookup('profile::mariadb::section_params')
    $def_params = $all_sections["_defaults_"]
    if has_key($all_sections, $section) {
        pick($all_sections[$section][$param], $def_params[$param])
    } else {
        $def_params[$param]
    }
}
