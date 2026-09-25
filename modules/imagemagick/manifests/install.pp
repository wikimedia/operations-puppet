# SPDX-License-Identifier: Apache-2.0
# === Class imagemagick::install
#
# Installs imagemagick and our custom policy
class imagemagick::install {
    stdlib::ensure_packages('imagemagick')
    stdlib::ensure_packages('webp')

    file { '/etc/ImageMagick-6/policy.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/imagemagick/policy.xml',
        require => Package['imagemagick'],
    }
}
