require 'spec_helper'

describe 'systemd::unit' do
    context 'when initsystem is unknown' do
        let(:title) { 'dummyservice' }
        let(:facts) { { :initsystem => 'unknown' } }
        let(:params) {
          {
            :ensure => 'present',
            :content => 'dummy'
          }
        }
        it { is_expected.to compile.and_raise_error(/You can only use systemd resources on systems with systemd/) }
    end

    context 'when initsystem is sytemd' do
      let(:facts) { {:initsystem => 'systemd' } }

        describe 'when using dummy parameters and a name without type' do
          let(:title) { 'dummyservice' }
            let(:params) { {
                :ensure => 'present',
                :content => 'dummy'
            } }
            it { should compile }

            describe 'then the systemd service' do
                it 'should define a unit file in the system directory' do
                  is_expected.to contain_file('/lib/systemd/system/dummyservice.service')
                                   .with_content('dummy')
                                   .that_notifies(
                                     "Exec[systemd daemon-reload for dummyservice.service]"
                  )
                end

                it 'should contain a systemctl-reload exec' do
                  is_expected.to contain_exec('systemd daemon-reload for dummyservice.service')
                                   .with_refreshonly(true)
                end
            end
        end
        describe 'when the title includes the unit type and is an override' do
          let(:title) { 'usbstick.device' }
          let(:params) { {
                           :ensure => 'present',
                           :content => 'dummy',
                           :override => true
                         } }
          it { should compile }

          it 'should define the parent directory of the override file' do
            is_expected.to contain_file('/etc/systemd/system/usbstick.device.d')
                             .with_ensure('directory')
                             .with_owner('root')
                             .with_group('root')
                             .with_mode('0555')
          end
          it 'should define the systemd override file' do
            is_expected.to contain_file('/etc/systemd/system/usbstick.device.d/puppet-override.conf')
                             .with_ensure('present')
                             .with_mode('0444')
                             .with_owner('root')
                             .with_group('root')
          end
          it 'should contain a systemctl-reload exec' do
            is_expected.to contain_exec('systemd daemon-reload for usbstick.device')
                             .with_refreshonly(true)
          end
        end
        describe 'when the corresponding service is defined (implicit name)' do
          let(:pre_condition) {
            """
            service { 'hhvm': ensure => running}
            """
          }
          let(:title) { 'hhvm' }
          let(:params) { {
                           :ensure => 'present',
                           :content => 'dummy',
                         } }
          it { should compile }
          it {
            is_expected.to contain_exec('systemd daemon-reload for hhvm.service')
                             .that_comes_before('Service[hhvm]')
          }
          describe 'when managing the service restarts' do
            let(:params) {
              {
                :ensure => 'present',
                :content => 'dummy',
                :restart => true
              }
            }
            it { should compile }
            it {
              is_expected.to contain_exec('systemd daemon-reload for hhvm.service')
                               .that_notifies('Service[hhvm]')
            }
          end
        end
    end
end
