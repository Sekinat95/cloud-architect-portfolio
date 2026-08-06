# On-Premises to Cloud Data Migration — Single VPC Walkthrough

Single end-to-end reference for the successful build. No VPN — single VPC
architecture, DMS reaches the source VM directly via Private Service Access.

---

## Phase 0 — Setup

### Step 1 — Environment Variables

export PROJECT_ID=$(gcloud config get-value project)
export REGION=europe-west2
export ZONE=europe-west2-a
export BUCKET_NAME=$PROJECT_ID-terraform-state
# persist to ~/.bashrc, source it

### Step 2 — Authenticate

gcloud auth application-default login
gcloud config set project $PROJECT_ID

### Step 3 — Terraform State Bucket

gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
gsutil versioning set on gs://$BUCKET_NAME

---

## Phase 1 — Architecture Decision

Single VPC, no VPN. On-prem simulated as a VM inside main-vpc's source-subnet.
Cloud SQL and DMS both reach that VM via Private Service Access — no peering
boundary to cross, unlike the two-VPC attempts (documented separately as a
failure case: non-transitive peering blocks both static and BGP routes).

Architecture:

DMS managed network
    ↓ connects FROM Private Service Access range (e.g. 10.80.0.0/16)
main-vpc
    ├── source-subnet (10.0.1.0/24) — PostgreSQL VM (10.0.1.2)
    ├── target-subnet (10.0.2.0/24) — defined, unused in practice
    └── Private Service Access (10.80.0.0/16) — Cloud SQL (10.80.0.3)

---

## Phase 2 — Terraform: Infrastructure

### Step 4 — main.tf
- Provider + GCS backend (bucket name hardcoded)
- API enablement: compute, servicenetworking, sqladmin, datamigration,
  secretmanager, cloudresourcemanager, iam
- `time_sleep` 120s after API enablement

### Step 5 — networking.tf
- main-vpc, source-subnet (10.0.1.0/24), target-subnet (10.0.2.0/24, unused)
- Firewall rules — Private Service Access CIDR added post-apply (unknown before)
- Private Service Access peering (`servicenetworking-googleapis-com`)

### Step 6 — secrets.tf
- Secret Manager secret + `random_password` for DB password — never a TF variable

### Step 7 — compute.tf + scripts/startup.sh
PostgreSQL VM (`onprem-postgres-vm`, e2-medium, source-subnet)

