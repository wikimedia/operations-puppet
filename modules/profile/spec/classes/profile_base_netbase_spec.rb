require_relative '../../../../rake_modules/spec_helper'
describe 'profile::base::netbase' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node_params) {{ '_role' => 'sretest' }}
      describe 'defaults' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'change defaults' do
        let(:params) { {manage_etc_services: true} }
        it { is_expected.to compile }
        it do
          is_expected.to contain_file('/etc/services')
            .with_content(%r{^tcpmux\s1/tcp\s#\sTCP port service multiplexer$})
            .with_content(%r{^kerberos\s88/tcp\skerberos5\skrb5\skerberos-sec\s#\sKerberos\sv5$})
        end
      end
    end
  end
end
