# On-Premises to Cloud Data Migration — Two-VPC Architecture

## Project Overview

This project documents a series of build attempts to implement a continuous
database migration from a simulated on-premises PostgreSQL database to Google
Cloud SQL PostgreSQL 15 using a two-VPC architecture connected via VPN.

The project did not produce a working CDC migration — not due to implementation
error, but because of a fundamental GCP architectural constraint that was
discovered and proven through exhaustive testing across five build attempts and
three distinct networking approaches. The analysis and findings are the primary
portfolio artefact of this project.

The working CDC migration is documented in the companion project:
[02-onprem-to-cloud-data-migration-single-vpc](../02-onprem-to-cloud-data-migration-single-vpc)

---

## Intended Architecture

The design intent was to simulate a realistic on-premises to cloud migration
topology where the source database and cloud destination are in separate,
isolated networks connected via VPN — analogous to a real enterprise migration
where on-premises infrastructure connects to GCP via Dedicated Interconnect or
Cloud VPN.

```
┌─────────────────────────────────────────────────────────────────────┐
│  GCP Project: sekinat-migration-two-vpcs                            │
│                                                                     │
│  ┌──────────────────────┐          ┌──────────────────────────────┐ │
│  │  source-vpc          │          │  target-vpc                  │ │
│  │  10.0.1.0/24         │          │  10.0.2.0/24                 │ │
│  │                      │   VPN    │                              │ │
│  │  ┌────────────────┐  │◄────────►│  ┌──────────────────────┐   │ │
│  │  │ PostgreSQL VM  │  │  Tunnel  │  │ Cloud SQL PG15        │   │ │
│  │  │ 10.0.1.2       │  │          │  │ 10.252.0.3 (PSA)     │   │ │
│  │  │ (simulates     │  │          │  └──────────────────────┘   │ │
│  │  │  on-premises)  │  │          │                              │ │
│  │  └────────────────┘  │          │  Private Service Access      │ │
│  │                      │          │  10.252.0.0/16               │ │
│  │  Private Service     │          └──────────────────────────────┘ │
│  │  Access              │                                           │
│  │  10.128.0.0/16       │          ┌──────────────────────────────┐ │
│  │  (DMS connects       │          │  DMS (managed service)       │ │
│  │   FROM here)         │          │  connects via PSA peering    │ │
│  └──────────────────────┘          └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Where the Architecture Broke

### The Intended Migration Path

```
DMS managed network
    ↓ Private Service Access peering → source-vpc
    ↓ Reads from PostgreSQL VM (10.0.1.2)
    ↓ VPN tunnel → target-vpc
    ↓ Writes to Cloud SQL (10.252.0.3)
```

### The Actual GCP Constraint

GCP VPC peering — including Private Service Access — is **non-transitive**.
Traffic entering a VPC via peering cannot exit via a VPN tunnel into another VPC.

```
DMS managed network
    ↓ Private Service Access peering → source-vpc  ✅
    ↓ VPN tunnel → target-vpc                      ❌ BLOCKED
