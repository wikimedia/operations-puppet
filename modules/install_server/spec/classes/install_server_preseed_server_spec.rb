require 'spec_helper'

describe 'install_server::preseed-server', :type => :class do

    it do
        should contain_file('/srv/autoinstall').with({
            'ensure' => 'directory',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
            'recurse' => 'true',
            'links' => 'manage',
        }).without_path
    end
end
