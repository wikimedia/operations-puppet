require 'spec_helper'

describe 'scap::target' do
    before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
    end
    let(:title) { 'test' }

    let(:facts) do
        {
            :lsbdistrelease => '8.7',
            :lsbdistid => 'Debian',
        }
    end

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

        it { should raise_error(/service_name must be set if additional_services_names is set/) }
    end
end
