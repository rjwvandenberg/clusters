### Scattered thoughts on provisioning
Is it worthwhile to automate the machine provisioning? Consumer grade hardware, no dhcp or dns facilities, so not really a good way to automate the provisioning (e.g. pxe). Could set it up, but would require maintenance that could inconvenience other users on the network. So instead looking into manual provisioning tools.

### Multi worker vagrant experiment on Windows
Limited support for hyperv images (at least in the official docs). Otherwise builds are very repeatable, albeit a bit slow. Might be faster with other hypervisors or images. VM startup requires manual selection of network switch.

Interop between linux bare-metal and linux vm will be easier with one big dynamic scaling vm under hyperv. As the configuration will be applied in the same way. No seperate configs juggling. Might be easier to use Hyperv PS extensions in combination with snapshotting if using one vm.

May revisit and look more into the cloud-init integrations. For now using manual provisioning with a single large machine and a snapshotted/exported base image machine.