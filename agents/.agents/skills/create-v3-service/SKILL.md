---
name: create-v3-service
description: Use when creating a brand new v3 business service - guides through Keystone provisioning, ARCOM approval, starter kit setup, and base Dockerfile configuration
---

<skill_overview>
Guides the complete process of creating a new v3 business service at UWM, from Keystone submission through ARCOM approval to initial project structure verification. This skill covers the organizational and infrastructure steps that must happen before any code is written. It ensures the service is properly registered, approved by the Architecture Committee (ARCOM), and provisioned with the correct infrastructure (Kubernetes namespaces, Vault, DNS, certificates, Harness pipelines) via Keystone's automated Orkes workflows.

**Important context:** As of January 2026, the ARCOM process is integrated into Keystone. You submit through Keystone first, and the ARCOM Jira issue is created automatically. ARCOM approval triggers the full provisioning workflow.
</skill_overview>

<rigidity_level>
LOW FREEDOM - The Keystone/ARCOM organizational process is rigid and must follow the prescribed workflow. Starter kit feature selections adapt to your service's requirements. Project structure follows established cell-biz-* conventions with minor variation.
</rigidity_level>

<quick_reference>

| Step | Tool/System | Key Details |
|------|-------------|-------------|
| **1. Decision** | Team discussion | New service vs. extend existing. ARCOM required for new services. |
| **2. Keystone Submit** | `https://keystone.uwm.com/` | Fill both pages: service info + starter kit features |
| **3. ARCOM Review** | Jira ARCOM project | Auto-created by Keystone. Daily meetings 11AM-noon. |
| **4. ARCOM Approval** | Enterprise Architecture | Approval triggers automated provisioning |
| **5. Verify Provisioning** | Bitbucket, K8s, Vault | Confirm all 11 automated tasks completed |
| **6. Clone & Verify** | Local dev | Verify starter kit, Dockerfile, project structure |
| **7. Initial Config** | appsettings, Program.cs | Environment configs, Vault, GUP auth bootstrap |

**Access required:** `GRP-S-IT-Keystone-Contributor` or `GRP-S-IT Keystone Approver` group membership.

</quick_reference>

<when_to_use>
- Creating a brand new v3 business service (cell-biz-*)
- Need guidance on the Keystone submission process
- Need guidance on ARCOM approval requirements
- Verifying starter kit configuration after Keystone provisioning
- Setting up the initial project structure and configuration

**Do NOT use for:**
- Adding features to existing services (use `implement-feature`)
- Data services (cell-data-* pattern is deprecated, do not create new ones)
- BFF services (cell-bff-* has different patterns)
- UI/frontend services (cell-ui-*)
</when_to_use>

<the_process>

## Step 1: Decide Whether a New Service Is Needed

Before submitting to Keystone, confirm that a new service is the right approach:

**Create a new service when:**
- The capability is a distinct business domain (e.g., loan conditions, broker preferences)
- No existing service owns this domain
- The capability needs independent deployment and scaling
- ARCOM thresholds are met (new technology/pattern, multi-discipline coordination, or 3+ months effort)

**Extend an existing service when:**
- The feature belongs to an existing domain
- An existing cell-biz-* service already handles related functionality
- The work is an enhancement, not a new domain

**ARCOM is required when ANY of these apply:**
- Annual licensing purchases exceeding $50,000
- One-time technology purchases exceeding $100,000
- Effort requiring teams from multiple disciplines to coordinate
- Effort requiring more than 3 months from any single discipline
- Any new technology or pattern never previously implemented at UWM

If extending an existing service, skip this skill and use `design-api` or `implement-feature` instead.

---

## Step 2: Submit Through Keystone

Navigate to `https://keystone.uwm.com/` and click "Create Application".

### Page 1: Service Information

