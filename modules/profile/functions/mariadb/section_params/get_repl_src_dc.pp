function profile::mariadb::section_params::get_repl_src_dc(Profile::Mariadb::Role $role) >> String {
    $other_site = $site ? {
        'codfw' => 'eqiad',
        'eqiad' => 'codfw',
        default => '(undefined)'
    }
    $role ? {
        'slave' => $::site,
        # Assumes this function will only be called if is_repl_client() returned true.
        'master' => $other_site,
        default => fail("Unsupported role type: ${role}"),
    }
}
