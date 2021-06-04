# Vagrant and the Ansible Provider on Microsoft Windows

In this guide, I describe a way make the Ansible Provider of Vagrant work on Microsoft Windows. I try to rely on long proven and tested software to be also compatible with you and your instance of Microsoft Windows. Please use the [repository's issues](https://github.com/meengit/vagrant-ansible-windows/issues) to report a bug, suggest improvements or ask a question. My work initially based at Michael Maurizi's blog post <a href="#Maurizi001"><em>"Running Vagrant with Ansible Provisioning on Windows."</em></a> (2014)
 
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

A quick Google search will show you several solutions to workaround Ansible's incompatibility on Microsoft Windows. In my experience, especially proposals suggesting Microsoft's WSL platform often end up in a mess in the context of Vagrant. As far as I can see, this mainly happens because Vagrant is integrated with Windows (you have a Windows installer), and Ansible isn't. So, you have to build a bridge between Windows and WSL to make Vagrant able to "crossing the lines," which can become complex very fast, depending on your use case. But don't worry, there is a simple alternative based on Cygwin.

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

### Optional but recommended

Microsoft Windows may have a problem with the long filenames which are used by Cygwin sometimes. To prevent time-consuming errors relying on long path names, set the Windows registry value of `LongPathsEnabled` in `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem` to `1`.

![Set Regedit value](./images/regedit-LongPathsEnabled.png)

### Install Ansible in the Cygwin Shell

Open a Cygwin shell _as administrator_ (`C:\cygwin64\Cygwin.bat`) and install Ansible using `pip`. Because some users reported issues with a missing [`wcwidth`](https://pypi.org/project/wcwidth/) package, I recommend first installing `wcwidth` to be sure it is present, and then Ansible:

```bash
pip install wcwidth
pip install ansible
```

### Create the `ansible.cfg`

Create your "main" configuration file for Ansible in your Cygwin environment:

* Go to `C:\cygwin64\home\__USER__`
* Create the file `.ansible.cfg` with the following contents:

```bash
[ssh_connection]
control_path = /tmp
```

`/tmp` in the Cygwin Shell will be mapped to  `C:\cygwin64\tmp\` on Windows.

### Access Vagrant's `insecure_private_key` (or a custom SSH key)

It's a common use case to use Vagrant's insecure SSH private key for Vagrant's Ansible Provider. It's a common use case to use Vagrant's insecure SSH private key for Vagrant's Ansible Provider in Ansible's inventory file:

```text
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
```


Even you use a custom SSH private key instead of Vagrant's, the key must be accessible from the Cygwin Shell. For Vagrant's insecure SSH private key, I suggest linking it from your Windows' user home to your Cygwin user home. To do so, open a Cygwin Shell _as Administrator_ and run from your user home:

```bash
# in /home/__USER__
$ ln -s /cygdrive/c/Users/run/.vagrant.d/ .vagrant.d
```

Alternatively, you can also create a Windows related inventory file or update your inventory file with the Cygwin path to Vagrant's insecure private key:

```text
ansible_ssh_private_key_file=/cygdrive/c/Users/__USER__/.vagrant.d/insecure_private_key
```

So, an example inventory file can look like this:

```bash
# Application Server
[app]
192.168.60.6

# Database Server
[db]
192.168.60.8

# Group 'common' with all servers
[common:children]
app
db

[common:vars]
ansible_ssh_user=vagrant
# for ln -s "solution:" ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
ansible_ssh_private_key_file=/cygdrive/c/Users/__USER__/.vagrant.d/insecure_private_key
ansible_ssh_common_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no"
```

Suppose you are using a custom private key. In that case, I suggest to place it in the SSH directory of your Cygwin user (`C:\cygwin64\home\__USER__\.ssh` in Windows Explorer) and link them to your inventory file:

```text
ansible_ssh_private_key_file=~/.ssh/__YOUR_PRIVATE_KEY__
```

## Run `vagrant`

Now, we should be prepared to run `vagrant up.` To do so, open a Cygwin Shell _as Administrator_, navigate to your Vagrant project and bring it up:

```bash
cd /cygdrive/c/path/to/your/project/root
vagrant up --provision
```

### Notes about the technical background

This guide aims to be as simple and as generic as possible. As far as I can see, running Vagrant and its Ansible Provider in the Cygwin Shell is actually the easiest and most secure way to not run into network or permission issues. Another solution, aside from WSL2 we try to avoid, can be to "redirect" the Ansible commands from PowerShell to Cygwin using BAT files, for example:

`ansible.bat`

```bat
@echo off

set CYGWIN=C:cygwin

REM You can switch this to work with bash with %CYGWIN%binzsh.exe
set SH=%CYGWIN%/bin/bash.exe

"%SH%" -c "/usr/local/bin/ansible %*"
```

The disadvantages of this solution, which I discovered, are also several types of SSH connection issues when the Ansible Provider starts. If you're using the Cygwin Shell, a full Bash environment getting initiated (`bash --login -i`). In opposite, calling Ansible via a BAT file, you don't get a complete interactive Cygwin environment. So, depending on your Windows Build and your environment, you may end up in either issue:

- permission issues because the process didn't get administration privileges via BAT file;
- SSH connection issues because Windows calls the System32 SSH from the PowerShell environment; instead of Cygwin's SSH implementation.

## Troubleshooting

### How do I get Vagrant's SSH configuration?

You have to run Vagrant at a minimum once to create your VM. If your Ansible Provider fails, you can temporarily disable the provider by adding a `unless` statement to the end of the provider configuration in your `Vagrantfile`. Example:

```diff
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
-   end
+   end unless Vagrant::Util::Platform.windows? # <<< Run the provisioner unless we are on Windows
  end
```

Afterward, run:

```bash
vagrant up
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

## Bibliography

<a name="Maurizi001" style="text-decoration: none;color: black;">Maurizi, M. (2014, October 30).</a> _Running Vagrant with Ansible Provisioning on Windows._ Azavea. https://www.azavea.com/blog/2014/10/30/running-vagrant-with-ansible-provisioning-on-windows/
