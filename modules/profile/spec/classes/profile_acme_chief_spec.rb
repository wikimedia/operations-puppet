require_relative '../../../../rake_modules/spec_helper'

describe 'profile::acme_chief' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node_params) { {'_role' => 'acme_chief'} }
      let(:pre_condition) { "exec { 'apt-get update': path => '/bin/true' }" }

      it { is_expected.to compile }

      describe 'internal CN' do
        let(:params) do
          {
            certificates: {
              'bad' => {
                'CN'        => 'bad.discovery.wmnet',
                'challenge' => 'dns-01',
                'SNI'       => ['www.example.org']
              }
            }
          }
        end
        it { is_expected.to compile.and_raise_error(/bad CN \(bad.discovery.wmnet\) contains internal domain/) }
      end

      describe 'internal SNI' do
        let(:params) do
          {
            certificates: {
              'bad' => {
                'CN'        => 'www.example.org',
                'challenge' => 'dns-01',
                'SNI'       => ['bad.discovery.wmnet']
              }
            }
          }
        end
        it { is_expected.to compile.and_raise_error(/bad SNI \(bad.discovery.wmnet\) contains internal domain/) }
      end
    end
  end
end
