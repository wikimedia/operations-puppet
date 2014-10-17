# = Class androidsdk::build::wikipedia
#
# Sets up requirements for building the wikipedia android
# app.
class androidsdk::build::wikipedia {

    include ::role::labs::lvm::srv
    include androidsdk::dependencies

    user { 'android-build':
        ensure     => present,
        shell      => '/bin/false',
        managehome => true,
    }

    git::clone { 'apps/android/wikipedia':
        directory => '/srv/wikipedia',
        ensure    => present,
        owner     => 'android-build',
        group     => 'www-data',
        require   => User['android-build'],
    }

    git::clone { 'labs/tools/wikipedia-android-builds':
        directory => '/srv/builds',
        ensure    => present,
        owner     => 'android-build',
        group     => 'www-data',
        require   => User['android-build'],
    }
   
    nginx::site { 'wikipedia-android-build':
        ensure => present,
        source => 'puppet:///modules/androidsdk/nginx.conf'
    }

    cron { 'wikipedia-android-build':
        ensure  => present,
        command => '/srv/builds/src/build.py',
        minute  => [0, 30],
        user    => 'android-build',
        require => User['android-build'],
    }
}
