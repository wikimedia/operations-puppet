require 'spec_helper'

describe 'install_server::web_server', :type => :class do

    # Please wmflib.os_version()
    let(:facts) { {
        :lsbdistrelease => '8.5',
        :lsbdistid => 'Debian',
    } }

    it do
        should contain_file('/srv/index.html').with({
            'mode'    => '0444',
            'owner'   => 'root',
            'group'   => 'root',
            'content' => '',
        })
    end
end
