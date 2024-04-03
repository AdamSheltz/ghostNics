# ghostNics
Attempting to detect GhostNics in AKS clusters.

If an AKS cluster has a limited IP range because of the number of reserved IP addresses a single node can require, a leftover nic that didn't get properly cleaned up can cause problems for Scaling / upgrades. 
This is an attempt to find ghost nics that are assosciated within AKS clusters. 

IF the cluster or a nodepool was created after late 2023 (October-December)*, there are better methods within Azure to identify and remove ghost nics. 


*Need to verify date 2024.04.03