| Field | Guidance |
|-------|----------|
| **Name** | Friendly name (e.g., "Loan Conditions"). Auto-generates repo name: `cell-{name.trim().replace(' ', '-').toLowerCase()}` — e.g., "Loan Conditions" becomes `cell-loan-conditions` |
| **Project Key** | Your team's Bitbucket project key (e.g., EH, BOLT, GGF) |
| **Product(s)** | UWM products your service interacts with (multi-select) |
| **Audience** | Internal (UWM employees) or External (brokers, loan officers). External services use Azure clusters. |
| **Primary Stakeholder** | Person/team responsible for feedback and feature direction |
| **DNS Entry** | Domain name without `.uwm.com` suffix (added automatically). Creates entries for int, stage, and prod environments. |
| **Cluster Location** | Kubernetes clusters per environment. Select Azure clusters for External audience. |
| **Needs Internal Ingress** | Yes if UWM team members need direct access (e.g., for Swagger page). Required for most business services. |
| **Needs Vault** | Yes for business services (secrets management). UI apps never need Vault. |
| **Needs Client ID/Secret** | Yes if service needs SSO configuration. Requires redirect URLs (1-10). |

### Page 2: Starter Kit Configuration

Keystone optionally applies the `lib-csharp-starterkit` (NuGet: `UWMC.Starter.Kit.V3`) template to your new repo.

| Feature | When to Enable |
|---------|---------------|
| **Use Starter Kit** | Recommended for all new services. Can also apply manually after provisioning. |
| **Service Type** | Select "Business Service" (not "Data Service" — data service pattern is deprecated) |
| **Azure SQL Database** | Enable if your service needs Azure SQL. Scaffolds EF Core setup + Terraform modules. |
| **Kerberos** | Enable only if connecting to on-premises databases. Auto-enabled for Data Services. |
| **REST API** | Enable for HTTP API endpoints (most business services). Requires DNS entry. |
| **OAuth** | Enable for OAuth app-to-app communication (OAuth-Agent library). Requires DNS entry. |
| **Orkes** | Enable if service will poll Orkes/Conductor for workflow tasks (worker service pattern). |
| **Feature Flags** | Always enabled for Starter Kit apps. Uses Harness FME. |

**If not using the starter kit through Keystone UI**, apply it manually after provisioning:
```bash
# Install the template
dotnet new -i UWMC.Starter.Kit.V3 \
  --nuget-source https://artifacts.uwm.com/artifactory/api/nuget/v3/nuget-production/index.json

# Generate the project
dotnet new uwmcstarterv3 \
  --appName cell-your-service \
  --TemplateType Rest \
  --MicroserviceType "Business Service" \
  --enableAzureSqlDb true \
  --withRestAuth true \
  --enableFeatureFlags true
```

**Template parameters reference:**

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| `appName` | string | — | Keystone name (e.g., `cell-loan-conditions`) |
| `dbcontext` | text | MyDbContext | Custom DbContext class name |
| `enableFeatureFlags` | bool | false | Harness feature flag integration |
| `enableKerberos` | bool | false | On-prem database Kerberos auth |
| `enableAzureSqlDb` | bool | false | Azure SQL + EF Core + Terraform |
| `withRestAuth` | bool | true | REST auth via GUP/Passport |
| `webApplicationBuilder` | bool | false | Modern minimal API pattern (Program.cs only) |
| `CommunicateWithOtherApps` | bool | false | OAuth app-to-app communication |
| `TemplateType` | choice | None | `None` or `Rest` (REST endpoint infrastructure) |
| `MicroserviceType` | choice | Business Service | `Business Service` or `Data Service` |

---

## Step 3: ARCOM Review

After Keystone submission, the following happens automatically:

1. **Keystone fires `keystone_create_workflow`** which creates an ARCOM Jira issue in the `ARCOM` project (issue type: Proposal)
2. The ARCOM card lands in the **Draft** column
3. Your application status in Keystone shows **pending**

### Prepare for the ARCOM Meeting

Enterprise Architecture will schedule your review at the daily ARCOM meeting (11:00 AM - noon, MS Teams, 15-minute blocks: 10 minutes discussion + 5 minutes feedback).

**Your ARCOM proposal should document:**
- Business justification (why a new service is needed)
- Architecture overview (what the service does, key integrations)
- Data flows (what data enters/exits the service)
- Dependencies (other services, databases, external systems)
- Security considerations (PII/NPI handling, authentication model)
- Expected scale (request volume, data volume)

### ARCOM Feedback Categories (MoSCoW)

