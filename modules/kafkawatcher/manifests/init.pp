# = Class: kafkawatcher
#
# == Parameters:
# - $username: Username owning the service
# - $package_dir:  Directory where the service should be installed.
class kafkawatcher(
    $username = 'kafkawatcher',
    $package_dir = '/srv/deployment/wikimedia/kafkawatcher',
    ) {

        require_package('python-kafka', 'python-yaml')

        group { $username:
            ensure => present,
            system => true,
        }

        user { $username:
            ensure     => present,
            name       => $username,
            comment    => 'KafkaWatcher user',
            forcelocal => true,
            system     => true,
            home       => $package_dir,
            managehome => no,
        }
        
        file { '/etc/kafkawatcher':
            ensure => directory,
            mode   => '0755',
            owner  => root,
            group  => root,
        }
}
