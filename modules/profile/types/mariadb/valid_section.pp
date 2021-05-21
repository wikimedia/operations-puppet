type Profile::Mariadb::Valid_section = Enum[
    # Mediawiki metadata
    's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8',
    # Wikitech - hosted in m5, does not appear in puppet T258376
    #'s10',
    # labtestwiki - hosted on clouddb2001-dev, does not appear in puppet T258376
    #'s11',
    # Mediawiki extension data
    'x1',
    # MainStash data
    'x2',
    # Mediawiki page content (External Storage)
    'es1', 'es2', 'es3', 'es4', 'es5',
    # Mediawiki ParserCache
    'pc1', 'pc2', 'pc3',
    # Misc
    'm1', 'm2', 'm3', 'm5',
    # Test
    'test-s1', 'test-s4', 'test-pc1',
    # Analytics
    'analytics_meta', 'matomo', 'staging',
    # Tendril/Zarcillo
    'tendril', 'zarcillo',
]
