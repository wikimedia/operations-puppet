require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::server', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:params) { { 'listen_address' => '10.2.3.4' } }
      let(:title) { 'my_prometheus_server' }

      context 'when only passing listen_addres' do
        it { is_expected.to compile }

        it 'uses --storage.tsdb.retention by default' do
          is_expected.to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.* --storage\.tsdb\.retention 730h .*/)
          is_expected.not_to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.*--storage\.tsdb\.retention\.size .*/)
        end
      end

      context 'when passing storage_retention_size uppercase' do
        let(:params) { super().merge({ 'storage_retention_size' => '50GB' }) }

        it { is_expected.to compile }

        it 'uses --storage.tsdb.retention. by default' do
          is_expected.to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.*--storage\.tsdb\.retention.size 50GB.*/)
          is_expected.not_to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.*--storage\.tsdb\.retention .*/)
        end
      end

      context 'when passing storage_retention_size lowercase' do
        let(:params) { super().merge({ 'storage_retention_size' => '50gb' }) }

        it { is_expected.to compile }

        it 'uses --storage.tsdb.retention. by default' do
          is_expected.to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.*--storage\.tsdb\.retention.size 50GB.*/)
          is_expected.not_to contain_file('/lib/systemd/system/prometheus@my_prometheus_server.service')
            .with_content(/.*--storage\.tsdb\.retention .*/)
        end
      end
    end
  end
end
