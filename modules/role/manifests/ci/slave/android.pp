# == Class role::ci::slave::android
#
# A continuous integration slave that runs Android based tests.
#
# filtertags: labs-project-integration
class role::ci::slave::android {

    requires_realm('labs')
    requires_os('debian >= jessie')

    system::role { 'role::ci::slave::android':
        description => 'CI Jenkins slave for Android testing',
    }

    include role::ci::slave::labs::common

    include contint::packages::androidsdk
    include contint::packages::java

    exec {'jenkins-deploy kvm membership':
        unless  => "/bin/grep -q 'kvm\\S*jenkins-deploy' /etc/group",
        command => '/usr/sbin/usermod -aG kvm jenkins-deploy',
    }

}
