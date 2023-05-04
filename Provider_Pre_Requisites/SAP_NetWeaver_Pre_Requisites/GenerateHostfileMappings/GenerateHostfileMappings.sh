# <copyright file="GenerateHostfileMappings.sh" company="Microsoft Corporation">
# Copyright (c) Microsoft Corporation. All rights reserved.
# </copyright>

#!/bin/bash

# Replace instance number with the instance number of the Central Server instance
instanceNumber=00

# Set the path to the SAP hostctrl executable
cd "/usr/sap/hostctrl/exe"

hosts=""
fqdn=""

function get_hosts() {
    # Get the hostnames of the SAP system instance
    hosts=$(./sapcontrol -prot PIPE -nr $instanceNumber -format script -function GetSystemInstanceList | grep "hostname" | cut -d " " -f 3)
}

function get_fqdn() {
    # Get the fully qualified domain name
    fqdn=$(./sapcontrol -prot PIPE -nr $instanceNumber -format script -function ParameterValue | grep "SAPFQDN" | cut -d "=" -f 2 | tr -d '\r')
}

{
    get_hosts
    get_fqdn
} || {
    echo "Failed to get the hostnames and fully qualified domain name. Please check if the instance number on line 8 is correct."
}

if [ -z "$hosts" ]; then
    echo "Failed to get the hostnames. Please check if the instance number on line 8 is correct."
    exit 1
fi

if [ -z "$fqdn" ]; then
    echo "Failed to get the fully qualified domain name. Please check if the instance number on line 8 is correct."
    exit 1
fi

# Declare an array to store the host file entries
hostfile_entries=()

# Loop through each hostname
for hostname in $hosts
do
    # Get the IP address of the hostname
    ip=""
    { 
        ip=$(ping -c 1 $hostname | head -n 1 | cut -d "(" -f 2 | cut -d ")" -f 1)
    } || {
        echo "Failed to get the IP address of $hostname ${?}"
        exit 1
    }
    hostfile_entries+="$ip $hostname.$fqdn $hostname,"
done

# Print the host file entries separated by commas
hostfile_entries=${hostfile_entries%?}
IFS=","
echo "${hostfile_entries[*]}"