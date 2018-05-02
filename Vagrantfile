# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
vagrant_config = YAML.load_file("provisioning/virtualbox.conf.yml")

Vagrant.configure("2") do |config|

  config.vm.box = vagrant_config['box']

  # Bring up the Devstack controller node on Virtualbox
  config.vm.define "odl_dev_vm" do |odl_vm|

    odl_vm.vm.provision :shell, path: "provisioning/setup-odl-dev-vm.sh",
                         privileged: false,
                         args: [
                           vagrant_config['http_https_proxy'],
                           vagrant_config['odl_dev_vm']['forwarded_port'],
                           vagrant_config['gerrit_parameters']['gerrit_id'],
                           vagrant_config['gerrit_parameters']['gerrit_username'],
                           vagrant_config['gerrit_parameters']['gerrit_ssh_key_filename']
                         ]

    config.vm.provider "virtualbox" do |vb|
      # Display the VirtualBox GUI when booting the machine
      vb.gui = true

      # Customize the amount of memory on the VM:
      vb.memory = vagrant_config['odl_dev_vm']['memory']
      vb.cpus = vagrant_config['odl_dev_vm']['cpus']

      # Configure external provide network in VM
      config.vm.network "private_network", ip: vagrant_config['odl_dev_vm']['provider_ip']

      # Enable port forward on desired port
      config.vm.network "forwarded_port", guest: vagrant_config['odl_dev_vm']['forwarded_port'], host: vagrant_config['odl_dev_vm']['forwarded_port']
    end
  end

  config.vm.synced_folder '.', '/home/vagrant/sync'

end
