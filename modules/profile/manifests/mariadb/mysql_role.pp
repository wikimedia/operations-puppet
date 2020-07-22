class profile::mariadb::mysql_role (
    Profile::Mariadb::Role $role = lookup('mariadb::mysql_role', { 'default_value' => 'slave' }),
){}
