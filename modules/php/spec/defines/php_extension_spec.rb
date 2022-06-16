# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'php::extension' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts) {facts}
      let(:title) { 'xml' }
      context 'when php is defined' do
        let(:pre_condition) { 'class { "::php": versions => ["7.0"]}' }

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
            .with_content(/extension = xml.so/)
            .with_ensure('present')
            .with_tag(['php::config::7.0::cli'])
          }
          it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/20-xml.ini')
            .with_ensure('link')
            .with_target('/etc/php/7.0/mods-available/xml.ini')
          }
          it { is_expected.to contain_package('php-xml')
            .with_ensure('present')
            .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
          }
        end
        context 'with ensure absent' do
          let(:params) {
            {'ensure' => 'absent'}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
            .with_ensure('absent')
            .with_tag(['php::config::7.0::cli'])
          }
          it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/20-xml.ini')
            .with_ensure('absent')
          }
          it { is_expected.to contain_package('php-xml')
            .with_ensure('absent')
            .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
          }
        end
        context 'with different priority' do
          let(:params){
            {'priority' => 15}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
            .with_content(/; priority=15/)
            .with_ensure('present')
            .with_tag(['php::config::7.0::cli'])
          }
          it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/15-xml.ini')
            .with_ensure('link')
          }
        end
        context 'with versioned packages' do
          let(:params) {
            {'versioned_packages' => true}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('php7.0-xml')}
        end
        context 'without installing packages' do
          let(:params) {
            {'install_packages' => false}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_package('php-xml') }
        end
        context 'with custom config' do
          let(:params) {
            {'config' => {'foo' => {'bar' => 'FooBar'}}}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
            .with_content(/foo.bar = FooBar/)
            .with_ensure('present')
            .with_tag(['php::config::7.0::cli'])
          }
        end
        context 'with a non-default sapi' do
          let(:params) {
            {'sapis' => ['fpm']}
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
            .with_content(/extension = xml.so/)
            .with_ensure('present')
            .with_tag(['php::config::7.0::fpm'])
          }
          it { is_expected.to contain_file('/etc/php/7.0/fpm/conf.d/20-xml.ini')
            .with_ensure('link')
            .with_target('/etc/php/7.0/mods-available/xml.ini')
          }
          it { is_expected.to contain_package('php-xml')
            .with_ensure('present')
            .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
            .with_tag(['php::package::7.0::fpm'])
          }
        end
        context 'with a non-default set of versions' do
          let(:params) { { 'versions' => ['7.2', '7.4'] } }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/php/7.2/mods-available/xml.ini')
            .with_content(/extension = xml.so/)
            .with_ensure('present')
            .with_tag(['php::config::7.2::cli'])
          }
          it { is_expected.to contain_file('/etc/php/7.4/mods-available/xml.ini')
            .with_content(/extension = xml.so/)
            .with_ensure('present')
            .with_tag(['php::config::7.4::cli'])
          }
          it { is_expected.to contain_package('php-xml')
            .with_ensure('present')
            .that_requires('File[/etc/php/7.2/mods-available/xml.ini]')
            .with_tag(['php::package::7.2::cli', 'php::package::7.4::cli'])
          }
          context 'with package overrides' do
            let(:params) { super().merge({'package_overrides' => {'7.0' => 'foo', '7.4' => 'bar'} }) }
            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to contain_package('foo') }
          end
        end
      end
      context 'when php is not declared' do
        it { is_expected.to compile.and_raise_error(/php::extension is not meant to /)}
      end
    end
  end
end
