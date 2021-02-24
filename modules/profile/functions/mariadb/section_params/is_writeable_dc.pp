function profile::mariadb::section_params::is_writeable_dc(
    Profile::Mariadb::Valid_section $section,
) >> Boolean {
    $dc = profile::mariadb::section_params::writeable_dc($section)
    $dc ? {
        'mwprimary' => $::site == mediawiki::state('primary_dc'),
        'eqiad' => $::site == $dc,
        'codfw' => $::site == $dc,
        'both' => true,
        'none' => false,
        default => fail("Unsupported writeable_dc type: ${dc}"),
    }
}
