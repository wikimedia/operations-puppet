type Profile::Mariadb::Role = Enum[
    # master of section per dc. Only master in active DC is read-write.
    'master',
    # read-only slave
    'slave',
    # single servers that are not part of replication
    'standalone',
]
