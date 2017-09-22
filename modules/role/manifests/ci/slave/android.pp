# == Class role::ci::slave::android
#
# A continuous integration slave that runs Android based tests.
#
# filtertags: labs-project-integration
class role::ci::slave::android {

    requires_realm('labs')

    system::role { 'ci::slave::android':
        description => 'CI Jenkins slave for Android testing',
    }

    include role::ci::slave::labs::common

    include contint::packages::androidsdk
    include contint::packages::java

    $user = hiera('jenkins_agent_username')

    exec { "${user} kvm membership":
        unless  => "/bin/grep -q 'kvm\\S*${user}' /etc/group",
        command => "/usr/sbin/usermod -aG kvm '${user}",
    }

}
