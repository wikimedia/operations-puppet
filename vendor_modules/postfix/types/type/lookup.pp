# @since 2.0.0
type Postfix::Type::Lookup = Variant[Postfix::Type::Lookup::Database, Enum['ldap', 'memcache', 'mysql', 'pgsql', 'sqlite']]
