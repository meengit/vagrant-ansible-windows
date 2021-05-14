!#/usr/bin/env bash

# Replace "__INVENTORY__", "__USER__", and "__PLAYBOOK__"

set -x -e

vagrant up --provision # --provider virtualbox
ansible-playbook -i __INVENTORY__ --ssh-extra-args='-p 4000 -i /cygdrive/c/Users/__USER__/.vagrant.d/insecure_private_key' --ssh-common-args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o IdentitiesOnly=yes' __PLAYBOOK__
