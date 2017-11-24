require 'spec_helper'

describe 'apt' do
    os = [
        {
            :lsbdistid => 'Debian',
            :lsbdistrelease => '8.0',
            :operatingsystem => 'Debian',
            :lsbdistcodename => 'jessie'
        },
        {
            :lsbdistid => 'Ubuntu',
            :lsbdistrelease => '14.04',
            :operatingsystem => 'Ubuntu',
            :lsbdistcodename => 'trusty'
        },
    ]
    os.each do |os_facts|
      context "with OS #{os_facts[:lsbdistid]} #{os_facts[:lsbdistrelease]}" do
            let(:facts) { os_facts }
            let(:node_params) { {'site' => 'eqiad'} }
            it { should compile }

            context "when not using a proxy" do
                let(:params) { {
                    :use_proxy => false,
                } }
                it { should compile }
            end

            context "when using experimental repo" do
                let(:params) { {
                    :use_experimental => true,
                } }
                it { should compile }
            end
        end
    end
end
