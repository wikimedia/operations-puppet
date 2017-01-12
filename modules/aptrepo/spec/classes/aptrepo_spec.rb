require 'spec_helper'

describe 'aptrepo', :type => :class do

    let(:params) {{ :basedir => '/srv/wikimedia' }}

    context "On Debian" do
        # On Mac OS the User provider is 'directoryservice' which does not
        # support managedhome.  We could use facts to hard set
        # operatingsystem but rspec-puppet matcher does not support it
        # https://github.com/rodjek/rspec-puppet/issues/256
        let(:pre_condition) do
            """
            User {
                provider => 'useradd',
            }
            """
        end
        it { should compile }
    end

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
