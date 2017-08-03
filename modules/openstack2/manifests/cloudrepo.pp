# sets upt APT repository for labs openstack

# class default kept here until components not yet moved to profiles
# for parameterization are completed in modules/openstack

class openstack2::cloudrepo(
    $version='liberty',
) {
    # As of 26/10/2015 we support kilo on trusty (lsb_release -c)
    if ($::lsbdistcodename == 'trusty') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "trusty-updates/${version}",
            components => 'main',
            keyfile    => 'puppet:///modules/openstack2/cloudrepo/ubuntu-cloud.key';
        }
    } elsif os_version('debian jessie') and ($version != 'liberty') {
        fail("T169099: There is no plan for ${version} on Jessie")
    }
}
