This repo contains a collection of configuration files and scripts used in learning concepts in a variety of fields, mainly focused on infrastructure, clusters and networking. There are no best practices to be found here, just experimentation.

### Topics
[Administration](/docs/admin.md)
[Ansible](/docs/ansible.md)  
[Cilium](/)  
[Kubernetes](/)  

### Tools
[Redhat yaml language server](https://github.com/redhat-developer/yaml-language-server)

### Todo
- enable dhcp macvlan based on LB external ip assignment (so we can access service by hostname instead of ip), maybe by writing a controller?
- Fact caching for installed roles/pkgs [link](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html#caching-facts)
- roles/patch
- roles/loadbalancer
- replace reboot on reboot=true with a handler? [link](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html) 
- figure out dependencies and variable/parameter sharing/passing
- How to report missing variables in a multi-play book?