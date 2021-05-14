# -*- mode: ruby -*-
# vi: set ft=ruby :
# frozen_string_literal: true

VERSION = '2'

module OS
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def self.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def self.unix?
    !OS.windows?
  end

  def self.linux?
    OS.unix? and not OS.mac?
  end
end

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

  if OS.windows?
    puts "Vagrant launched on Microsoft Windows. 'config.vm.provision' ignored!"
  else
    puts "Vagrant launched from #{OS.mac || OS.unix || OS.linux || 'unknown'} platform."

    # Provisioning configuration for Ansible.
    config.vm.provision 'ansible' do |ansible|
      ansible.playbook = './ansible/main.yml'
      ansible.inventory_path = './ansible/develop.ini'
    end
  end
end