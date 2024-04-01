### Vagrant hyperv
[https://developer.hashicorp.com/vagrant/docs/boxes/base](https://developer.hashicorp.com/vagrant/docs/boxes/base)
[https://developer.hashicorp.com/vagrant/docs/providers/hyperv/boxes](https://developer.hashicorp.com/vagrant/docs/providers/hyperv/boxes)
After installing the base os apply the following
'''
sudo apt update
sudo apt upgrade
sudo apt install linux-virtual linux-cloud-tools-virtual linux-tools-virtual vim
curl https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub > ~/.ssh/authorized_keys
chmod 0700 .ssh
chmod 0600 .ssh/authorized_keys
sudo apt remove lxd-installer linux-generic snapd --autoremove --purge
'''
Could remove cloudinit and friends to have less dynamic initialization with baremetal.
'''
sudo update-initramfs -u
'''
Apply visudo changes. 