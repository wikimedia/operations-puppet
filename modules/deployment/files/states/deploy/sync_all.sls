git-core:
  pkg.installed

python-redis:
  pkg.installed

deploy.sync_all:
  ## We need to use cmd.run until module.run supports returners
  #module.run:
  #  - name: deploy.sync_all
  #  - require:
  #    - pkg: git-core
  #    - pkg: python-redis
  cmd.run:
    - name: salt-call --return=deploy_redis deploy.sync_all
    - require:
      - pkg: git-core
      - pkg: python-redis
