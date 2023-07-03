# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'apt::package_from_bpo' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'mypackage' }
      let(:distro) { os_facts[:os]['distro']['codename'] }
      let(:params) { { distro: distro } }

      context 'default parameters' do
          it { is_expected.to compile }
          it do
            is_expected.to contain_apt__pin("apt_pin_mypackage_#{distro}-bpo").with(
              pin: "release a=#{distro}-backports",
              package: 'mypackage',
              priority: 1001
            )
            is_expected.to contain_exec("exec-apt-get-update-mypackage_#{distro}-bpo").with(
              command: '/usr/bin/apt-get update',
              refreshonly: true
            )
            is_expected.to contain_package('mypackage').with_ensure('installed')
          end
      end

      context 'multiple packages' do
          let(:params) { super().merge(packages: ['package1', 'package2', 'package3']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apt__pin("apt_pin_mypackage_#{distro}-bpo").with(
              pin: "release a=#{distro}-backports",
              package: 'package1 package2 package3',
              priority: 1001
            )
            is_expected.to contain_exec("exec-apt-get-update-mypackage_#{distro}-bpo").with(
              command: '/usr/bin/apt-get update',
              refreshonly: true
            )
            is_expected.to contain_package('package1').with_ensure('installed')
            is_expected.to contain_package('package2').with_ensure('installed')
            is_expected.to contain_package('package3').with_ensure('installed')
          end
      end

      context 'override priority' do
          let(:params) { super().merge(priority: 123) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apt__pin("apt_pin_mypackage_#{distro}-bpo").with(
              pin: "release a=#{distro}-backports",
              package: 'mypackage',
              priority: 123
            )
            is_expected.to contain_exec("exec-apt-get-update-mypackage_#{distro}-bpo").with(
              command: '/usr/bin/apt-get update',
              refreshonly: true
            )
            is_expected.to contain_package('mypackage').with_ensure('installed')
          end
      end

      context 'override ensure_packages' do
          let(:params) { super().merge(ensure_packages: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apt__pin("apt_pin_mypackage_#{distro}-bpo").with(
              pin: "release a=#{distro}-backports",
              package: 'mypackage',
              priority: 1001
            )
            is_expected.to contain_exec("exec-apt-get-update-mypackage_#{distro}-bpo").with(
              command: '/usr/bin/apt-get update',
              refreshonly: true
            )
            is_expected.to_not contain_package('mypackage')
          end
      end
    end
  end
end
