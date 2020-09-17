require_relative '../../../../rake_modules/spec_helper'

describe 'stunnel' do
  let(:node) { 'foobar.example.com' }
  let(:params) do
    {
      # ensure: "present",
      # service_name: "stunnel4",
    }
  end

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/default/stunnel4').with(
            ensure: 'file'
          ).with_content(
            %r{^FILES="/etc/stunnel/daemons/\*\.conf"$}
          ).with_content(
            /^OPTIONS=""$/
          ).with_content(
            /^PPP_RESTART=0$/
          ).with_content(
            /^RLIMITS=""$/
          ).with_content(
            /^ENABLED=1$/
          )
        end
        ['/etc/stunnel/clients', '/etc/stunnel/daemons'].each do |directory|
          it do
            is_expected.to contain_file(directory).with(
              ensure: 'directory',
              recurse: true,
              purge: true
            )
          end
        end
        it { is_expected.to contain_service('stunnel4').with_ensure('running') }
      end
      describe 'Change Defaults' do
        context 'ensure' do
          before(:each) { params.merge!(ensure: 'absent') }
          it { is_expected.to compile }
          it { is_expected.to contain_service('stunnel4').with_ensure('stopped') }
          it do
            is_expected.to contain_file('/etc/default/stunnel4').with_content(
              /^ENABLED=0$/
            )
          end
        end
        context 'config_dir' do
          before(:each) { params.merge!(config_dir: '/etc/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/default/stunnel4').with_content(
              %r{^FILES="/etc/foobar/daemons/\*\.conf"$}
            )
          end
        end
      end
    end
  end
end
