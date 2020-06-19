class profile::mariadb::mysql_role (
    Enum['master', 'slave', 'standalone'] $role = lookup('mariadb::mysql_role', { 'default_value' => 'slave' }),
){}
