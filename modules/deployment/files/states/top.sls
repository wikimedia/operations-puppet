base:
  'deployment_target:*':
    - match: grain
    - deploy.sync_all
