type Profile::Mariadb::InterDC_Replication_Type = Enum[
    # No replication between masters.
    'none',
    # Writes only flow in on direction between DCs
    'unidir',
    # Writes flow in both directions between DCs.
    'bidir',
]
