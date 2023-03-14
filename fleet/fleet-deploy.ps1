# Deploy two different fleets, each fleet will run on different versions of AKS
# however, the version will be standardized.  Example is that one cycle green fleet might rung 
# AKS v.N and the blue fleet might run AKS v.N+1.  This will allow us to test the upgrade process
# of AKS and the impact on the fleet.
# In a sense we're fully treating the fleets as cattle. Once the last member in the fleet has been upgraded
# we sunset the fleet and create a new one, which will be version v.N+1
# For testing this entire script is one batch. Ideally this would be GitOps based and you have a single process
# to create a fleet. In a seperate data store we can have our "cluster" inventory that we read and recreate 
# under the next version of AKS.
# Each fleet will be in it's own RG to further isolate them. This will permit us simply delete the RG to
# get rid of the old fleet.

$subscription = az account show --query id
$location = "eastus2"

$rg = "fleet-tests-rg"

# AKS v.N
$fleet = "green-fleet" 

# version to be given to clusters in fleet
$fleet_version = "1.24.9"


# create a resource group
az group create --name $rg --location $location

# create green fleet
az fleet create --name $fleet --resource-group $rg --location $location


# create sample vnets and subnets for cluster testing
# we'll create 3 clusters; as per tutorial we'll creat 2 VNETs
# and 3 subnets. This is to demonstrate that clusters can be
# in different VNETs
$vnet_one = "fleet-first-vnet"
$vnet_two = "fleet-second-vnet"

$member_1_subnet = "member-1-snet"
$member_2_subnet = "member-2-snet"
$member_3_subnet = "member-3-snet"

# create VNETS and Subnets

az network vnet create `
    --name $vnet_one `
    --resource-group $rg `
    --location $location `
    --address-prefixes "10.0.0.0/8"

az network vnet create `
    --name $vnet_two `
    --resource-group $rg `
    --location $location `
    --address-prefixes "10.0.0.0/8"

az network vnet subnet create `
    --vnet-name $vnet_one `
    --name $member_1_subnet `
    --resource-group $rg `
    --address-prefixes "10.1.0.0/16"

az network vnet subnet create `
    --vnet-name $vnet_one `
    --name $member_2_subnet `
    --resource-group $rg `
    --address-prefixes "10.2.0.0/16"

az network vnet subnet create `
    --vnet-name $vnet_two `
    --name $member_3_subnet `
    --resource-group $rg `
    --address-prefixes "10.1.0.0/16"

# create AKS clusters

$aks_cluster_1 = "aks-member-1"
$aks_cluster_2 = "aks-member-2"
$aks_cluster_3 = "aks-member-3"

az aks create `
    --resource-group $rg `
    --location $location `
    --name $aks_cluster_1 `
    --node-count 1 `
    --network-plugin azure `
    --vnet-subnet-id "/subscriptions/$subscription/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnet_one/subnets/$member_1_subnet"