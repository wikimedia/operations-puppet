# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'aptrepo', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {{ :basedir => '/srv/wikimedia' }}
      let(:pre_condition) {
        # Stub for the ::apt module
        "exec { 'apt-get update': path => '/bin/true' }
        user{'reprepro':}
        group{'reprepro':}"
      }
      it { should compile }

      it { should contain_package('dpkg-dev').with_ensure('installed') }
      it { should contain_package('gnupg').with_ensure('installed') }
      it { should contain_package('reprepro').with_ensure('installed') }
      it { should contain_package('dctrl-tools').with_ensure('installed') }

      it do
        should contain_file('/srv/wikimedia').with({
          'ensure' => 'directory',
          'mode'   => '0755',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end

      it do
        should contain_file('/srv/wikimedia/conf').with({
          'ensure' => 'directory',
          'mode'   => '0755',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end

      it do
        should contain_file('/srv/wikimedia/conf/log').with({
          'ensure' => 'present',
          'mode'   => '0755',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end

      it do
        should contain_file('/srv/wikimedia/conf/updates').with({
          'ensure' => 'present',
          'mode'   => '0444',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end

      it do
        should contain_file('/srv/wikimedia/conf/incoming').with({
          'ensure' => 'present',
          'mode'   => '0444',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end
    end
  end
end
