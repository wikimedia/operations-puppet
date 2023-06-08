# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'puppetserver' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetserver::g10k').with_ensure('absent') }
      end
      context "with g10k_sources" do
        let(:params) do
          {
            g10k_sources: {
              'production' => {
                'remote' => 'https://git.example.org/puppet.git'
              }
            }
          }
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetserver::g10k').with_ensure('present') }
      end
    end
  end
end
