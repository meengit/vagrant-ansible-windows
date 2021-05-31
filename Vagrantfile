# -*- mode: ruby -*-
# vi: set ft=ruby :
# frozen_string_literal: true

VERSION = '2'

Vagrant.configure(VERSION) do |config|
  # # Your configuration, for example:
  #
  # config.vm.box = 'debian/buster64'
  #
  # # Set the provider to host the VM
  # config.vm.provider 'virtualbox' do |vm|
  #   vm.gui = false
  #   vm.memory = 2048
  # end
  #
  # ...

  # Provisioning configuration for Ansible.
  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = './ansible/main.yml'
    ansible.inventory_path = './ansible/develop.ini'
  end unless Vagrant::Util::Platform.windows?
end
