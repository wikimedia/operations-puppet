require_relative '../../../../rake_modules/spec_helper'

describe 'cfssl::config' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'test_config' }
      describe 'default run failes' do
        it do
          is_expected.to compile
            .and_raise_error(/auth_keys must have an entry for 'default_auth'/)
        end
      end
      context 'with default auth_keys entry' do
        let(:params) do
          {
            auth_keys: {
              'default_auth' => {
                'key' => 'aaaabbbbccccdddd',
                'type' => 'standard',
              }
            }
          }
        end

        describe 'default run should pass' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/"default_auth":{"key":"aaaabbbbccccdddd"/))
              .with_content(sensitive(/"signing":{"default":{"auth_key":"default_auth"/))
          end
        end
      end
      context 'change default auth_keys entry' do
        let(:params) do
          {
            auth_keys: {
              'default_auth' => {
                'key' => 'aaaabbbbccccdddd',
                'type' => 'standard',
              },
              'foobar' => {
                'key' => 'ddddccccbbbbaaaa',
                'type' => 'standard',
              }
            },
            profiles: {
              'foobar' => {
                'auth_key' => 'foobar',
              }
            }
          }
        end

        describe 'default run should pass' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/"default_auth":{"key":"aaaabbbbccccdddd"/))
              .with_content(sensitive(/"signing":{"default":{"auth_key":"default_auth"/))
              .with_content(sensitive(/"profiles":{"foobar":{"auth_key":"foobar"/))
          end
        end
      end
    end
  end
end
