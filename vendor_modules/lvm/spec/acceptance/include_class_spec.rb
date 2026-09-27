# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'include the lvm class' do
  pp = <<-MANIFEST
      include ::lvm
  MANIFEST

  it 'run the manifest' do
    apply_manifest(pp, catch_failures: true)
  end
end
