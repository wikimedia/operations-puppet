require_relative '../../../../rake_modules/spec_helper'

describe 'base::standard_packages' do
  on_supported_os(WMFConfig.test_on(11, 13)).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts}
      case facts[:os]['distro']['codename']
      when 'bullseye'
        let(:installed_packages) { ['ack'] }
        let(:absent_packages) { ['python2.7'] }
        let(:purged_packages) { [] }
      when 'bookworm'
        let(:installed_packages) { ['ack'] }
        let(:absent_packages) { ['libicu67'] }
        let(:purged_packages) { [] }
      else
        let(:installed_packages) { ['linux-sysctl-defaults'] }
        let(:absent_packages) { [] }
        let(:purged_packages) { [] }
      end
      it { is_expected.to compile }
      # tests a some random packages
      it { is_expected.to contain_package('vim').with_ensure('installed') }
      it { is_expected.to contain_package('tzdata').with_ensure('latest') }
      it 'test debian specific present package' do
        installed_packages.each do |package|
          is_expected.to contain_package(package).with_ensure('installed')
        end
      end
      it 'test debian specific absent package' do
        absent_packages.each do |package|
          is_expected.to contain_package(package).with_ensure('absent')
        end
      end
      it 'test debian specific purged package' do
        purged_packages.each do |package|
          is_expected.to contain_package(package).with_ensure('purged')
        end
      end
    end
  end
end
