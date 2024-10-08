# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'fastapi::application' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'foobar' }
      context "With default parameters" do
        let(:params) { { :port => 8080 } }
        it { is_expected.to compile }
        it { is_expected.to contain_systemd__sysuser('deploy-foobar') }
        it { is_expected.to contain_file('/srv/deployment/foobar')
          .with_ensure('directory')
          .with_owner('deploy-foobar')
        }
        it {
          is_expected.to contain_systemd__service('foobar')
          .with_content(/User=deploy-foobar/)
          .with_content(%r{WorkingDirectory=/srv/deployment/foobar/deploy/src})
          .with_content(
            %r{ExecStart=/srv/deployment/foobar/venv/bin/uvicorn main:app \-\-host 0\.0\.0\.0 \-\-port 8080 \-\-workers 2 \-\-log-level info \-\-reload}
          )
        }
      end
    end
  end
end
