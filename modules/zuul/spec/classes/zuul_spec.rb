require 'spec_helper'

describe 'zuul' do
    context "on production" do
        let(:facts) {{
            :realm => 'production',
            :operatingsystem => 'Debian',
            # for wmflib os_version
            :lsbdistid      => 'Debian',
            :lsbdistrelease => '8.7',
        }}
        it { should compile }
    end
    context "on labs" do
        let(:facts) {{
            :realm => 'labs',
            :operatingsystem => 'Debian',
            # for wmflib os_version
            :lsbdistid       => 'Debian',
            :lsbdistrelease  => '8.7',
        }}
        it { should compile }
    end
end
