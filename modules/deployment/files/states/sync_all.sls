git-core:
  pkg.installed

python-redis:
  pkg.installed

deploy.sync_all:
  module.run:
    - name: deploy.sync_all
    - require:
      - pkg: git-core
      - pkg: python-redis
