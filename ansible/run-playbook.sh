#!/bin/bash

ansible-playbook --user ec2-user --private-key ~/.ssh/aws --inventory hosts playbook.yml