| Category | Meaning |
|----------|---------|
| **Must-have** | Architecture will not endorse until resolved. Feedback provider must offer direction. |
| **Should-have** | Strong recommendation for additional considerations |
| **Could-have** | Lower value recommendations |
| **Will-not-have** | Excluded/deferred requirements |

### Meeting Request Types
- POC review, Production Ready review, Re-review, Change review, In-depth review, Ideation consultation

---

## Step 4: After ARCOM Approval

When Enterprise Architecture marks the ARCOM Jira card as **Approved**, Keystone fires the `keystone_create_application_workflow` which orchestrates these automated tasks:

| # | What Gets Provisioned | Workflow |
|---|----------------------|----------|
| 1 | **Bitbucket Repository** with starter kit code | git workflow |
| 2 | **Harness Pipeline** for CI/CD | `git_create_harness_workflow` |
| 3 | **Kubernetes Namespaces** (int, stg, prd) | `kubernetes_namespace_setup_workflow` |
| 4 | **Vault Configuration** (4 service accounts: dev, int, stg, prd) | `keystone_setup_vault_workflow` |
| 5 | **DNS and Certificates** for all environments | `keystone_create_dns_cert_workflow` |
| 6 | **AD Groups** (`GRP-S-{ENV}-{REPO-NAME}`) with service accounts | AD automation |
| 7 | **Redis ACLs** for default caching | `redisdb_acl_automation_workflow` |
| 8 | **ServiceNow CMDB Record** (business application) | `servicenow_create_business_application_workflow` |
| 9 | **PactFlow Pacticipant** for contract testing | `create_pactflow_pacticipants_workflow` |
| 10 | **Client Credentials/SSO** (if selected) | `create_client_credentials_workflow` |
| 11 | **Email Notifications** to requestor, EA group, Hot-N-Ready team | notification workflow |

**Expected timeline:** Automated provisioning completes in ~5 minutes. The Keystone application status transitions from **pending** → **approved** → **completed**.

If ARCOM rejects the proposal, the Keystone request is deleted.

---

## Step 5: Clone and Verify the Generated Project

After provisioning completes, clone the new repository and verify the generated structure:

```bash
git clone https://code.uwm.com/scm/{PROJECT_KEY}/cell-your-service.git
cd cell-your-service
```

### Expected Project Structure (from Starter Kit)

```
cell-your-service/
  Jenkinsfile                        # buildPipeline { majorVersion = 1; portDeploy = true }
  *.sln
  global.json
  Copyright.lic
  .gitignore, .dockerignore, .editorconfig
  dockercompose/
    docker-compose.yml               # Local dev environment
    .env                             # Docker build configuration
  iac/
    values.yaml                      # Helm/K8s base values
    terraform/                       # Azure SQL Terraform (if enableAzureSqlDb)
  src/UWMC.{Namespace}/
    Program.cs                       # Application entry point
    Startup.cs                       # Service registration (if not webApplicationBuilder)
    Dockerfile                       # Multi-stage build with UWM base images
    appsettings.json                 # Base configuration
    appsettings.Development.json     # Local dev settings
    appsettings.Integration.json     # INT environment settings
    appsettings.Staging.json         # STG environment settings
    appsettings.Production.json      # PRD environment settings
    Application/                     # CQRS handlers
    Config/                          # Configuration models (DbConnection, etc.)
    Dto/                             # Request/response DTOs and entity models
    Generated/                       # EF Core scaffolded code (if SQL enabled)
    Infrastructure/                  # Extensions, services, handlers
    Mapping/                         # AutoMapper profiles
    Utilities/                       # Configuration utilities
  test/
    UWMC.{Namespace}.Tests/          # Unit tests (xUnit)
    UWMC.{Namespace}.IntegrationTests/  # Integration tests (TestContainers)
```

### Verify Dockerfile Uses UWM Base Images

Open `src/UWMC.{Namespace}/Dockerfile` and confirm:

