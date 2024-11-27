Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install hifis.toolkit
ansible-galaxy role install stefangweichinger.ansible_rclone
```

# Run

```shell
ansible-playbook -i inventory.ini main.yaml --ask-become-pass
```