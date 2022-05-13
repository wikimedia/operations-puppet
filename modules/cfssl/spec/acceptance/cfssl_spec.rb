# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'cfssl class' do
  describe 'running puppet code' do
    it 'work with no errors' do
      pp = "class {'cfssl': }"
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
  end
end
