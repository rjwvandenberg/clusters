# ssh jumping
```
ssh -J <proxy> <target>
```
Ansible ssh jumping: https://www.jeffgeerling.com/blog/2022/using-ansible-playbook-ssh-bastion-jump-host

# OCI networking
VCN - default configs for the virtual network, including available services
Subnet (private/public) configs specific to the subnet, routing and acl
Security List (adjustable by subnet) cidr,port control on the subnet
Routing Table (adjustable by subnet) ip routing on the subnet between cidrs and services
InternetGateway, internet access associated with the public subnet
Nat Gateway, internet access without assigning a public ip (e.g. the private subnet)
Access between hosts available by hostname or FQDN within the entire vcn (assuming the sec. list is set up correctly for your use case) 