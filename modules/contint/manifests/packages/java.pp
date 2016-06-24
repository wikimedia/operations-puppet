class contint::packages::java {

    require_package('openjdk-7-jdk')

    if os_version('debian >= jessie') {
        require_package('openjdk-8-jdk')
    }

    package { 'maven2':
        ensure => present,
    }

}
