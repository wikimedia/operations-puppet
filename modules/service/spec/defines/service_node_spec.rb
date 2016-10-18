require 'spec_helper'

describe 'service::node', :type => :define do

  let(:title) { 'my_service_name' }
  let(:facts) { { :initsystem => 'systemd' } }

  context 'when only port is given' do
    let(:params) { { :port => 1234 } }

    it 'create application config file' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
    end
    it 'logs locally with info level' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
                         .with_content(%r{level: info\n\s*path: /srv/log/my_service_name/main\.log}m)
    end
  end

  context 'when $local_logging_level is set to warn' do
    let(:params) { {
        :port => 1234,
        :local_logging_level => 'warn',
    } }

    it 'create application config file' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
    end
    it 'logs locally with warn level' do
      is_expected.to contain_file('/etc/my_service_name/config.yaml')
                         .with_content(%r{level: warn\n\s*path: /srv/log/my_service_name/main\.log}m)
    end
  end
end
