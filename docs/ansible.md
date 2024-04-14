### Ansible summary
Automated state management for systems. [Inventories](https://docs.ansible.com/ansible/latest/inventory_guide/index.html) define host/group structures and their variables. 
Start with a simple 01-hosts.yaml file that lists all servers. Then add grouping/role names in subsequent 0x-role.yaml files. Test groups of a particular host with:
```yaml
ansible-inventory -i <inventory_path> --list --limit <role/group/host>
```
[Plays](https://docs.ansible.com/ansible/latest/getting_started/get_started_playbook.html) are ordered lists of tasks to be applied to inventories. 
[Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html) allow for a decoupling of hosts and tasks.
[Facts](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html) are used discover host facts at the start of a play and share variables across plays.