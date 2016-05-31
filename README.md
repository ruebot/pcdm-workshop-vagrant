## PCDM Workshop Vagrant

This Vagrant VM is provided to help PCDM workshop attendees at [OR 2016](http://or2016.net/)
quickly setup a Fedora environment with related services, such as Camel, Hydra and Islandora.

## Requirements

* [Vagrant](https://www.vagrantup.com/)
* [VirtualBox](https://www.virtualbox.org/)

## Setup

1. Clone this repository with `git clone https://github.com/ruebot/pcdm-workshop-vagrant.git` or [download a ZIP file from Github](https://github.com/ruebot/pcdm-workshop-vagrant/archive/master.zip).
2. `cd pcdm-workshop-vagrant`
3. `vagrant up`

You can shell into the machine with `vagrant ssh` or `ssh -p 2222 vagrant@localhost`

## Services Provided

* Tomcat running on port 8080 with:
   * Fedora 4.5.1: [http://localhost:8080/fcrepo/](http://localhost:8080/fcrepo/)
   * Solr 4.10: [http://localhost:8080/solr/](http://localhost:8080/solr/)
* A stock [Curation Concerns](https://github.com/projecthydra-labs/curation_concerns) app is built in the Vagrant in `/home/vagrant/ccdemo`
   * Once connected to the Vagrant VM, start with: `cd ccdemo; rake ccdemo`
   * Access the app at [http://localhost:3000](http://localhost:3000) and its embedded Solr 6 index at [http://localhost:8983/solr/](http://localhost:8983/solr/).
   * To setup an initial user account:
      * Click "Log In" in the upper right, and then "Sign up" in the login form.
      * Enter your username and password, and click "Sign up" to create your account and sign in.
   * Once signed in, you can create content by clicking the "+" button in the upper right.
* Karaf on port 8181
* Islandora Microservices on port 8282
* MySQL database on port 3306
* PostgreSQL database on port 5432
