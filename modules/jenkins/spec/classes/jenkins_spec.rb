require_relative '../../../../rake_modules/spec_helper'

systemd_override_file = '/etc/systemd/system/jenkins.service.d/override.conf'

describe 'jenkins' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:node_params) { {'site' => 'eqiad'} }
      let(:params) { {
        :prefix => '/ci',
      } }
      it { should compile }

      describe 'when service_ensure' do
        context "is 'running'" do
          let(:params) { {
            :prefix => '/ci',
            :service_ensure => 'running',
          } }
          it { should contain_service('jenkins') .with_ensure('running') }
        end
        context "is 'stopped'" do
          let(:params) { {
            :prefix => '/ci',
            :service_ensure => 'stopped',
          } }
          it { should contain_service('jenkins') .with_ensure('stopped') }
        end
      end
      describe 'systemd jenkins service' do
        it 'should set Umask' do
            should contain_file(systemd_override_file)
            .with_content(/^UMask=0002$/)
        end
        it 'should set LimitNOFILE' do
          should contain_file(systemd_override_file)
            .with_content(/^LimitNOFILE=8192$/)
        end
        it 'should pass prefix to jenkins' do
          should contain_file(systemd_override_file)
            .with_content(%r% --prefix=/ci$%)
        end
        context 'when http port is given' do
          let(:params) { {
            :prefix => '/ci',
            :http_port => 8042,
          } }
          it 'should set http port' do
          should contain_file(systemd_override_file)
              .with_content(/ --httpPort=8042 /)
          end
        end
        context 'when access log is enabled' do
          let(:params) { {
            :prefix => '/ci',
            :access_log => true,
          } }
          it 'should set Jenkins access logger' do
            should contain_file(systemd_override_file)
              .with_content(/SimpleAccessLogger.+\\$/)
          end
        end
        it 'escapes build_dir dollar token for systemd' do
          should contain_file(systemd_override_file)
            .with_content(%r%\$\${ITEM_ROOTDIR}/builds%)
        end
      end
    end
  end
end