```

DMS connects from its own managed network via Private Service Access peering
into one VPC. From that VPC it cannot traverse the VPN tunnel to reach a second
VPC. This is a deliberate GCP design decision — not a configuration issue.

---

## Networking Evolution Across Builds

### Builds 1-4 — Classic VPN + Static Routes + DMS

**Configuration:**
- Classic VPN gateways with forwarding rules
- Static routes between VPCs
- DMS private connection peering into source-vpc

**Failures encountered:**
- DMS private connection placed in wrong VPC (target-vpc) — builds 1-2
- pglogical extension not installed — builds 1-3
- Source connection profile defaulting to DESTINATION role
- DMS connecting from Private Service Access range (`10.128.0.0/16`) not
  from DMS private connection subnet (`10.0.3.0/29`) as documented by GCP
- Despite all configuration fixes — DMS traffic never reached source VM

### Build 5 — HA VPN + BGP + Cloud Router

**Hypothesis:** Replacing Classic VPN static routes with HA VPN + BGP might
allow BGP-learned routes to propagate through the `servicenetworking` peering
into Google's managed service network — enabling Cloud SQL and DMS to reach
the source VM.

**Configuration:**
- HA VPN gateways (two tunnels per gateway pair)
- Cloud Routers with BGP (ASN 64512 / 64513)
- BGP sessions established and routes learned
- Custom route export enabled on `servicenetworking-googleapis-com` peering

**BGP session verification:**
```
source-peer-0: Established, UP, learned 1 route ✅
source-peer-1: Established, UP, learned 1 route ✅
target-peer-0: Established, UP, learned 1 route ✅
target-peer-1: Established, UP, learned 1 route ✅
```

**BGP routes in target-vpc:**
```
Dest: 10.0.1.0/24, NextHop: 169.254.0.1, Type: BGP ✅
Dest: 10.0.1.0/24, NextHop: 169.254.1.1, Type: BGP ✅
```

**Result:** Despite BGP routes being present in `target-vpc` routing table —
Cloud SQL and DMS could not reach `10.0.1.2`. Connection timed out in both cases.

**Root cause:** GCP's `servicenetworking-googleapis-com` peering only propagates
**subnet routes** into the managed service network. BGP-learned routes are
classified as **custom routes** and are not propagated — even with
`exportCustomRoutes: true` explicitly set on the peering.

---

## The Definitive Constraint

```
Route type          Propagated through servicenetworking peering?
─────────────────────────────────────────────────────────────────
Subnet routes       ✅ Yes — automatically
Static routes       ❌ No — classified as custom routes
BGP-learned routes  ❌ No — classified as custom routes
```

GCP managed services (Cloud SQL, DMS) only see subnet routes from your VPC.
Custom routes — regardless of origin — do not reach the managed service network.

---

## Why This Does Not Affect Real Production

In real production on-premises to cloud migrations via Dedicated Interconnect
or HA VPN:

```
On-premises network (e.g. 192.168.0.0/16)
    ↓ Dedicated Interconnect / HA VPN (BGP routing)
Single GCP VPC
    ├── Cloud Router learns on-prem routes via BGP
    ├── Routes installed in VPC routing table
    └── Cloud SQL / DMS via Private Service Access
            → sees VPC subnet routes → reaches on-prem via Interconnect ✅
