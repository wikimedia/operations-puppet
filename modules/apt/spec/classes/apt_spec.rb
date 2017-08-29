require 'spec_helper'

describe 'apt' do
    os = [
        {:operatingsystem => 'Debian'},
        {:operatingsystem => 'Ubuntu'},
    ]

    os.each do |facts|
        context "with OS #{facts[:operatingsystem]}" do
            let(:facts) { facts }

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
