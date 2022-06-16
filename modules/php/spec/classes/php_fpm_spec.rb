# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'php::fpm' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      context 'when php is defined' do
        let(:pre_condition) { 'class { "::php": versions => ["7.2"], sapis => ["fpm"]}' }
        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.2/fpm/php-fpm.conf')
            .with_owner('root')
            .with_mode('0444')
            .with_ensure('present')
            .with_content(/log_level = notice\n/)
            .that_requires('Package[php7.2-fpm]')
          }
          it { is_expected.to contain_service('php7.2-fpm')
            .with_ensure('running')
            .with_restart('/bin/systemctl reload php7.2-fpm.service')
            .that_subscribes_to('File[/etc/php/7.2/fpm/php-fpm.conf]')
          }
          it { is_expected.to contain_file('/etc/php/7.2/fpm/pool.d')
            .with_ensure('directory')
            .with_owner('root')
            .with_recurse(true)
            .with_purge(true)
          }
        end
        context 'with ensure absent' do
          let(:params) {
            { 'ensure' => :absent }
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.2/fpm/php-fpm.conf')
            .with_ensure('absent')
          }
          it { is_expected.not_to contain_service('php7.2-fpm') }
          it { is_expected.to contain_file('/etc/php/7.2/fpm/pool.d')
            .with_ensure('absent')
            .with_owner('root')
            .with_recurse(true)
            .with_purge(true)
          }
        end
        context 'with custom config' do
          let(:params) {
            { 'config' => { 'log_level' => 'warning' } }
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.2/fpm/php-fpm.conf')
            .with_owner('root')
            .with_mode('0444')
            .with_ensure('present')
            .with_content(/log_level = warning\n/)
          }
        end
      end
    end
  end
end
