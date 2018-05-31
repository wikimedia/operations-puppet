# defined type: a config dir and file for a planet language version
define planet::config (
    $domain_name = $domain_name,
){

    $config_path = '/etc/rawdog'
    $config_file = 'config'
    $feed_src = 'feeds'

    file { "${config_path}/${title}":
        ensure => 'directory',
        path   => "${config_path}/${title}",
        mode   => '0755',
        owner  => 'planet',
        group  => 'planet',
    }

    file { "${config_path}/${title}/${config_file}":
        ensure  => 'present',
        path    => "${config_path}/${title}/${config_file}",
        owner   => 'planet',
        group   => 'planet',
        mode    => '0444',
        content => template("planet/${feed_src}/${title}_config.erb"),
    }
}
