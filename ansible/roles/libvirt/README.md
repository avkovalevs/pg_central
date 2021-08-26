Role Name
=========

The role will install libvirt related packages, setup sysctl parameters, download images needed for building VMs.
Other useful commands listed below:
# --Create default network and list it
~~~
# virsh net-start default
# virsh net-list
~~~
# -- Generate VM using cli
~~~
# virt-install -n ubuntu20 -r 2048 --os-variant=ubuntu20.04 --location http://us.archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/  --disk /var/lib/libvirt/images/ubuntu20.img,size=10,device=disk,bus=virtio --graphics none -w bridge=virbr0,model=virtio --extra-args 'console=ttyS0,115200n8 serial' --force --debug
~~~
# --Check IP addresses used by VMs
~~~
# virsh net-dhcp-leases default
~~~
# -- List of VMs
# virsh list --all
# -- Clone VM target -> source and create a new image file
# virt-clone --original ubuntu20 --auto-clone
# -- Remove network info to be unique except account avkovalevs and firewall-rules
# virt-sysprep -d ubunt20-clone --operations all,-user-account,-firewall-rules
# -- Delete VM including image
# virsh destroy testvm
# virsh undefine --remove-all-storage testvm
# -- Start VM
# virsh start node1


License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
