#!/bin/bash

function vagrant_common() {
  arch-chroot "${MOUNT}" /usr/bin/pacman -S --noconfirm netctl polkit

  local NEWUSER="vagrant"
  # setting the user credentials
  arch-chroot "${MOUNT}" /usr/bin/useradd -m -U "${NEWUSER}"
  echo -e "${NEWUSER}\n${NEWUSER}" | arch-chroot "${MOUNT}" /usr/bin/passwd "${NEWUSER}"

  # setting sudo for the user
  cat <<EOF >"${MOUNT}/etc/sudoers.d/${NEWUSER}"
Defaults:${NEWUSER} !requiretty
${NEWUSER} ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 440 "${MOUNT}/etc/sudoers.d/${NEWUSER}"

  # setup network
  cat <<EOF >"${MOUNT}/etc/systemd/network/eth0.network"
[Match]
Name=eth0

[Network]
DHCP=ipv4
EOF

  # install vagrant ssh key
  arch-chroot "${MOUNT}" /bin/bash -e <<EOF
install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
EOF

  # setting automatic authentication for any action requiring admin rights via Polkit
  cat <<EOF >"${MOUNT}/etc/polkit-1/rules.d/49-nopasswd_global.rules"
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("vagrant")) {
        return polkit.Result.YES;
    }
});
EOF
}