```dockerfile
# Build stage - MUST use UWM SDK image
FROM artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:8.0-redhat AS build-kestrel-env
ARG BRANCH_NAME
ARG RUN_SONAR
WORKDIR /app
COPY src src
COPY test test
COPY .git .git
COPY *.sln *.json Copyright.lic ./
RUN /app/dotnet-build-test-analyze-publish.sh "$BRANCH_NAME" "$RUN_SONAR"

# Runtime stage - MUST use UWM runtime image
FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:8.0-redhat
ENV ASPNETCORE_URLS=http://*:5000
EXPOSE 5000
RUN /tmp/hardening.sh
WORKDIR /app
USER uwm
COPY --from=build-kestrel-env /app/publish .
ENTRYPOINT ["dotnet", "UWMC.YourService.dll"]
```

**For .NET 10 projects**, the pattern is slightly different:
- Build alias: `build` (not `build-kestrel-env`)
- Image tags: `10.0-redhat` instead of `8.0-redhat`
- May use `COPY . ./` instead of granular COPY statements

**Required elements (both versions):**
- Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat`
- Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat`
- Security hardening: `RUN /tmp/hardening.sh`
- Non-root user: `USER uwm`
- Port 5000: `ENV ASPNETCORE_URLS=http://*:5000` and `EXPOSE 5000`
- COPY not ADD (per Container Image Hardening Standard)
- No secrets in Dockerfile (use Vault)

---

## Step 6: Naming Conventions

### Repository Naming
Keystone auto-generates the repo name: `cell-{name.trim().replace(' ', '-').toLowerCase()}`

For services that need both HTTP API and Kafka consumer:
- HTTP API: `cell-biz-your-service`
- Kafka consumer: `cell-biz-your-service-consumer`
- **These MUST be separate repositories** (v3 pattern: one container per repo)

### Namespace/Assembly Naming
The starter kit generates namespaces following this pattern:
- Source: `UWMC.Business.{ServiceName}` (e.g., `UWMC.Business.LoanConditions`)
- Unit tests: `UWMC.Business.{ServiceName}.Tests`
- Integration tests: `UWMC.Business.{ServiceName}.IntegrationTests`

### Solution File
`UWMC.Business.{ServiceName}.sln`

---

## Step 7: First-Day Configuration

After verifying the generated project, complete these initial configuration steps:

### 1. Verify GUP Auth Bootstrap (Program.cs)
```csharp
// Ensure Passport is configured (starter kit includes this if REST auth selected)
builder.Services.AddPassport(builder.Configuration);  // AFTER other auth services
// ...
app.UsePassport();  // BEFORE other middleware
app.MapPassportEndpoints();  // If service serves UI
app.MapControllers().RequirePassport();  // Require auth on all controllers
```

### 2. Verify Vault Integration (Program.cs)
```csharp
builder.Configuration.AddVaultSecrets();  // Load secrets from Vault
```

### 3. Configure appsettings for Each Environment
Ensure each environment file has the correct `ApplicationEdgeUrl` for GUP:
```json
// appsettings.Integration.json
{
  "ApplicationEdgeUrl": "https://your-service.int.uwm.com"
}
```

### 4. Set Up Local Development
```bash
cd dockercompose
docker-compose up -d
```

The docker-compose typically includes:
- Backend service on port 5000
- SQL Server (if Azure SQL was selected) on port 1433 (or custom)
- Additional services as needed

</the_process>

<examples>

<example>
<scenario>Team decides to build a new loan condition tracking service</scenario>

<code>
# CORRECT: Follow the full Keystone/ARCOM workflow

1. Verify need: No existing cell-biz-* service handles loan conditions → new service needed
2. Navigate to https://keystone.uwm.com/ → Create Application
3. Fill Page 1:
   - Name: "Loan Conditions" → repo becomes cell-loan-conditions
   - Project Key: EH
   - Audience: Internal
   - DNS Entry: loan-conditions (creates loan-conditions.int.uwm.com, etc.)
   - Needs Internal Ingress: Yes (for Swagger)
   - Needs Vault: Yes
4. Fill Page 2 (Starter Kit):
   - Use Starter Kit: Yes
   - Service Type: Business Service
   - Azure SQL Database: Yes
   - REST API: Yes
   - Feature Flags: (always enabled)
5. Submit → Keystone auto-creates ARCOM Jira issue
6. Attend ARCOM meeting → Present architecture, data flows, justification
7. ARCOM approves → Keystone provisions everything automatically
8. Clone repo, verify structure, begin development
</code>
</example>

<example>
<scenario>Developer tries to skip ARCOM and provision manually</scenario>

