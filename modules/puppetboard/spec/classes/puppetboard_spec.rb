# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'puppetboard' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # let(:params) { {} }
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('puppetboard') }
        it do
          is_expected.to contain_file('/etc/puppetboard/settings.py')
            .with_content(/SECRET_KEY = os.urandom\(24\)/)
            .with_content(/LOCALISE_TIMESTAMP = True/)
            .with_content(/PUPPETDB_CERT = None/)
        end
      end
    end
  end
end
