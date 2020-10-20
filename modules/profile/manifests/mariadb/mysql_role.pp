class profile::mariadb::mysql_role (
    Profile::Mariadb::Role $role = lookup('profile::mariadb::mysql_role', { 'default_value' => 'slave' }),
){}
