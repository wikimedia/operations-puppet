require 'spec_helper'

describe 'install-server::apt-repository', :type => :class do

    it { should contain_package('dpkg-dev') }
    it { should contain_package('gnupg') }
    it { should contain_package('reprepro') }
    it { should contain_package('dctrl-tools') }

    it do
        pending "Fix this"
        should contain_file('/srv/wikimedia').with({
            'ensure' => 'directory',
            'mode'   => '0755',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it { should contain_file('/usr/local/sbin/update-repository').with_ensure('absent') }

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
            'mode'   => '0755',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        pending "Fix this"
        should contain_file('/srv/wikimedia/conf/distributions').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        pending "Fix this"
        should contain_file('/srv/wikimedia/conf/updates').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        pending "Fix this"
        should contain_file('/srv/wikimedia/conf/incoming').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end
end
