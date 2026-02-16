# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "query_service::blazegraph", type: :define do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |_, facts|
    let(:facts) { facts }
    before(:each) do
      Puppet::Parser::Functions.newfunction(:secret, type: :rvalue) do |_|
        "fake_secret"
      end
    end

    let(:title) { "wdqs-blazegraph" }
    let(:params) do
      {
        journal: "wikidata",
        package_dir: "/srv/deployment/wdqs/wdqs",
        data_dir: "/srv/wdqs",
        log_dir: "/var/log/wdqs",
        port: 9999,
        config_file_name: "RWStore.wikidata.properties",
        heap_size: "1g",
        username: "blazegraph",
        deploy_name: "wdqs",
        use_deployed_config: false,
        logstash_logback_port: 11_514,
        extra_jvm_opts: [],
        use_geospatial: false,
        federation_user_agent: "TEST User-Agent",
        blazegraph_main_ns: "wdq",
        prefixes_file: "prefixes.conf",
        use_oauth: false,
        internal_federated_endpoints: {
          "https://internal/sparql" => %w[
            https://alias1/sparql
            https://alias2/sparql
          ],
          "https://internal2/sparql" => ["https://alias3/sparql"]
        },
        only_throttle_cdn: true
      }
    end

    context "with systemd" do
      it do
        is_expected.to contain_file(
          "/lib/systemd/system/wdqs-blazegraph.service"
        ).with_content(
          %r{runBlazegraph.sh -f /etc/wdqs/RWStore.wikidata.properties}
        )
      end
      it do
        is_expected.to contain_file(
          "/etc/wdqs/RWStore.wikidata.properties"
        ).with_content(%r{AbstractJournal.file=/srv/wdqs/wikidata.jnl})
      end
      it do
        is_expected.to contain_file(
          "/etc/wdqs/allowlist-wdqs-blazegraph.txt"
        ).with_content(
          %r{https://internal/sparql,https://alias1/sparql,https://alias2/sparql}
        )
      end
      it do
        is_expected.to contain_file(
          "/etc/default/wdqs-blazegraph"
        ).with_content(/-Dhttp.proxyExcludedHosts=internal,internal2/)
      end
      it do
        is_expected.to contain_file(
          "/etc/default/wdqs-blazegraph"
        ).with_content(
          /-Dwdqs.enable-throttling-if-header=X-BIGDATA-READ-ONLY&&!X-Disable-Throttling/
        )
      end
    end
  end
end

describe "query_service::blazegraph", type: :define do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |_, facts|
    let(:facts) { facts }
    before(:each) do
      Puppet::Parser::Functions.newfunction(:secret, type: :rvalue) do |_|
        "fake_secret"
      end
    end

    let(:title) { "wdqs-blazegraph" }
    let(:params) do
      {
        journal: "wikidata",
        package_dir: "/srv/deployment/wdqs/wdqs",
        data_dir: "/srv/wdqs",
        log_dir: "/var/log/wdqs",
        port: 9999,
        config_file_name: "RWStore.wikidata.properties",
        heap_size: "1g",
        username: "blazegraph",
        deploy_name: "wdqs",
        use_deployed_config: true,
        logstash_logback_port: 11_514,
        extra_jvm_opts: [],
        use_geospatial: false,
        federation_user_agent: "TEST User-Agent",
        blazegraph_main_ns: "wdq",
        prefixes_file: "prefixes.conf",
        use_oauth: false,
        internal_federated_endpoints: {
        },
        only_throttle_cdn: false
      }
    end

    context "with systemd" do
      it do
        is_expected.to contain_file(
          "/lib/systemd/system/wdqs-blazegraph.service"
        ).with_content(/runBlazegraph.sh -f RWStore.wikidata.properties/)
      end
    end
  end
end

describe "query_service::blazegraph", type: :define do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |_, facts|
    let(:facts) { facts }
    before(:each) do
      Puppet::Parser::Functions.newfunction(:secret, type: :rvalue) do |_|
        "fake_secret"
      end
    end

    let(:title) { "wdqs-categories" }
    let(:params) do
      {
        journal: "categories",
        package_dir: "/srv/deployment/wdqs/wdqs",
        data_dir: "/srv/wdqs",
        log_dir: "/var/log/wdqs",
        port: 9090,
        config_file_name: "RWStore.categories.properties",
        heap_size: "1g",
        username: "blazegraph",
        deploy_name: "wdqs",
        use_deployed_config: false,
        logstash_logback_port: 11_514,
        extra_jvm_opts: [],
        use_geospatial: true,
        federation_user_agent: "TEST User-Agent",
        blazegraph_main_ns: "wdq",
        prefixes_file: "prefixes.conf",
        use_oauth: false,
        internal_federated_endpoints: {
        },
        only_throttle_cdn: false
      }
    end

    context "with systemd" do
      it do
        is_expected.to contain_file(
          "/lib/systemd/system/wdqs-categories.service"
        ).with_content(
          %r{runBlazegraph.sh -f /etc/wdqs/RWStore.categories.properties}
        )
      end
      it do
        is_expected.to contain_file(
          "/lib/systemd/system/wdqs-categories.service"
        ).with_content(%r{BLAZEGRAPH_CONFIG=/etc/default/wdqs-categories})
      end
      it do
        is_expected.to contain_file(
          "/etc/default/wdqs-categories"
        ).with_content(/PORT=9090/)
      end
      it do
        is_expected.to contain_file(
          "/etc/wdqs/RWStore.categories.properties"
        ).with_content(%r{AbstractJournal.file=/srv/wdqs/categories.jnl})
      end
    end
  end
end
