# puppet module for wmf image scalers
class imagescaler {

# Virtual resource for the monitoring server
@monitor_group { 'imagescaler': description => 'image scalers' }


# files for wmf image scalers
file { '/etc/wikimedia-image-scaler':
    content => 'The presence of this file alters the apache configuration, to be suitable for image scaling.',
    #notify => Service[apache],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
}

file { '/etc/fonts/conf.d/70-yes-bitmaps.conf':
    ensure => 'absent',
}

file { '/etc/fonts/conf.d/70-no-bitmaps.conf':
    ensure => 'link',
    target => '/etc/fonts/conf.avail/70-no-bitmaps.conf',
}

file { '/a':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
}

file { '/a/magick-tmp':
    ensure  => 'directory',
    owner   => 'apache',
    group   => 'root',
    mode    => '0755',
    require => File['/a'],
}

file { '/tmp/magick-tmp':
    ensure => 'directory',
    owner  => 'apache',
    group  => 'root',
    mode   => '0755',
}

include imagescaler::fonts
include imagescaler::packages
include imagescaler::cron

}