startup.sh does, in order:
1. Install PostgreSQL
2. Configure `wal_level = logical`, `max_replication_slots`, `max_wal_senders`,
   `listen_addresses = '*'` (mandatory — without it DMS can't connect at all)
3. Install pglogical: `apt-get install -y postgresql-13-pglogical`
4. Add `shared_preload_libraries = 'pglogical'` to postgresql.conf
5. Restart PostgreSQL (mandatory — the setting has no effect until restart)
6. `CREATE EXTENSION pglogical;` in BOTH `postgres` and `retail_db`
   (DMS connects to `postgres` first for verification, then `retail_db`)
7. Grant pglogical schema privileges to `migration_user` explicitly —
   standard DB privileges alone produce `AUTHENTICATION_FAILURE`
8. Create `migration_user` (REPLICATION LOGIN) and `retail_db`

### Step 8 — dms.tf
- Source and destination connection profile *shells* only — DMS migration job
  itself has no stable Terraform resource; created via gcloud post-apply
- `lifecycle { ignore_changes = [...] }` on destination profile

### Step 9 — terraform apply

cd terraform
terraform init
terraform apply

---

## Phase 3 — Data Setup

### Step 10 — Generate source data (run from inside the VM, not Cloud Shell)

gcloud compute ssh onprem-postgres-vm --zone=$ZONE --tunnel-through-iap
# then, on the VM:
python3 generate.py   # customers, products, orders, order_items

---

## Phase 4 — Post-Apply Network Reconciliation

### Step 11 — Retrieve Private Service Access CIDR (dynamic per project)

gcloud compute addresses describe private-service-access \
  --global --project=$PROJECT_ID \
  --format="value(address,prefixLength)"

Add this CIDR to both the firewall rule and `pg_hba.conf` — it wasn't knowable
before apply.

### Step 12 — Verify pglogical

sudo -u postgres psql -c "\dx pglogical"
sudo -u postgres psql -d retail_db -c "\dx pglogical"
# expect version 2.3.3 listed in both

---

## Phase 5 — DMS Setup

### Step 13 — Create source connection profile (explicit SOURCE role)

PASSWORD=$(gcloud secrets versions access latest \
  --secret="postgres-migration-password" --project=$PROJECT_ID)

gcloud database-migration connection-profiles create postgresql \
  source-postgres-profile \
  --region=$REGION \
  --host=10.0.1.2 --port=5432 \
  --username=migration_user --database=retail_db \
  --password=$PASSWORD \
  --role=SOURCE \
  --project=$PROJECT_ID

`--role=SOURCE` is mandatory — default is DESTINATION. Password passed as
`$PASSWORD` env var, not typed/pasted, to avoid special-character corruption.

### Step 14 — Create destination connection profile

gcloud database-migration connection-profiles create cloudsql \
  destination-cloudsql-profile \
  --region=$REGION \
  --display-name=destination-cloudsql-profile \
  --source-id=projects/$PROJECT_ID/locations/$REGION/connectionProfiles/source-postgres-profile \
  --tier=db-custom-2-4096 \
  --database-version=POSTGRES_15 \
  --no-enable-ip-v4 \
  --private-network=projects/$PROJECT_ID/global/networks/main-vpc \
  --project=$PROJECT_ID

`cloudsql` profile type implicitly sets role DESTINATION — no need to specify.

### Step 15 — Verify both profiles READY

gcloud database-migration connection-profiles list \
  --region=$REGION --project=$PROJECT_ID
# both must show STATE: READY

### Step 16 — Create and start migration job

gcloud database-migration migration-jobs create retail-db-migration \
  --region=$REGION --type=CONTINUOUS \
  --source=projects/$PROJECT_ID/locations/$REGION/connectionProfiles/source-postgres-profile \
  --destination=projects/$PROJECT_ID/locations/$REGION/connectionProfiles/destination-cloudsql-profile \
  --project=$PROJECT_ID

gcloud database-migration migration-jobs start retail-db-migration \
  --region=$REGION --project=$PROJECT_ID

### Step 17 — Monitor migration phases

gcloud database-migration migration-jobs describe retail-db-migration \
  --region=$REGION --project=$PROJECT_ID

| State | Phase | Meaning |
|---|---|---|
| STARTING | — | Job initialising |
| RUNNING | FULL_DUMP | Copying all existing data |
| RUNNING | CDC | Continuous replication active |
| COMPLETED | — | Migration promoted successfully |

Confirm DMS is actually connecting via PostgreSQL logs:

gcloud compute ssh onprem-postgres-vm --zone=$ZONE --tunnel-through-iap \
  --command="sudo tail -30 /var/log/postgresql/postgresql-*-main.log"

Expected entries: `aurora_version() does not exist` (expected — DMS checks if
source is AWS Aurora), `adding table ... to replication set`,
`CREATE_REPLICATION_SLOT ... pglogical_output`, `START_REPLICATION SLOT`.

If the job fails: `restart`, never `delete`/`create` — deleting the job also
deletes the destination profile and loses the Cloud SQL instance reference.

gcloud database-migration migration-jobs restart retail-db-migration \
  --region=$REGION --project=$PROJECT_ID

### Step 18 — Promote (once phase shows CDC and you're ready to cut over)

gcloud database-migration migration-jobs promote retail-db-migration \
  --region=$REGION --project=$PROJECT_ID
# monitor until state: COMPLETED

---

## Phase 6 — Post-Migration Reconciliation

DMS migrates table data and schema — but not PostgreSQL users or grants.
`migration_user` does not exist on Cloud SQL until you create it manually.

### Step 19 — Create migration_user on Cloud SQL

gcloud sql users create migration_user \
  --instance=destination-cloudsql-profile \
  --password=$(gcloud secrets versions access latest \
    --secret=postgres-migration-password --project=$PROJECT_ID) \
  --project=$PROJECT_ID

### Step 20 — Grant SELECT on all tables

gcloud sql users set-password postgres \
  --instance=destination-cloudsql-profile \
  --password=YourChosenPassword --project=$PROJECT_ID

PGPASSWORD=YourChosenPassword psql -h 127.0.0.1 -p 5432 -U postgres -d retail_db \
  -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO migration_user;"

---

## Phase 7 — Validation

Cloud Shell can't reach internal VPC IPs directly — needs an IAP tunnel.

### Step 21 — Firewall rule for IAP → PostgreSQL

gcloud compute firewall-rules create allow-iap-postgres \
  --network=main-vpc --allow=tcp:5432 \
  --source-ranges=35.235.240.0/20 \
  --target-tags=postgres-source --project=$PROJECT_ID

### Step 22 — Open IAP tunnel (separate terminal, keep running)

gcloud compute start-iap-tunnel onprem-postgres-vm 5432 \
  --local-host-port=localhost:5433 \
  --zone=$ZONE --project=$PROJECT_ID

### Step 23 — Run validation script

Checks: row count reconciliation, referential integrity, order total
checksum, spot sample comparison — source (via tunnel, localhost:5433) vs
target (via Cloud SQL Auth Proxy, localhost:5432).

Result: all four tables (customers, products, orders, order_items) passed
row-count reconciliation; order total checksum matched exactly.

---

## Teardown

# 1. Delete Cloud SQL instance (DMS-managed, outside Terraform)
gcloud sql instances delete destination-cloudsql-profile --project=$PROJECT_ID

# 2. Delete the manually-created IAP firewall rule
gcloud compute firewall-rules delete allow-iap-postgres --project=$PROJECT_ID

# 3. Remove VPC peering
gcloud compute networks peerings delete servicenetworking-googleapis-com \
  --network=main-vpc --project=$PROJECT_ID

# 4. Terraform destroy
cd terraform
terraform destroy

# 5. Delete state bucket
gsutil rm -r gs://$BUCKET_NAME