# ADR-006: BGP + HA-VPN vs Peering based options

## Status

## Date
2026-05-02

## Context
This iteration of the data migration POC between on-prem and cloud uses two VPCs provisioned to simulate each respective network. 
As will later be discussed, this simulation design ultimately fails due to the underlying GCP rules governing the behavior between two VPCs.
As such, the initial single VPC design was the most achievable way to simulate on-prem to cloud data migration in GCP.


## Decision
We used HA VPN between the two VPCs along with boder gate protocol (BGP) to broadcast the IPs of each VPC to the other so that they can be learned.
We decided on this because peering is non-transitive. Even though, each VPC has access to GCP managed tools using private service connect, connecting to each other 
via the VPN tunnel breaks. 
We eventually learned that the mechanism used for Interconnect and HA VPN between onprem and cloud in production is solely designed to be used between an external network (onprem)
and google cloud. Any attempt to use it (as we have done in our simulation) between two VPCs will not be allowed.

DMS managed network
    ↕ Private Service Access peering (Boundary 1)
source-vpc OR target-vpc
    ↕ VPN tunnel OR direct peering (Boundary 2)
The other VPC

The main constraint is that DMS (and other GCP services) lives outside of both VPCs so private service connect (which uses peering underneath ) isused 
to connect each GCP managed service to each VPC. this peering link will however not tranfer beyond boundary 1 (as above i.e. between the managed service and the VPC).
What we later also learned is that although BGP is used to broadcast learned IP addresses between networks without needed direct connection such as peering, that 
mechanism is not allowed between two VPCs either.

## References 

- [Classic VPN BGP between two GCP VPCs — not allowed](https://cloud.google.com/network-connectivity/docs/vpn/deprecations/classic-vpn-deprecation)
- [BGP on Classic VPN only for on-prem/VM gateways](https://cloud.google.com/network-connectivity/docs/vpn/concepts/choosing-networks-routing)
- [VPC peering non-transitive](https://cloud.google.com/vpc/docs/vpc-peering)
- [Custom route exchange via peering](https://cloud.google.com/vpc/docs/using-vpc-peering)