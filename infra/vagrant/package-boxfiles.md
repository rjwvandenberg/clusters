cd boxfiles directory
tar czvf ../vagrant.box ./*
cd ..
vagrant box add --name <name> vagrant.box