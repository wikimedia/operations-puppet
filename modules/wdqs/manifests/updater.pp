# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
class wdqs::updater(
    $options = '-n wdq -s',
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
){

    $init_template = "wdqs/initscripts/wdqs-updater.${::initsystem}.erb"
    case $::initsystem {
        'systemd': {

            $path = '/etc/systemd/system/wdqs-updater.service'

            exec { 'systemd reload for wdqs-updater':
                refreshonly => true,
                command     => '/bin/systemctl daemon-reload',
                subscribe   => File[$path],
            }

            file { $path:
                ensure  => present,
                content => template($init_template),
                mode    => '0444',
                owner   => root,
                group   => root,
                require => [
                            File['/etc/wdqs/updater-logs.xml'],
                            Service['wdqs-blazegraph'] ],
            }
        }
        'upstart': {
            file { '/etc/init/wdqs-updater.conf':
                ensure  => present,
                content => template($init_template),
                mode    => '0444',
                owner   => root,
                group   => root,
                require => [
                            File['/etc/wdqs/updater-logs.xml'],
                            Service['wdqs-blazegraph']
                            ],
            }

        }
        default: { fail('Unsupported init system') }
    }
}
