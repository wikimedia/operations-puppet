# == Class cergen
# Installs cergen and ensure that /etc/cergen/manifests.d exists.
#
class cergen
{
    require_package('cergen')

    $manifests_path = '/etc/cergen/manifests.d'

    file { ['/etc/cergen', $manifests_path]:
        ensure => 'directory',
    }

    # Collect all exported cergen certificate manifests.
    Cergen_manifest <<||>>
}
