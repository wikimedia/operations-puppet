require 'spec_helper'

describe 'openstack::repo' do

  describe 'RHEL and havana' do
    let :params do
      { :release => 'havana' }
    end
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '6.4',
      }
    end

    it do
      should contain_yumrepo('rdo-release').with(
        :baseurl => 'http://repos.fedorapeople.org/repos/openstack/openstack-havana/epel-6/'
      )
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Havana')

      should contain_yumrepo('epel')
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6')
    end
  end

  describe 'RHEL and grizzly' do
    let :params do
      { :release => 'grizzly' }
    end
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '6.4',
      }
    end

    it do
      should contain_yumrepo('rdo-release').with(
        :baseurl => 'http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/epel-6/'
      )
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Grizzly')

      should contain_yumrepo('epel')
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6')
    end
  end

  describe 'Fedora and havana' do
    let :params do
      { :release => 'havana' }
    end

    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'Fedora',
        :operatingsystemrelease => '18',
      }
    end

    it do
      should contain_yumrepo('rdo-release').with(
        :baseurl => 'http://repos.fedorapeople.org/repos/openstack/openstack-havana/fedora-18/'
      )
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Havana')
    end
  end


  describe 'Fedora and grizzly' do
    let :params do
      { :release => 'grizzly' }
    end

    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'Fedora',
        :operatingsystemrelease => '18',
      }
    end

    it do
      should contain_yumrepo('rdo-release').with(
        :baseurl => 'http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/fedora-18/'
      )
      should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Grizzly')
    end
  end

  describe 'Ubuntu and havana' do
    let :params do
      { :release => 'havana' }
    end

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
        :lsbdistcodename        => 'precise',
      }
    end

    it do
      should contain_apt__source('ubuntu-cloud-archive').with_release('precise-updates/havana')
    end
  end

  describe 'Ubuntu and grizzly' do
    let :params do
      { :release => 'grizzly' }
    end

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
        :lsbdistcodename        => 'precise',
      }
    end

    it do
      should contain_apt__source('ubuntu-cloud-archive').with_release('precise-updates/grizzly')
    end
  end
end