<code>
# WRONG: Creating repo manually and skipping ARCOM
git init cell-biz-loan-conditions
dotnet new webapi -n UWMC.Business.LoanConditions
# Missing: K8s namespaces, Vault, DNS, Harness pipeline, CMDB record, PactFlow...
</code>

<why_it_fails>
- No ARCOM approval = service cannot be deployed to production
- No Vault configuration = secrets must be hardcoded (security violation)
- No K8s namespaces = nowhere to deploy
- No Harness pipeline = no CI/CD
- No DNS/certificates = service unreachable
- No CMDB record = service invisible to operations
- No PactFlow = contract testing not set up
- Keystone automates all of this in ~5 minutes after ARCOM approval
</why_it_fails>
</example>

<example>
<scenario>Developer selects "Data Service" type in Keystone</scenario>

<code>
# WRONG: Creating a data service
Keystone Page 2 → Service Type: Data Service
</code>

<why_it_fails>
- The cell-data-* pattern is deprecated
- Business services should own their own data
- Do NOT create new data services
- Select "Business Service" and enable Azure SQL if you need a database
</why_it_fails>
</example>

<example>
<scenario>Service needs both HTTP API and Kafka consumer</scenario>

<code>
# CORRECT: Create two separate Keystone submissions
1. cell-biz-loan-conditions (HTTP API)
   - REST API: Yes
   - Service Type: Business Service

2. cell-biz-loan-conditions-consumer (Kafka consumer)
   - REST API: No
   - Service Type: Business Service
   - Orkes: Yes (if using Conductor for orchestration)

# WRONG: Single repo with both HTTP and Kafka
cell-biz-loan-conditions/
  src/UWMC.Business.LoanConditions/         # HTTP API
  src/UWMC.Business.LoanConditions.Consumer/ # Kafka consumer
  # V3 constraint: one container per repo. This won't deploy correctly.
</code>
</example>

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **NEVER skip ARCOM review** - All new v3 services MUST be submitted through Keystone and approved by ARCOM before provisioning. There is no shortcut.

2. **ALWAYS use Keystone for provisioning** - Manual provisioning is technically possible but you will miss critical infrastructure (Vault, DNS, K8s namespaces, CMDB, PactFlow). Use Keystone.

3. **NEVER use non-UWM base Docker images** - The Dockerfile MUST use `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar` (build) and `uwm-aspnet-runtime` (runtime). Custom images will fail deployment.

4. **NEVER create data services (cell-data-*)** - The data service pattern is deprecated. Business services own their own data. Select "Business Service" in Keystone.

5. **ALWAYS set up Vault integration** - Secrets must never be hardcoded. Use `UWMC.Vault` package and `AddVaultSecrets()`.

6. **NEVER combine HTTP API and Kafka consumer** in one repo - V3 pattern requires separate repos (one container per repo). Create separate Keystone submissions.

7. **ALWAYS include security hardening** in the Dockerfile - `RUN /tmp/hardening.sh` and `USER uwm` are mandatory. Services running as root will be rejected.

8. **ALWAYS use COPY instead of ADD** in Dockerfiles - Per the Container Image Hardening Standard.

9. **NEVER store secrets in Dockerfiles** - Use Vault for all secrets management.

## Common Mistakes

- "I'll just create the Bitbucket repo manually" → You'll miss 10 other provisioned resources. Use Keystone.
- "ARCOM is just a formality, I'll skip it" → Without ARCOM approval, Keystone won't provision your infrastructure. No shortcuts.
- "I'll use a custom Docker base image for my specific needs" → Only UWM base images are allowed. They include SonarQube analysis (build) and security hardening (runtime).
- "This small service doesn't need ARCOM" → If it's a new service, it needs ARCOM. The process was streamlined in January 2026 — submit through Keystone and the ARCOM card is created automatically.

</critical_rules>

<verification_checklist>

Before moving to Phase 2 (design-api), verify ALL of the following:

### Keystone and ARCOM
- [ ] Keystone application submitted at `https://keystone.uwm.com/`
- [ ] ARCOM Jira issue exists in ARCOM project (auto-created by Keystone)
- [ ] ARCOM review meeting attended
- [ ] ARCOM status: **Approved**
- [ ] Keystone application status: **completed** (all workflows succeeded)

