require 'spec_helper'

describe 'aptrepo::distribution', :type => :class do

    let(:params) {{
        :basedir => '/srv/wikimedia',
        :settings => {
            'jessie' => {
                'Suite' => 'jessie-mediawiki'
            }
        },
    }}

    it { should compile }

    it do
        should contain_file('/srv/wikimedia/conf/distributions').with({
            'ensure' => 'file',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end

end
