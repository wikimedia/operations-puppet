type Postgresql::Priv::Table = Enum[
    'ALL',
    'SELECT',
    'DELETE',
    'INSERT',
    'REFERENCES',
    'UPDATE',
    'TRIGGER',
    'TRUNCATE'
]
