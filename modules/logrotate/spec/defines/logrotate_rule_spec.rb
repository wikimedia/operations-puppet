# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'logrotate::rule', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'some_rule' }
      let(:params) do
        {
          file_glob: '/var/log/some.log',
        }
      end

      context 'default' do
        it { is_expected.to contain_file('/etc/logrotate.d/some_rule') }
      end

      context 'defined frequency and no size' do
        let(:params) { super().merge(frequency: "daily") }
        it do
          is_expected.to contain_file('/etc/logrotate.d/some_rule')
            .without_content(/size/)
        end
      end

      context 'undef frequency and size' do
        let(:params) { super().merge(size: "10M") }
        it do
          is_expected.to contain_file('/etc/logrotate.d/some_rule')
            .with_content(/\ssize 10M/)
        end
      end

      context 'defined frequency and size' do
        let(:params) { super().merge(frequency: 'daily', size: "10M") }
        it do
          is_expected.to contain_file('/etc/logrotate.d/some_rule')
            .with_content(/maxsize 10M/)
        end
      end
    end
  end
end