### Repository and Infrastructure
- [ ] Bitbucket repository exists with correct name (cell-biz-{name} pattern)
- [ ] Harness pipeline created and visible
- [ ] Kubernetes namespaces exist (integration, staging, production)
- [ ] Vault configuration present (4 service accounts: dev, int, stg, prd)
- [ ] DNS entries created for all environments ({name}.int.uwm.com, {name}.stage.uwm.com, {name}.uwm.com)
- [ ] ServiceNow CMDB record created
- [ ] PactFlow pacticipant registered

### Project Structure
- [ ] Starter kit applied (either via Keystone or manual `dotnet new uwmcstarterv3`)
- [ ] .NET project targets net8.0 or net10.0
- [ ] Solution structure follows cell-biz-* conventions
- [ ] Dockerfile uses UWM base images:
  - Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat`
  - Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat`
- [ ] Dockerfile includes `RUN /tmp/hardening.sh` and `USER uwm`
- [ ] Port configured as 5000 (`ASPNETCORE_URLS=http://*:5000`)

### Initial Configuration
- [ ] GUP auth configured in Program.cs (`AddPassport`, `UsePassport`)
- [ ] Vault integration configured (`AddVaultSecrets`)
- [ ] Environment-specific appsettings files exist (Development, Integration, Staging, Production)
- [ ] Local dev docker-compose works (`docker-compose up` in dockercompose/)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-business-service` orchestrator (Phase 1)
- Developers directly when creating a new service

**After this skill, proceed to:**
- `design-api` (Phase 2) - Design REST endpoints, DTOs, versioning
- `implement-feature` (Phase 3) - TDD implementation of business logic

**Prerequisites:**
- Membership in `GRP-S-IT-Keystone-Contributor` or `GRP-S-IT Keystone Approver`
- Access to `https://keystone.uwm.com/`
- If no Keystone access, contact the Keystone team on Microsoft Teams

</integration>

<resources>

**Systems:**
- Keystone: `https://keystone.uwm.com/`
- ARCOM Jira Project: `https://work.uwm.com` → ARCOM project
- Bitbucket: `https://code.uwm.com/`
- UWM Artifact Registry: `https://artifacts.uwm.com/`

**Confluence Documentation:**
- Keystone Create Application Process: https://kb.uwm.com/display/Keystone/Create+Application+Process
- New Keystone Approval Process (Jan 2026): https://kb.uwm.com/display/Keystone/New+Keystone+Approval+Process
- ARCOM FAQ: https://kb.uwm.com/display/ARCOM/ARCOM+Frequently+Asked+Questions
- ARCOM Main Page: https://kb.uwm.com/display/ARCOM/Arcom%3A+Architecture+Committee
- Keystone System Design: https://kb.uwm.com/display/Keystone/Keystone+System+Design
- Keystone FAQ: https://kb.uwm.com/display/DEVOPSGGF/Keystone+%7C+Frequently+Asked+Questions
- Container Image Hardening Standard: https://kb.uwm.com/display/ITSTD/Container+Image+Hardening+Standard
- V3 Service SDLC UX: https://kb.uwm.com/display/EArch/V3+Service+SDLC+UX

**Starter Kit:**
- Repository: ATLAS/lib-csharp-starterkit on Bitbucket
- NuGet package: `UWMC.Starter.Kit.V3`
- Install source: `https://artifacts.uwm.com/artifactory/api/nuget/v3/nuget-production/index.json`

**UWM Docker Base Images:**
- Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat` (8.0 or 10.0)
- Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat` (8.0 or 10.0)

**Reference Services:**
- `cell-keystone` (GGF project) - .NET 10.0, modern Keystone provisioning source
- `cell-biz-broker-preferences` - .NET 8.0, mature business service pattern
- `cell-biz-borrower` - .NET 8.0, data-owning business service
- `cell-biz-condition` - .NET 8.0, business service with rules engine

**When stuck:**
- Keystone access issues → Contact Keystone team on Microsoft Teams
- ARCOM questions → Enterprise Architecture team
- Starter kit issues → Check ATLAS/lib-csharp-starterkit repo or Teams channels

</resources>
