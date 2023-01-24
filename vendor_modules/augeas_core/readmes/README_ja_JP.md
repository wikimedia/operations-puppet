
# augeas_core

#### 目次

1. [説明](#description)
2. [セットアップ - augeas_core導入の基本](#setup)
    * [セットアップ要件](#setup-requirements)
    * [augeas_coreモジュールの利用方法](#beginning-with-augeas)
3. [使用 - 設定オプションと追加機能](#usage)
4. [参考 - モジュールの機能と動作について](#reference)
5. [制約 - OS互換性など](#limitations)
6. [開発 - モジュール貢献についてのガイド](#development)

<a id="description"></a>
## 説明

`augeas_core`モジュールは、Augeasを用いた設定の管理に使用されます。このモジュールは、AugeasライブラリとRubyバインディングが存在するホストに適しています。

<a id="setup"></a>
## セットアップ

<a id="setup-requirements"></a>
### セットアップ要件

このモジュールを使用するには、AugeasライブラリとRubyバインディングをインストールする必要があります。`puppet-agent`パッケージを使用している場合は、ほとんどのプラットフォームでこの前提条件は満たされています。

<a id="beginning-with-augeas"></a>
### augeas_coreモジュールの利用方法

`augeas`を用いて設定ファイルを管理するには、以下のコードを使用します。

```
augeas { 'add_services_entry':
  context => '/files/etc/services',
  incl    => '/etc/services',
  lens    => 'Services.lns',
  changes => [
    'ins service-name after service-name[last()]',
    'set service-name[last()] "Doom"',
    'set service-name[. = "Doom"]/port "666"',
    'set service-name[. = "Doom"]/protocol "udp"'
  ]
}
```

<a id="usage"></a>
## 使用

参考文書についてはREFERENCE.mdを、使用法の詳細については[例](https://puppet.com/docs/puppet/latest/resources_augeas.html)を参照してください。

<a id="reference"></a>
## リファレンス

リファレンス文書については、REFERENCE.mdを参照してください。

このモジュールは、Puppet Stringsを用いて文書化されています。

Stringsの仕組みの簡単な概要については、Puppet Stringsに関する[こちらのブログ記事](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules)または[README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md)を参照してください。

文書をローカルで作成するには、以下のコマンドを実行します。
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
このコマンドにより、閲覧可能な`_index.html`ファイルが`doc`ディレクトリに作成されます。ここで利用可能なリファレンスはすべて、コードベースに埋め込まれたYARD形式のコメントから生成されます。このモジュールに関して何らかの開発をする場合は、影響を受ける文書も更新する必要があります。

<a id="limitations"></a>
## 制約

このモジュールは、AugeasライブラリおよびRubyバインディングがインストールされたプラットフォームでのみ使用できます。

<a id="development"></a>
## 開発

Puppet ForgeのPuppet Labsモジュールは、オープンプロジェクトです。プロジェクトをさらに発展させるには、コミュニティへの貢献が不可欠です。Puppetが役立つ可能性のある膨大な数のプラットフォーム、無数のハードウェア、ソフトウェア、デプロイメント構成に我々がアクセスすることはできません。

弊社は、できるだけ変更に貢献しやすくして、弊社のモジュールがユーザの環境で機能する状態を維持したいと考えています。弊社では、状況を把握できるよう、貢献者に従っていただくべきいくつかのガイドラインを設けています。

詳細については、[モジュール貢献ガイド](https://docs.puppetlabs.com/forge/contributing.html)を参照してください。
