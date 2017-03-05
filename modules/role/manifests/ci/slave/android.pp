# == Class role::ci::slave::android
#
# A continuous integration slave that runs Android based tests.
#
# filtertags: labs-project-integration
class role::ci::slave::android {

    requires_realm('labs')
    requires_os('Debian >= jessie')

    system::role { 'role::ci::slave::android':
        description => 'CI Jenkins slave for Android testing',
    }

    include role::ci::slave::labs::common

    include contint::packages::androidsdk
    include contint::packages::java

    $repo_license_dir = '/srv/jenkins-workspace/workspace/apps-android-wikipedia-periodic-test/licenses'
    $sdk_license_dir = '/srv/jenkins-workspace/tools/android-sdk/licenses'

    exec {'jenkins-deploy kvm membership':
        unless  => "/bin/grep -q 'kvm\\S*jenkins-deploy' /etc/group",
        command => '/usr/sbin/usermod -aG kvm jenkins-deploy',
    }

    exec {'create link to app repo license directory':
        command => "/bin/ln -s ${repo_license_dir} ${sdk_license_dir}",
        onlyif  => "/usr/bin/test -e ${repo_license_dir}",
        creates => $sdk_license_dir,
    }
}
