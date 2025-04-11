# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'package_builder::environments' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'Change Defaults' do
        context 'extra_packages' do
          let(:params) { {extra_packages: {'bookworm' => ['foobar']}} }

          it { is_expected.to compile.with_all_deps }
          it 'is applied on the requested distribution' do
            is_expected.to contain_package_builder__pbuilder_base('bookworm-amd64')
              .with_extra_packages(['foobar'])
          end
          it 'is ignoring other distributions' do
            is_expected.to contain_package_builder__pbuilder_base('sid-amd64')
              .with_extra_packages([])
          end
        end
        context 'extra_packages with default' do
          let(:params) { {extra_packages: {'default' => ['foobar']}} }

          it { is_expected.to compile.with_all_deps }
          it 'is applied on multiple distributions' do
            is_expected.to contain_package_builder__pbuilder_base('bookworm-amd64')
              .with_extra_packages(['foobar'])
            is_expected.to contain_package_builder__pbuilder_base('sid-amd64')
              .with_extra_packages(['foobar'])
          end
        end
      end
    end
  end
end
