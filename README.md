Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install hifis.toolkit
ansible-galaxy role install stefangweichinger.ansible_rclone
```

# Upgrade
```shell
uv lock --upgrade
uv sync
ansible-galaxy collection install -U hifis.toolkit
ansible-galaxy role install stefangweichinger.ansible_rclone --force
```

# Run

```shell
ansible-playbook -i inventory.ini main.yaml --ask-become-pass
```