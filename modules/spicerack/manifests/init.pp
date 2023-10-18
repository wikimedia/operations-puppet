# SPDX-License-Identifier: Apache-2.0
# @summary Installs the spicerack library and cookbook entry point and their configuration.
#
# @param tcpircbot_host Hostname for the IRC bot.
# @param tcpircbot_port Port to use with the IRC bot.
# @param http_proxy a http_proxy to use for connections
# @param etcd_config the path to the etcd configuration to use for distributed locking
# @param cookbooks_dirs a list of paths where cookbooks have been checked out
# @param modules a hash where the keys are the spicerack module names and the values
#        are hashes where keys are the file names and values is the file content to be converted
#        to yaml.
class spicerack (
    String                     $tcpircbot_host,
    Stdlib::Port               $tcpircbot_port,
    String                     $http_proxy,
    Array[String]              $cookbooks_dirs,
    Hash                       $modules,
    Optional[Stdlib::Unixpath] $etcd_config = undef,
) {
    ensure_packages('spicerack')

    # this directory is created by the debian package however we still manage it to force
    # an auto require on all files under this directory
    file { '/etc/spicerack':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }

    file { '/etc/spicerack/config.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('spicerack/config.yaml.erb'),
    }

    ### SPICERACK MODULES CONFIGURATION FILES

    $modules.each | $module, $file_data | {
        file { "/etc/spicerack/${module}":
            ensure => directory,
            owner  => 'root',
            group  => 'ops',
            mode   => '0550',
        }
        $file_data.each | $filename, $content | {
            file { "/etc/spicerack/${module}/${filename}":
                ensure  => file,
                owner   => 'root',
                group   => 'ops',
                mode    => '0440',
                content => $content.to_yaml,
            }
        }
    }

    ### COOKBOOKS CONFIGURATION FILES

    file { '/etc/spicerack/cookbooks':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }

}
