# === Class imagemagick::install
#
# Installs imagemagick and our custom policy
class imagemagick::install {
    require_package('imagemagick')
    require_package('webp')

    file { '/etc/ImageMagick-6/policy.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/imagemagick/policy.xml',
        require => [
            Class['packages::imagemagick'],
            Class['packages::webp']
        ]
    }
}
