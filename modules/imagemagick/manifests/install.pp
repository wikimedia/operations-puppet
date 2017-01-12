# === Class imagemagick::install
#
# Installs imagemagick and our custom policy
class imagemagick::install {
    require_package('imagemagick')
    require_package('webp')

    if os_version('debian >= jessie || ubuntu >= wily') {
        # configuration directory changed since ImageMagick 8:6.8.5.6-1
        $confdir = '/etc/ImageMagick-6'
    } else {
        $confdir = '/etc/ImageMagick'
    }

    file { "${confdir}/policy.xml":
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
