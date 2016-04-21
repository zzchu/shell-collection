#!/usr/bash


# $1 = certificate name; $2 = certificate path; $3 = certificate password
function func_update_developer_certificate() {
# remove the old certificate
cert_ids=`security find-certificate -a -Z -c "$1" | grep SHA-1 | awk '{print $3}'`


# install the new certificate
}


function func_update_provisioning_profile() {
# remove the old provision

# install the new provision
}



