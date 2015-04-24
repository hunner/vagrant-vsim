#!/usr/bin/env bash
. /vagrant/vsim.conf
sudo wget http://apt.puppetlabs.com/puppetlabs-release-trusty.deb -O /tmp/puppetlabs-release-trusty.deb
sudo dpkg -i /tmp/puppetlabs-release-trusty.deb
sudo apt-get -y update
sudo apt-get -y install dnsmasq sshpass git puppet puppetmaster
BASEIP=`echo $NODE_MGMT_IP | cut -d"." -f1-3`
sudo sh -c "cat <<EOF >> /etc/dnsmasq.conf
dhcp-range=$BASEIP.60,$BASEIP.62,12h
dhcp-host=08:00:DE:AD:AC:1D,vsim,$NODE_MGMT_IP,infinite
log-dhcp
EOF"
sudo /etc/init.d/dnsmasq restart

sudo iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 22222 -j REDIRECT --to-port 22

echo "Preparing Chef"
sudo su $OS_USER -c "cp -R /vagrant/chef /home/vagrant/"
sudo su $OS_USER -c "cd /home/vagrant/chef/cookbooks && git clone https://github.com/chef-partners/netapp-cookbook.git netapp"

sudo su $OS_USER -c "cd && git clone https://github.com/antani/nmsdk_ruby.git"

sudo su $OS_USER -c "cp -R /home/vagrant/nmsdk_ruby/lib/rb/* /home/vagrant/chef/cookbooks/netapp/libraries"
chown $OS_USER:$OS_USER /home/vagrant/chef/cookbooks/netapp/libraries/*

echo "Preparing Puppet"
[ -f "/vagrant/puppetlabs-netapp" ] && sudo ln -s /vagrant/puppetlabs-netapp /etc/puppet/modules/netapp
[ -f "/vagrant/device.conf" ] && sudo ln -s /vagrant/device.conf /etc/puppet/device.conf
sudo echo '127.0.1.1 puppet' >> /etc/hosts

