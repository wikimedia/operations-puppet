# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'Wmflib::Portrange' do
  describe 'valid handling' do
    ['1:65535', '5:20'].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end
  describe 'invalid handling' do
    [1, '1', '65536', '1:65536', '-1:5'].each do |value|
      describe value.inspect do
        it { is_expected.not_to allow_value(value) }
      end
    end
  end
end
