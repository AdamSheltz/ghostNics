#!/bin/bash
# Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
# THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
# We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the 
# object code form of the Sample Code, provided that. You agree: (i) to not use Our name, logo, or trademarks to market Your 
# software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in 
# which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against
# any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code


set -x
# List of Azure subscription IDs
SUBSCRIPTION_IDS=()

# Login to Azure CLI
#az login

# Iterate over each subscription
for SUBSCRIPTION_ID in "${SUBSCRIPTION_IDS[@]}"; do
    echo "Processing subscription: $SUBSCRIPTION_ID"
    # Set the subscription context
    az account set --subscription "$SUBSCRIPTION_ID"

    # Find AKS managed clusters in the subscription
    aksClusters=$(az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o json)

    # Iterate over each AKS cluster to find VMSS and associated NICs
    for cluster in $(echo "${aksClusters}" | jq -c '.[]'); do
        clusterName=$(echo "$cluster" | jq -r '.name')
        resourceGroup=$(echo "$cluster" | jq -r '.resourceGroup')
        nodeResourceGroup=$(az aks show --name $clusterName --resource-group $resourceGroup --query nodeResourceGroup -o tsv)

        echo "Processing AKS Cluster: $clusterName in Resource Group: $resourceGroup"

        # Check for VMSS in the AKS cluster's resource group
        vmssInstances=$(az vmss list --resource-group "$nodeResourceGroup" --query "[].{id:id,name:name}" -o json)
        if [[ "$(echo "$vmssInstances" | jq length)" -eq 0 ]]; then
            echo "No VMSS found in AKS cluster resource group."
            continue
        fi

        # List all NICs in the subscription/resource group
        nics=$(az network nic list --query "[].{id:id,name:name}" --subscription "$SUBSCRIPTION_ID" ${RESOURCE_GROUP:+--resource-group "$RESOURCE_GROUP"} -o json)

        # List all VMSS in the subscription/resource group
        vmssInstances=$(az vmss list --query "[].{id:id,name:name}" --subscription "$SUBSCRIPTION_ID" ${RESOURCE_GROUP:+--resource-group "$RESOURCE_GROUP"} -o json)

        # Create an associative array to map NIC IDs to VMSS names
        declare -A nicToVmssMap

        # Populate the map with NIC IDs and corresponding VMSS names
        for vmss in $(echo "${vmssInstances}" | jq -c '.[]'); do
            vmssName=$(echo "$vmss" | jq -r '.name')
            resourceGroup=$(echo "$vmss" | jq -r '.id' | cut -d '/' -f5)
            nicsInVmss=$(az vmss nic list --vmss-name "$vmssName" --resource-group "$resourceGroup" --query "[].id" -o json)
            for nicId in $(echo "${nicsInVmss}" | jq -r '.[]'); do
                nicToVmssMap["$nicId"]="$vmssName"
            done
        done

        # Display associated NICs and their VMSS
        echo "Associated NICs and VMSS:"
        for nic in $(echo "${nics}" | jq -c '.[]'); do
            nicId=$(echo "$nic" | jq -r '.id')
            nicName=$(echo "$nic" | jq -r '.name')
            if [[ -n "${nicToVmssMap[$nicId]}" ]]; then
            # echo "NIC Name: $nicName, NIC ID: $nicId, Associated VMSS: ${nicToVmssMap[$nicId]}"
            fi
        done

        # Display unassociated NICs
        echo "Cluster Name: $cluster"
        echo "Unassociated NICs:"
        for nic in $(echo "${nics}" | jq -c '.[]'); do
            nicId=$(echo "$nic" | jq -r '.id')
            if [[ -z "${nicToVmssMap[$nicId]}" ]]; then
                echo "NIC ID: $nicId"
            fi
        done

            done
        done

        echo "Report generation complete."
