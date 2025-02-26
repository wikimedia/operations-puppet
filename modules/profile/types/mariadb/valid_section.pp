type Profile::Mariadb::Valid_section = Enum[
    # MediaWiki metadata
    's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8',
    # MediaWiki extension data
    'x1',
    # MainStash data
    'x2', 'ms1', 'ms2', 'ms3',
    # MediaWiki page content (External Storage)
    'es1', 'es2', 'es3', 'es4', 'es5', 'es6', 'es7',
    # MediaWiki ParserCache
    'pc1', 'pc2', 'pc3', 'pc4','pc5','pc6','pc7',
    # Misc
    'm1', 'm2', 'm3', 'm5', 'backup1-eqiad', 'backup1-codfw',
    # Test
    'test-s1', 'test-s4',
    # Analytics
    'analytics_meta', 'matomo', 'staging',
    # Tendril/Zarcillo
    'tendril', 'zarcillo',
]
