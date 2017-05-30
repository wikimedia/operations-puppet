class contint::packages::java {

    if os_version('debian >= jessie') {
        require_package('openjdk-8-jdk')
    } else {
        require_package('openjdk-7-jdk')
    }

    package { 'maven2':
        ensure => present,
    }

}
