require 'spec_helper'

describe 'mirrors', :type => :class do

    it { should contain_user('mirror') }
    it { should contain_group('mirror') }
    it { should contain_file('/srv/mirrors') }

    it do
        should contain_file('/usr/local/lib/nagios/plugins/check_apt_mirror').with({
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0555',
        },)
    end
end
