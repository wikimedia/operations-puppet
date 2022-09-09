# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'scap::target' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
      'fake_secret'
    }
  end
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      let(:title) { 'test' }

      context 'using a single service' do
        let(:params) { {
          :deploy_user => 'deploy-service',
          :service_name => 'test_service',
        } }

        it { should contain_sudo__user('scap_deploy-service_test_service').with('user' => 'deploy-service') }
      end

      context 'additional services plus service' do
        let(:params) { {
          :deploy_user => 'deploy-service',
          :service_name => 'test_service1',
          :additional_services_names => ['test_service2'],
        } }
        it { should contain_sudo__user('scap_deploy-service_test_service1').with('user' => 'deploy-service') }
        it { should contain_sudo__user('scap_deploy-service_test_service2').with('user' => 'deploy-service') }
      end

      context 'only additional services' do
        let(:params) { {
          :deploy_user => 'deploy-service',
          :additional_services_names => ['test_service3'],
        } }

        it do
          is_expected.to raise_error(
            Puppet::Error, /service_name must be set if additional_services_names is set/
          )
        end
      end
    end
  end
end
