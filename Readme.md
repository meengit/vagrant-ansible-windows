# Vagrant and the Ansible Provider on Microsoft Windows

In this guide, I describe a way make the Ansible provider of Vagrant work on Microsoft Windows. I try to rely on long proven and tested software to be also compatible with you and your instance of Microsoft Windows. Please use the [repository's issues](https://github.com/meengit/vagrant-ansible-windows/issues) to report a bug, suggest improvements or ask a question. My work initially based at Michael Maurizi's blog post <a href="#Maurizi001"><em>"Running Vagrant with Ansible Provisioning on Windows."</em></a> (2014)
 
## Context

When Microsoft Windows is sitting behind, Vagrant and its Ansible Provider aren't a good team. This is because you can use **Ansible only to manage Windows** hosts but **not to run on Windows** hosts. So, how can we work around this fact in the context of Vagrant?

**In short:** migrate to [Chef.io](https://chef.io) or a similar tool with full support for Microsoft Windows. **Or a bit longer**, in my opinion: don't touch Microsoft's WSL platform and use stable and proven software instead.

## Introduction

If you try to run *Vagrant with the Ansible Provider* on (native) Windows, you're may end up with this or a similar message of incompatibility:

```text
# ...
==> default: Running provisioner: ansible...
Windows is not officially supported for the Ansible Control Machine.
Please check https://docs.ansible.com/intro_installation.html#control-machine-requirements
Vagrant gathered an unknown Ansible version:


and falls back on the compatibility mode '1.8'.

Alternatively, the compatibility mode can be specified in your Vagrantfile:
https://www.vagrantup.com/docs/provisioning/ansible_common.html#compatibility_mode
    default: Running ansible-playbook...
The system cannot find the path specified.
Ansible failed to complete successfully. Any error output should be
visible above. Please fix these errors and try again.
```

A quick Google search will show you several solutions to workaround Ansible's incompatibility on Microsoft Windows. In my experience, especially proposals suggesting Microsoft's WSL platform often end up in a mess in the context of Vagrant. As far as I can see, this mainly happens because Vagrant is integrated with Windows (you have a Windows installer), and Ansible isn't. So, you have to build a bridge between Windows and WSL to make Vagrant able to "crossing the lines," which can become complex very fast, depending on your use case. But don't worry, there is a simple alternative. Instead of using WSL, we only have to make Vagrant believe that Ansible runs on a supported platform. To reach this, we use Cygwin.

## Install Cygwin

* Go to [Cygwin's website](https://www.cygwin.com/) and download the installer to your `Downloads` folder.
* Double-click the installer and install Cygwin in its recommended place `C:\cygwin64`.

## Install the required Cygwin packages for Ansible

***Hint: Currently, Cygwin's latest version of Python is 3.8. I'll do all steps based on this version. Feel free to use a newer version but don't forget to change the Python version in all further steps.***

Cygwin is using its installer to install *and update* Cygwin. Each time you want to install additional packages, you have to run the Cygwin installer. So, head over to your `Downloads` folder and re-run the Cygwin installer.

Click through the installation steps until the _"Select packages"_ window appears and change to the View _"Full."_ Now you have to select the following packages to install (use the drop-down in the column _"New"_):

* `python3`
* `python38-crypto`
  * Optional: `python38-asn1crypto`, `python38-cryptograhy`
* `python38-paramiko`
* `python38-setuptools`
  * Optional: `python-setuptools-wheel`
* `gcc-g++`
  * Optional: `gcc-core`
* `openssh`
  * Optional: `openssh-debuginfo`
* `wget`
  * Optional: `wget-debuginfo`

***Hint: In some cases, I noticed a crashing Cygwin installer if I type too fast into the search field. Be patience! Type into the search field, wait, click your package, wait, delete all texts in the search field, wait, search for new package, wait... and so on.***

![Cygwin Package manager](./images/cygwin-ansible-packages.png)


Now that you have selected all necessary packages for Ansible, click _"Next"_ and finish the installation process.

## Prepare the Cygwin Environment

* Go to `C:\cygwin64` and run `Cygwin.bat` _as Administrator_ to make sure, your Cygwin user folder and environment is fully operational. If you see no errors, exceptions or warnings, quite the Cygwin shell.
* Take your favorite text editor, open the `.bashrc` file of your Cygwin user (located in `C:\cygwin64\home\__USER__`), and add these lines at the end:

```bash
# Python HOME
# export PYTHONHOME=/usr
export PYTHONPATH=/lib/python3.8

alias pip='python3 -m pip'
```

* `PYTHONHOME` is the location of Python at runtime. _Enable this variable only if you have a reason for it._
* `PYTHONPATH` points Python to additional directories holding private libraries. In the context of Cygwin, Python gets installed in the `lib` folder of Cygwin, and we have to make sure, Python recognizing this fact.
* In the third line, we're map the `pip` command correctly into our Cygwin environment.

But why we have to set this? Depending on your environment, it's maybe optional. Settings these properties makes sure we have no conflicts with possible "native" Python installations on Microsoft Windows (for instance in `C:\Python39\python.exe`).

### Create the `ansible.cfg`

Create your "main" configuration file for Ansible in your Cygwin environment:

* Go to `C:\cygwin64\home\__USER__`
* Create the file `.ansible.cfg` with the following contents:

```bash
[ssh_connection]
control_path = /tmp
```

* Go to `C:\` and create the directory `C:\tmp\`

### Prepare your inventory file

In some cases, it may be helpful to create a dedicated inventory file just for Windows. However, you can also modify an existing inventory file. To make your inventory file ready to run in Cygwin's environment, first ask Vagrant for its SSH configuration. Open a Cygwin shell _as Administrator_ (`C:\cygwin64\Cygwin.bat`), go to your Vagrant project root (`cd /cygdrive/c/path/to/your/project/root`) and run:

```bash
vagrant ssh-config

# Output:
Host default
  HostName 127.0.0.1
  User vagrant
  Port 4000
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile C:/Users/__USER__/.vagrant.d/insecure_private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

Update your inventory file with the results from `vagrant ssh-config`, but make sure `ansible_ssh_private_key_file` is set to Cgywin's full path:

```bash
[server]
127.0.0.1

[server:vars]
ansible_user=vagrant
# ansible_ssh_pass=vagrant # Optional
ansible_ssh_private_key_file=/cygdrive/c/Users/__USER__/.vagrant.d/insecure_private_key
ansible_connection=ssh
ansible_port=4000
ansible_debug=1
```

### Optional but recommended

Microsoft Windows may have a problem with the long filenames which are used by Cygwin sometimes. To prevent time-consuming errors relying on long path names, set the Windows registry value of `LongPathsEnabled` in `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem` to `1`.

![Set Regedit value](./images/regedit-LongPathsEnabled.png)

## Execution environment

Now, we are prepared for a first run. You can execute Vagrant and Ansible either in the PowerShell or in a Cygwin shell.

### PowerShell

To run Vagrant and Ansible in the PowerShell, you must "redirect" Ansible's commands from the PowerShell to a Cygwin shell:

* Create a directory called `Cygwin` in `C:\tools\`. If `C:\tools\` does not already exists, create it.
* "Redirect" the Ansible commands from PowerShell to Cygwin when they are called. To do this, you have to create a BAT file for each Ansible command. You can find a complete list to copy or download [here](https://github.com/meengit/vagrant-ansible-windows/tree/main/tools/Cygwin). For demonstration purposes, I'll illustrate here only the BAT file for the `ansible` command itself:

`ansible.bat`

```bat
@echo off

set CYGWIN=C:cygwin

REM You can switch this to work with bash with %CYGWIN%binzsh.exe
set SH=%CYGWIN%/bin/bash.exe

"%SH%" -c "/usr/local/bin/ansible %*"
```

#### Set the Windows' environment variables

Add `C:\tools\Cygwin` to Windows's _System Variables_:

![Edit Windows's System Variables](./images/win-system-var.png)

Add `C:\tools\Cygwin` to your user's path:

![Edit Windows User's path](./images/win-user-path.png)


#### Run it!

```bash
vagrant up --provision
```

### Cygwin shell

In a Cygwin shell, you can run Vagrant and the Ansible provider directly. To do so, open a Cygwin shell _as administrator_ (`C:\cygwin64\Cygwin.bat`), navigate to your project root (`cd /cygdrive/c/path/to/your/project/root`) and run:

```bash
vagrant up --provision
```

## Prevent Vagrant from calling the Ansible provider and run it independently instead

It is also possible to run Ansible independently from Vagrant. With this workaround, Vagrant builds your VM but does not run Ansible. To do so, you have to update the Vagrant file a bit and create a little Shell script that manages Vagrant and Ansible.

### Prepare your `Vagrantfile`

Modify your `Vagrantfile` along with the following template:

```ruby
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

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = './ansible/main.yml'
    ansible.inventory_path = './ansible/develop.ini'
  end unless Vagrant::Util::Platform.windows? # <<< Run the provisioner unless we are on Windows
end
```

### Create the Shell script and run it

To run Vagrant and Ansible in two steps, we create a little Shell script for the Cygwin environment:

`vagrant-win.sh`:

```bash
!#/usr/bin/env bash

set -x -e

vagrant up --provision # --provider virtualbox
ansible-playbook -i __INVENTORY__ --ssh-extra-args='-p 4000 -i /cygdrive/c/Users/__USER__/.vagrant.d/insecure_private_key' --ssh-common-args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o IdentitiesOnly=yes' __PLAYBOOK__
```

Replace `__INVENTORY__` with the path to your inventory file, `__PLAYBOOK__` with the path to your playbook entry file, and `__USER__` with your user name and save the file in the same place as the `Vagrantfile` of your project.

OK! Great job, you are ready to start your VM and provision afterward. Do this in the Cygwin shell (_as Administrator_). Let's go:

```bash
. ./vagrant-win.sh
```

## Bibliography

<a name="Maurizi001" style="text-decoration: none;color: black;">Maurizi, M. (2014, October 30).</a> _Running Vagrant with Ansible Provisioning on Windows._ Azavea. https://www.azavea.com/blog/2014/10/30/running-vagrant-with-ansible-provisioning-on-windows/
