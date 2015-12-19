require 'spec_helper'

describe 'install_server::web_server', :type => :class do
    it do
        should contain_file('/srv/index.html').with({
            'mode'    => '0444',
            'owner'   => 'root',
            'group'   => 'root',
            'content' => '',
        })
    end
end
