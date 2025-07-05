Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install hifis.toolkit
```

# Upgrade
```shell
uv lock --upgrade
uv sync
ansible-galaxy collection install -U hifis.toolkit
```

# Run

```shell
ansible-playbook -i inventory.ini debian.yaml --ask-become-pass

# Limiting to a host
ansible-playbook -i inventory.ini cachyos.yaml --ask-become-pass --limit 192.168.0.3

# Dry Run
ansible-playbook -i inventory.ini cachyos.yaml --ask-become-pass --check --diff --limit localhost
```
