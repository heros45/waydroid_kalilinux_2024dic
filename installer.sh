#!/bin/bash
# script name: install_waydroid.sh
# description: Install Waydroid on unsupported Debian based distro caused by incompatible python3-gbinder package
# related to : https://github.com/waydroid/waydroid/issues/214#issuecomment-1120926304
# author     : Wachid Adi Nugroho <wachidadinugroho.maya@gmail.com>
# date       : 2022-07-07

export distro=$(grep -oP '(?<=^NAME=).*' /etc/os-release)

if [[ -f /usr/bin/dpkg ]];
then
  export arch=$(dpkg --print-architecture)
  if ! ([[ $arch == "amd64" ]] || [[ $arch == "arm64" ]]);
  then
    echo "You're using $arch machine, currently waydroid repo only provides deb packages for amd64 and arm64 machine."
    echo "If you're really want to install waydroid on this $arch machine you should build it with all the dependencies."
    echo "Go check this link https://gist.github.com/cniw/98e204d7dbc73a3fa1bf61629b2a2fc1 or just run this command"
    echo -e "\n    \`curl -s https://gist.githubusercontent.com/cniw/98e204d7dbc73a3fa1bf61629b2a2fc1/raw | bash\`\n"
    exit 0
  fi
  
  [[ ${distro} =~ Debian ]] && \
  export codename=bullseye || \
  export codename=focal

  [[ ! -f /usr/bin/curl ]] && sudo apt install -y curl
  sudo curl https://repo.waydro.id/waydroid.gpg -o /usr/share/keyrings/waydroid.gpg
  echo "deb [signed-by=${_}] https://repo.waydro.id/ ${codename} main" | \
  sudo tee /etc/apt/sources.list.d/waydroid.list

  sudo apt update
  sudo apt install -y \
  build-essential cdbs devscripts equivs fakeroot \
  git git-buildpackage git-lfs \
  libgbinder-dev

  mkdir ~/build-packages
  cd ${_}
  git clone https://github.com/waydroid/gbinder-python.git
  cd gbinder-python
  curl https://raw.githubusercontent.com/MrCyjaneK/waydroid-build/main/build_changelog -o build_changelog
  bash ${_} $(git tag -l --sort=authordate | sed 's/[a-z/]//g' | uniq | tail -n1)
  sudo mk-build-deps -ir -t "apt -o Debug::pkgProblemResolver=yes -y --no-install-recommends"
  sudo debuild -b -uc -us
  sudo apt install -f -y ../*.deb

  sudo apt remove -y gbinder-python-build-deps libgbinder-dev \
  git-buildpackage git-lfs fakeroot equivs devscripts cdbs
  echo "You can remove git and build-essential packages too, by run:"
  echo -e "\t\`sudo apt remove git build-essential\`"
  sudo apt autoremove

  sudo apt install -y waydroid
else
  echo "Your distro ${distro} is not use dpkg as package manager"
fi
