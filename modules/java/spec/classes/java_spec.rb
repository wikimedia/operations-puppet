# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'java' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
        context "On #{os}" do
            let(:facts) { facts }
            let(:node_params) { { 'site' => 'eqiad' } }

            ['8', '11'].each do |jdk_version|
                context "With just the Jdk #{jdk_version}" do
                    let(:params) do
                        {
                            :java_packages => [
                                {
                                :version => jdk_version,
                                :variant => 'jdk',
                                }
                            ]
                        }
                    end
                    it { is_expected.to compile }
                    it { is_expected.to contain_alternatives__java(jdk_version) }
                end
            end

            context 'With both Jdk' do
                let(:params) do
                    {
                        :java_packages => [
                            { :version => '8', :variant => 'jdk', },
                            { :version => '11', :variant => 'jdk', },
                        ]
                    }
                end
                it { is_expected.to compile }
                it { is_expected.to contain_alternatives__java(8) }
            end
        end
    end
end
