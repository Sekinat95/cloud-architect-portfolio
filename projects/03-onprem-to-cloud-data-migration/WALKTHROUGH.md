# WALKTHROUGH (TWO VPCs)

1. Architecture Decision
   - What's being simulated (on-prem → cloud DB migration)
   - Why this topology (single VPC vs two VPC — and why two-VPC failed)
   

2. IaC Skeleton (Terraform)
   - Provider/backend setup, API enablement (GCP cloud resource manager API enablement manually,
   IAM, compute, secret manager etc in IaC docs )
   - What's declared here vs what's manual (and why — e.g. Cloud Build trigger)
   - File-by-file purpose (networking.tf, vpn.tf, dms.tf, secrets.tf...)

3. Provisioning
   - terraform plan apply, wait time of 2 mins for service APIs to be enabled
   - What gets created — VPCs, subnets, VM, Cloud SQL instance shell

4. Database Setup (source + destination)
   - On-prem DB (simulated on VM): install (start up using secret manager secret),
    schema, seed data
   - Cloud SQL destination: Postgresql15
   - Both the VM and cloudSQL instances are provisioned with terraform. Cloudsql in GCP is prefered to be created in the same VPC as DB Migration Servicz (DMS)

5. Secrets & VM Bootstrap
   - Secret Manager: stores the DB passwords for the postgresql instance in the VM
   - Retreival flow during start up of the DB password

6. pglogical Setup
   - Extension install, publication/subscription creation
   - Source vs destination side steps — which commands run where
   - What CDC actually replicates and how you verified it was flowing

7. DMS Setup
   - Connection profiles (source, destination)
   - Migration job creation, what DMS manages vs what you pre-built
   - Lifecycle: what persists vs what gets torn down when the job is deleted
     (this is the part worth being very explicit about — it's the part people forget)

8. Network Path (VPN / IP connectivity)
   - Simple diagram-in-words: single VPC: source subnet -> destination subnet
   - IP ranges involved, what's routable vs not
   - This is also where the two-VPC failure mode lives conceptually —
     even if that's a separate WALKTHROUGH_V2, worth a pointer here

9. Validation
   - Schema checks and comparisons of the two DBs were conducted to validate that the data was migrated successfully

10. Teardown
   - terraform destroy
   - DMS migration deletion along with its dependencies (source and destination connections)
   - remove GCS for terraform states