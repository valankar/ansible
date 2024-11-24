Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install hifis.toolkit
ansible-galaxy install stefangweichinger.ansible_rclone
```

# Run

```shell
ansible-playbook -i inventory.ini install.yaml --ask-become-pass
```