```

**The key difference:** In real production there is only **one GCP VPC**.
The on-premises network connects to that single VPC via Interconnect — not
via a second VPC. DMS and Cloud SQL peer into that single VPC and can reach
the on-premises source database via the Interconnect path.

The two-VPC simulation introduced a GCP-specific constraint (non-transitive
VPC peering) that has no equivalent in real production topology.

**Important distinction on BGP and Custom Routes:**
HA VPN + BGP with custom route export is the backbone of on-premises to cloud
connectivity via Interconnect. It works in real production because on-premises
systems initiate connections **into** GCP — traffic flows inbound through the
Interconnect following subnet routes to reach managed services. The constraint
only applies to managed service-initiated **outbound** connections attempting
to traverse custom routes through the servicenetworking peering boundary.

---

## Approaches Tested and Results

| Approach | Private | Result | Reason |
|---|---|---|---|
| Classic VPN + DMS private connection | ✅ | ❌ | Non-transitive peering |
| Classic VPN + pglogical subscriber | ✅ | ❌ | Custom routes blocked at servicenetworking |
| HA VPN + BGP + DMS | ✅ | ❌ | BGP routes classified as custom routes |
| HA VPN + BGP + pglogical | ✅ | ❌ | BGP routes classified as custom routes |
| Single VPC + DMS | ✅ | ✅ | No peering boundary — direct subnet routing |

---

## What Would Work in a Two-VPC Topology

For completeness — approaches that could achieve CDC in a two-VPC GCP simulation:

| Approach | Notes |
|---|---|
| Shared VPC (Host/Service project) | Requires organisation-level setup |
| GCP Datastream | Different connectivity model — not subject to same peering constraints |
| Self-managed Debezium on source-vpc VM | Application-level CDC — no managed service peering involved |
| Move Cloud SQL to source-vpc | Functionally equivalent to single VPC |

---

## Infrastructure as Code

All infrastructure was provisioned using Terraform. The final state reflects
the HA VPN + BGP architecture:

| File | Purpose |
|---|---|
| `main.tf` | APIs, backend, providers |
| `networking.tf` | Two VPCs, subnets, firewall rules, Private Service Access (both VPCs) |
| `vpn.tf` | HA VPN gateways, Cloud Routers, BGP peers, VPN tunnels |
| `compute.tf` | PostgreSQL VM with pglogical pre-installed |
| `iam.tf` | Service accounts, IAM bindings |
| `secrets.tf` | Secret Manager for database password |
| `dms.tf` | DMS connection profiles |
| `variables.tf` | Input variables |
| `outputs.tf` | Key resource outputs |
| `scripts/startup.sh` | PostgreSQL + pglogical installation and configuration |

---

## Network Design

| Component | CIDR | VPC | Purpose |
|---|---|---|---|
| `source-subnet` | `10.0.1.0/24` | source-vpc | PostgreSQL VM |
| `target-subnet` | `10.0.2.0/24` | target-vpc | Unused — Cloud SQL uses PSA |
| Private Service Access (source) | `10.128.0.0/16` | source-vpc | DMS connects FROM here |
| Private Service Access (target) | `10.252.0.0/16` | target-vpc | Cloud SQL private IP |
| DMS private connection | `10.0.3.0/29` | source-vpc | DMS peering endpoint |
| HA VPN BGP link 0 | `169.254.0.0/30` | Both | BGP session |
| HA VPN BGP link 1 | `169.254.1.0/30` | Both | BGP session (redundant) |

---

## Key Discoveries

| # | Discovery |
|---|---|
| 1 | DMS connects FROM Private Service Access range — not from DMS private connection subnet |
| 2 | DMS private connection subnet (`10.0.3.0/29`) is never actually used by DMS |
| 3 | VPC peering including Private Service Access is non-transitive |
| 4 | Classic VPN with BGP is not supported between two GCP Classic VPN gateways |
| 5 | HA VPN + BGP establishes sessions correctly but BGP routes are custom routes |
| 6 | `servicenetworking` peering only propagates subnet routes into managed service network |
| 7 | `exportCustomRoutes: true` on servicenetworking peering has no effect for managed services |
| 8 | pglogical is required for DMS CDC — not prominently documented by GCP |
| 9 | DMS source connection profile defaults to DESTINATION role without `--role=SOURCE` |
| 10 | Deleting a migration job also deletes the destination connection profile |

---

## Equivalent Services on AWS and Azure

| GCP | AWS | Azure |
|---|---|---|
| Database Migration Service | AWS Database Migration Service | Azure Database Migration Service |
| Cloud SQL PostgreSQL | Amazon RDS PostgreSQL | Azure Database for PostgreSQL |
| HA VPN + Cloud Router | AWS Transit Gateway + VPN | Azure VPN Gateway + Route Server |
| Private Service Access | AWS PrivateLink | Azure Private Link |
| VPC Peering | VPC Peering | VNet Peering |
| BGP via Cloud Router | BGP via Virtual Private Gateway | BGP via VPN Gateway |

---

## Lessons Learned

The two-VPC architecture is a valid and realistic network design for simulating
on-premises to cloud migration topology. However GCP's managed service
connectivity model — where services connect via Private Service Access peering
rather than via the VPC routing table — means that VPN-traversing routes are
invisible to managed services.

The single VPC build is the architecturally correct simulation because in real
production there is only one GCP VPC. The on-premises network connects to that
VPC via Interconnect and BGP routing — the source database is not behind a
second VPC peering boundary.

This distinction — between BGP routing (transitive, used by Interconnect) and
VPC peering (non-transitive, used by managed services) — is a fundamental GCP
networking concept that has significant implications for migration architecture.

---

## Related Projects

- [03-onprem-to-cloud-data-migration-single-vpc](../03-onprem-to-cloud-data-migration-single-vpc) —
  Single VPC architecture. Successful CDC migration using DMS. The correct
  simulation of real production Dedicated Interconnect topology.
