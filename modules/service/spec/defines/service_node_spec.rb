require 'spec_helper'

describe 'service::node', :type => :define do
  let(:title) { 'my_service_name' }
  let(:facts) { { :initsystem => 'systemd' } }

  context 'when only port is given' do
    let(:params) { { :port => 1234 } }

    it 'create application config file' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
    end
    it 'contains a service named after the application' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
                         .with_content(/name: my_service_name/)
    end
  end
end
