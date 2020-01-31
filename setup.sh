#!/bin/bash

#####
##### SYSTEM SOFTWARE INSTALLATION
#####

# if these are already set by our parent, use that.. otherwise sensible defaults
export WARVOX_DIR=/opt/warvox
export RUBY_VERSION="${RUBY_VERSION:=2.2.5}"
export DEBIAN_FRONTEND=noninteractive

# set locales
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen en_US.UTF-8

echo "[+] Creating clean database"
service postgresql start
sudo -u postgres createuser -s warvox
sudo -u postgres createdb warvox -O warvox

##### Install rbenv
if [ ! -d ~/.rbenv ]; then
  echo "[+] Installing & Configuring rbenv"
  
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile > /dev/null

  # manually load it up...
  eval "$(rbenv init -)"
  export PATH="$HOME/.rbenv/bin:$PATH"
  
  # ruby-build
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  # rbenv gemset
  git clone git://github.com/jf/rbenv-gemset.git ~/.rbenv/plugins/rbenv-gemset
else
  echo "[+] rbenv installed, upgrading..."
  # upgrade rbenv
  cd ~/.rbenv && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/ruby-build && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/rbenv-gemset && git pull
fi

# setup ruby
if [ ! -e ~/.rbenv/versions/$RUBY_VERSION ]; then
  echo "[+] Installing Ruby $RUBY_VERSION"
  rbenv install $RUBY_VERSION
  export PATH="$HOME/.rbenv/versions/$RUBY_VERSION:$PATH"
else
  echo "[+] Using Ruby $RUBY_VERSION"
fi

source ~/.bash_profile > /dev/null
rbenv global $RUBY_VERSION
echo "Ruby version: `ruby -v`"

# Install bundler
echo "[+] Installing Latest Bundler"
gem install bundler:2.0.2 --no-document
rbenv rehash

#####
##### WARVOX SETUP / CONFIGURATION
#####
echo "[+] Installing Gem Dependencies"
cd $WARVOX_DIR
bundle update --bundler
bundle install

#echo "[+] Running DB Migrations"
#bundle exec rake db:migrate

# check install 
bundle exec $WARVOX_DIR/bin/verify_install.rb

echo "[+] Creating default config"
cp $WARVOX_DIR/config/database.yml.example $WARVOX_DIR/config/database.yml
cp $WARVOX_DIR/config/secrets.yml.example $WARVOX_DIR/config/secrets.yml

echo "[+] Creating session secret"
bundle exec rake secret > $WARVOX_DIR/config/session.key

make database

# if we're configuring as root, we're probably going to run as root, so
#   manually force the .bash_profile to be run every login
if [ $(id -u) = 0 ]; then
   echo "source ~/.bash_profile" >> ~/.bashrc
fi

# Cleaning up
echo "[+] Cleaning up!"
sudo apt-get -y clean