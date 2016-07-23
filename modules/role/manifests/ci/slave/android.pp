class role::ci::slave::android {

    requires_realm('labs')
    requires_os('Debian >= jessie')

    system::role { 'role::ci::slave::android':
        description => 'CI Jenkins slave for Android testing',
    }

    include role::ci::slave::labs::common

    include contint::packages::androidsdk
    include contint::packages::java

}
