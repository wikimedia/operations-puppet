require 'spec_helper'

describe 'openstack::repo::uca' do

  describe 'Ubuntu with defaults' do

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
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-updates/grizzly'
      )
    end
  end

  describe 'Ubuntu and grizzly' do
    let :params do
      { :release => 'folsom', :repo => 'proposed' }
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
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-proposed/folsom'
      )
    end
  end

end
