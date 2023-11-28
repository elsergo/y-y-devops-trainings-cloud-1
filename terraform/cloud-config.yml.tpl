#cloud-config
datasource:
 Ec2:
  strict_id: false
ssh_pwauth: no
users:
- name: ${ vm-user }
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ${ vm-user-ssh-pubkey }

write_files:
- encoding: b64
  content: ${ ua-config }
  owner: root:root
  path: /etc/yc/unified_agent/conf.d/config.yml
  permissions: '0644'

runcmd:
  - wget -O - https://monitoring.api.cloud.yandex.net/monitoring/v2/unifiedAgent/config/install.sh | bash
