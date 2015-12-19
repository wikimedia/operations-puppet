require 'spec_helper'

describe 'install_server::apt_repository', :type => :class do

    it { should contain_package('dpkg-dev').with_ensure('present') }
    it { should contain_package('gnupg').with_ensure('present') }
    it { should contain_package('reprepro').with_ensure('present') }
    it { should contain_package('dctrl-tools').with_ensure('present') }

    it do
        should contain_file('/srv/wikimedia').with({
            'ensure' => 'directory',
            'mode'   => '0755',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/wikimedia/conf').with({
            'ensure' => 'directory',
            'mode'   => '0755',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/wikimedia/conf/log').with({
            'ensure' => 'present',
            'mode'   => '0755',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/wikimedia/conf/distributions').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/wikimedia/conf/updates').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/wikimedia/conf/incoming').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end
end
