# == Class cdh::pig
#
# Installs and configures Apache Pig and Pig DataFu.
#
class cdh::pig(
    $pig_properties_template = 'cdh/pig/pig.properties.erb',
    $log4j_template          = 'cdh/pig/log4j.properties.erb',
)
{
    # cdh::pig requires hadoop client and configs are installed.
    Class['cdh::hadoop'] -> Class['cdh::pig']

    package { 'pig':
        ensure => 'installed',
    }
    package { 'pig-udf-datafu':
        ensure => 'installed',
    }

    $config_directory = "/etc/pig/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['pig'],
    }
    cdh::alternative { 'pig-conf':
        link => '/etc/pig/conf',
        path => $config_directory,
    }

    file { "${config_directory}/pig.properties":
        content => template($pig_properties_template),
        require => Package['pig'],
    }
    file { "${config_directory}/log4j.properties":
        content => template($log4j_template),
        require => Package['pig'],
    }
}
