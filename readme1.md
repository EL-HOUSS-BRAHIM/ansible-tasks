# Ansible Tasks

This repository contains Ansible playbooks and configurations to deploy and manage virtual machines and applications in the cloud.

## Prerequisites

- Three virtual machines deployed in the cloud.
- Ansible installed on one of the machines (control_plane).

## Files

### Inventory

The `inventory` file lists the hosts managed by Ansible.

### Ansible Configuration

The `ansible.cfg` file contains the Ansible configuration settings.

### Playbooks

#### Docker Installation

The `docker.yml` playbook installs Docker on the specified hosts.

```yaml
---
- hosts: all
  become: true
  tasks:
    - name: Install python3-apt (required for Ansible)
      apt:
        name: python3-apt
        state: present

    - name: Install aptitude
      apt:
        name: aptitude
        state: latest
        update_cache: yes
        force_apt_get: yes

    - name: Install system packages
      apt:
        name: "{{ item }}"
        state: latest
        update_cache: yes
      loop:
        - apt-transport-https
        - ca-certificates
        - curl
        - software-properties-common
        - python3-pip
        - virtualenv
        - python3-setuptools

    - name: Docker GPG apt Key Adding
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Adding Docker Repo
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release | lower }} stable"

    - name: Update apt and install docker-ce
      apt:
        update_cache: yes
        name: docker-ce
        state: latest

    - name: Install Docker Module for Python in virtual environment
      pip:
        name: docker
        virtualenv: /home/ubuntu/ansible-docker-venv
        virtualenv_python: python3

    - name: Pull hello-world image
      docker_image:
        name: hello-world
        source: pull

    - name: Create Hello World container
      docker_container:
        name: hello-world
        image: hello-world
        state: started
```

#### WordPress Deployment

The `wordpress.yml` playbook installs Docker and deploys WordPress in a Docker container.

```yaml
---
- hosts: all
  become: true
  vars_prompt:
    - name: wp_db_name
      prompt: Enter the DB name
    - name: db_user
      prompt: Enter the DB username
    - name: db_password
      prompt: Enter the DB password
      private: yes
  vars:
    db_host: db
    wp_name: wordpress
    docker_network: wordpress_net
    wp_container_port: 80
  tasks:
    - name: Create a network
      docker_network:
        name: "{{ docker_network }}"

    - name: Pull WordPress image
      docker_image:
        name: wordpress
        source: pull

    - name: Pull MySQL image
      docker_image:
        name: mysql:5.7
        source: pull

    - name: Create DB container
      docker_container:
        name: "{{ db_host }}"
        image: mysql:5.7
        state: started
        network_mode: "{{ docker_network }}"
        env:
          MYSQL_USER: "{{ db_user }}"
          MYSQL_PASSWORD: "{{ db_password }}"
          MYSQL_DATABASE: "{{ wp_db_name }}"
          MYSQL_RANDOM_ROOT_PASSWORD: '1'
        volumes:
          - db:/var/lib/mysql:rw
        restart_policy: always

    - name: Create WordPress container
      docker_container:
        name: "{{ wp_name }}"
        image: wordpress:latest
        state: started
        ports:
          - "80:80"
        restart_policy: always
        network_mode: "{{ docker_network }}"
        env:
          WORDPRESS_DB_HOST: "{{ db_host }}:3306"
          WORDPRESS_DB_USER: "{{ db_user }}"
          WORDPRESS_DB_PASSWORD: "{{ db_password }}"
          WORDPRESS_DB_NAME: "{{ wp_db_name }}"
        volumes:
          - wordpress:/var/www/html
```

#### LEMP Stack Deployment

The `lemp_stack.yml` playbook installs Docker and deploys a LEMP stack in Docker containers.

```yaml
---
- name: Deploy LEMP Stack with Docker
  hosts: all
  become: true
  tasks:
    - name: Install Docker dependencies
      apt:
        name: 
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present
        update_cache: yes

    - name: Create Docker network
      docker_network:
        name: lemp_network
        state: present

    - name: Deploy Nginx container
      docker_container:
        name: nginx
        image: nginx:latest
        state: started
        ports:
          - "80:80"
        networks:
          - name: lemp_network

    - name: Deploy MySQL container
      docker_container:
        name: mysql
        image: mysql:5.7
        state: started
        env:
          MYSQL_ROOT_PASSWORD: "{{ mysql_root_password }}"
          MYSQL_DATABASE: "{{ mysql_database }}"
        networks:
          - name: lemp_network

    - name: Deploy PHP-FPM container
      docker_container:
        name: php
        image: php:7.4-fpm
        state: started
        networks:
          - name: lemp_network
```

### Commands

#### Syntax Check

To check the syntax of a playbook:

```sh
ansible-playbook -i inventory --syntax-check docker.yml
```

#### Run Playbook

To run a playbook:

```sh
ansible-playbook -i inventory docker.yml
```

### Dynamic Inventory

The `aws_ec2.yml` file contains the configuration for dynamic inventory using AWS EC2.

```yaml
---
plugin: aws_ec2
aws_access_key: <access_id>
aws_secret_key: <access_key>
keyed_groups:
  - key: tags
    prefix: tag
  - prefix: instance_type
  - key: placement.region
    prefix: aws_region
```

To use the dynamic inventory:

```sh
ansible-inventory -i aws_ec2.yml --list
ansible all -m ping
```

Switching Between Static and Dynamic Inventory
To use static inventory, ensure the inventory file is specified in the `ansible.cfg` file:

```sh
ansible-playbook -i inventory docker.yml
```

To use dynamic inventory, specify the aws_ec2.yml file directly in the command:

```sh
ansible-playbook -i aws_ec2.yml docker.yml
```
## Usage

1. Clone the repository.
2. Update the `inventory` file with your hosts.
3. Run the playbooks using the commands provided.

## License

This project is licensed under the MIT License.
```

ansible-playbook -i inventory --syntax-check docker.yml
ansible-playbook -i inventory --syntax-check wordpress.yml
ansible-playbook -i inventory --syntax-check lemp_stack.yml