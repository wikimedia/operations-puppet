require 'spec_helper'

describe 'apt' do
    ['Debian', 'Ubuntu'].each do |os|
        context "with OS #{os}" do
            let(:facts) { { :operatingsystem => os } }

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
