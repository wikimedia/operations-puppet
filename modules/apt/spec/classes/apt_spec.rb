require_relative '../../../../rake_modules/spec_helper'

describe 'apt' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "with OS #{os}" do
      let(:facts) { os_facts }
      let(:node_params) { {'site' => 'eqiad'} }
      it { should compile }

      context "when not using a proxy" do
        let(:params) { {
                         :use_proxy => false,
                       } }
        it { should compile }
      end
    end
  end
end
