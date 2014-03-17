base:
  'deployment_server:true':
    - match: grain
    - deploy.sync_all
  'deployment_target:*':
    - match: grain
    - deploy.sync_all
