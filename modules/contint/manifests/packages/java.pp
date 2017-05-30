class contint::packages::java {

    if os_version('ubuntu == trusty || debian == jessie') {
        require_package('openjdk-7-jdk')
    }

    if os_version('debian >= jessie') {
        require_package('openjdk-8-jdk')
    }

    package { 'maven2':
        ensure => present,
    }

}
