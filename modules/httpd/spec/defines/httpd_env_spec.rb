# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'httpd::env' do
  let(:pre_condition){ 'service { "apache2": ensure => running }'}
  let(:title) { 'foobar' }
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      context 'normal variable' do
        let(:params) {
          {:vars => {'FOO' => 'bar'}}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__conf('foobar').with_content("export FOO=\"bar\"\n") }
      end

      context 'vars get uppercased' do
        let(:params) {
          {:vars => {'FOO' => 'bar'}}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__conf('foobar').with_content("export FOO=\"bar\"\n") }
      end
      context 'multiple variables' do
        let(:params) {
          {:vars => {'foo' => 'bar', 'bar' => 'foo'}}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__conf('foobar').with_content("export FOO=\"bar\"\nexport BAR=\"foo\"\n") }
      end
    end
  end
end
