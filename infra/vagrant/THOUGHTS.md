### Multi worker experiment on Windows
Limited support for hyperv images (at least in the official docs). Otherwise builds are very repeatable, albeit a bit slow. Might be faster with other hypervisors or images. VM startup requires manual selection of network switch.

Interop between linux bare-metal and linux vm will be easier with one big dynamic scaling vm under hyperv. As the configuration will be applied in the same way. No seperate configs juggling. Might be easier to use Hyperv PS extensions in combination with snapshotting if using one vm.

May revisit and look more into the cloud-init integrations.