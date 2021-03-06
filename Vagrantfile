# -*- mode: ruby -*-
# vi: set ft=ruby :

[
  'vagrant-cachier',
  'vagrant-fsnotify'
].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "Please install #{plugin} using 'vagrant plugin install #{plugin}'"
  end
end

AVAILABLE_MEMORY = `hostinfo`.match(/memory available: (\d+\.\d+)/)[1].to_f
AVAILABLE_CPU    = `hostinfo`.match(/(\d+) processors are logically available./)[1].to_i
# needs to be a multiple of 4MB
VM_MEMORY        = (AVAILABLE_MEMORY * 0.2 * 1024).fdiv(4).round * 4
VM_CPU           = AVAILABLE_CPU / 2

# Temporary workaround to Python bug in macOS High Sierra which can break Ansible
# https://github.com/ansible/ansible/issues/34056#issuecomment-352862252
# This is an ugly hack tightly bound to the internals of Vagrant.Util.Subprocess, specifically
# the jailbreak method, self-described as "quite possibly, the saddest function in all of Vagrant."
# That in turn makes this assignment the saddest line in all of Vagrantfiles.
ENV["VAGRANT_OLD_ENV_OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] = "YES"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.define 'box'

  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = 'homelab'
  config.vm.box_url = 'file://vmware.box'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.ssh.username = 'ubuntu'

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.
  config.vm.provider :vmware_desktop do |vmware|
    vmware.gui = true
    vmware.vmx["memsize"] = VM_MEMORY
    vmware.vmx["numvcpus"] = VM_CPU
    vmware.vmx["ethernet0.virtualdev"] = "vmxnet3" # vagrant overrides this

    # https://www.vagrantup.com/docs/vmware/boxes.html#vmx-whitelisting
    # box assumes 192 in /etc/netplan/01-netcfg.yaml
    vmware.vmx["ethernet0.pcislotnumber"] = "192"
  end

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'ansible/playbook.yml'
    ansible.compatibility_mode = '2.0'
    ansible.raw_arguments = ['--diff']
  end

  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      # The nolock option can be useful for an NFSv3 client that wants to avoid
      # the NLM sideband protocol. Without this option, apt-get might hang if it
      # tries to lock files needed for /var/cache/* operations. All of this can
      # be avoided by using NFSv4 everywhere. Please note that the tcp option is
      # not the default.
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end
end
