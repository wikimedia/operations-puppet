require_relative '../../../../rake_modules/spec_helper'

describe 'puppet::agent' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts}

      context "default params" do
        it { is_expected.to compile }
      end
      context "With use_srv_records with no srv_domain" do
        let(:params) {{ use_srv_records: true }}
        it { is_expected.to compile.and_raise_error(/You must set \$srv_domain/) }
      end
      context "With use_srv_records and srv_domain" do
        let(:params) {{ use_srv_records: true, srv_domain: 'example.org' }}
        it { is_expected.to compile }
        it do
          is_expected.to contain_concat__fragment('main')
            .with_content(/^use_srv_records\s=\strue$/)
            .with_content(/^srv_domain\s=\sexample.org$/)
            .without_content(/^server/)
            .without_content(/^ca_server/)
        end
      end
    end
  end
end
