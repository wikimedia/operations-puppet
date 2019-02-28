require 'spec_helper'

describe 'install_server::tftp_server', :type => :class do
    let(:pre_condition) { 'include base::auto_restarts' }

    it { should compile }
    it { should contain_package('atftpd').with_ensure('present') }

    it do
        should contain_file('/etc/default/atftpd').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

    it do
        should contain_file('/srv/tftpboot').with({
            'mode'    => '0444',
            'owner'   => 'root',
            'group'   => 'root',
            'recurse' => 'remote',
        })
    end
end
