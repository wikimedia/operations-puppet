# filtertags: labs-project-ores
class role::labs::ores::web {
    class { '::ores::web':
        ores_config_user => 'nobody',
        ores_config_group => 'nogroup',
    }
    include ::role::labs::ores::redisproxy
}
