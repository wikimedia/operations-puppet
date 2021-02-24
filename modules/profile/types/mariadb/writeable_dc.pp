type Profile::Mariadb::Writeable_DC = Enum[
    # Use the value from mediawiki::state('primary_dc')
    'mwprimary',
    'eqiad',
    'codfw',
    'both',
    'none',
]
