---
name: prepare-deployment
description: Use when preparing a v3 service for CI/CD - multi-stage Dockerfile with UWM base images, Helm values.yaml, Jenkinsfile, health checks, and CD readiness
---

<skill_overview>
Guides the preparation of v3 business services for deployment through UWM's CI/CD pipeline. This skill covers the multi-stage Dockerfile using UWM base images, Helm values.yaml for Kubernetes deployment (Istio, Vault, probes, autoscaling), Jenkinsfile configuration with `buildPipeline` DSL, health check endpoints, docker-compose for local development, RepoMetaData.json, PactFlow contract testing configuration, and the CD Readiness checklist. All configuration patterns are verified from real production services.

**Key constraints:** All services run on port 5000 with non-root user `uwm`, security hardening via `/tmp/hardening.sh`, and UWM base images from `artifacts.uwm.com/build-images/`.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Base Docker images, security hardening, port configuration, and Helm chart structure are rigid UWM infrastructure requirements. Resource limits, autoscaling ranges, and health check implementation patterns adapt to service-specific needs.
</rigidity_level>

<quick_reference>

| Component | Required Configuration |
|-----------|----------------------|
| **Dockerfile (build)** | `FROM artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat` |
| **Dockerfile (runtime)** | `FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat` |
| **Security** | `RUN /tmp/hardening.sh` then `USER uwm` |
| **Port** | `ENV ASPNETCORE_URLS=http://*:5000` and `EXPOSE 5000` |
| **Health check** | `/hc` via USFS library or custom controller, `[AllowAnonymous]` |
| **Helm base values** | `framework: dotnet`, `containerPort: 5000`, vault enabled |
| **Helm env overrides** | `values.Integration.yaml`, `values.Staging.yaml`, `values.Production.yaml` |
| **Jenkinsfile** | `buildPipeline { majorVersion = 1; portDeploy = true }` |
| **PactFlow** | `iac/pacts.json` with `blockRelease: true` |
| **RepoMetaData** | `RepoMetaData.json` at repo root |
| **Local dev** | `dockercompose/docker-compose.yml` with `.env` |

</quick_reference>

<when_to_use>
- Setting up initial Dockerfile for a new v3 service
- Configuring Helm values.yaml for Kubernetes deployment
- Setting up Jenkinsfile for CI/CD pipeline
- Adding health check endpoints
- Preparing for CD Readiness review
- Creating docker-compose for local development
- Setting up PactFlow contract testing configuration

**Do NOT use for:**
- Business logic implementation (use `implement-feature`)
- Infrastructure integration like GUP, Kafka, Vault (use `integrate-infrastructure`)
- Test strategy and test writing (use `test-strategy`)
</when_to_use>

<the_process>

## Step 1: Multi-Stage Dockerfile

The Dockerfile uses a two-stage build with UWM base images. The SDK image includes SonarQube analysis tooling; the runtime image includes security hardening scripts.

### .NET 8.0 Pattern (Current Standard)

```dockerfile
FROM artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:8.0-redhat AS build-kestrel-env
ARG BRANCH_NAME
ARG RUN_SONAR
ARG TC_CLOUD_KEY
ARG BUILD_URL
WORKDIR /app

# Copy only what's needed (per Container Image Hardening Standard)
COPY src src
COPY test test
COPY .git .git
COPY *.sln *.json Copyright.lic ./

# Build, test, analyze, and publish (script baked into SDK image)
RUN /app/dotnet-build-test-analyze-publish.sh "$BRANCH_NAME" "$RUN_SONAR"

# Optional: PactFlow contract verification
# RUN /app/pact.sh "$VERSION" "$BRANCH_NAME" "$PACTFLOW_TOKEN"

FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:8.0-redhat
ENV ASPNETCORE_URLS=http://*:5000
EXPOSE 5000

# Security hardening (mandatory)
RUN /tmp/hardening.sh

WORKDIR /app
USER uwm
COPY --from=build-kestrel-env /app/publish .

ENTRYPOINT ["dotnet", "UWMC.Business.YourService.dll"]
```

### .NET 10.0 Pattern (For New/Migrated Services)

```dockerfile
FROM artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:10.0-redhat AS build
ARG BRANCH_NAME
ARG RUN_SONAR
ARG TC_CLOUD_KEY
ARG BUILD_URL
WORKDIR /app

COPY . ./

RUN /app/dotnet-build-test-analyze-publish.sh "$BRANCH_NAME" "$RUN_SONAR"

FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:10.0-redhat
ENV ASPNETCORE_URLS=http://*:5000
EXPOSE 5000

RUN /tmp/hardening.sh

WORKDIR /app
USER uwm
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "UWMC.Business.YourService.dll"]
```

**Key differences between versions:**
- Build alias: `build-kestrel-env` (net8.0) vs `build` (net10.0)
- COPY strategy: Granular (net8.0) vs `COPY . ./` (net10.0)
- Pact testing: Supported in net8.0 Dockerfiles, not yet in net10.0

### Container Image Hardening Requirements

These are mandatory per the Container Image Hardening Standard:
1. Only use UWM base images from `artifacts.uwm.com/build-images/`
2. Use `COPY` instead of `ADD`
3. Include `RUN /tmp/hardening.sh` in runtime stage
4. Set `USER uwm` (never run as root)
5. Never store secrets in the Dockerfile (use Vault)
6. Prefer granular COPY statements over `COPY . ./`

---

## Step 2: Helm values.yaml Configuration

All Helm configuration lives in the `iac/` directory at the repo root.

### Base Values (iac/values.yaml)

```yaml
framework: dotnet
partOf: biz-your-service

istio:
  enabled: true
  tls: true

image:
  url: ${artifact.metadata.image}

createNamespace: true

service:
  type: ClusterIP

containerPort:
  port: 5000

env:
  ASPNETCORE_ENVIRONMENT: ${env.name}

vault:
  enabled: true
  role: biz-your-service
  tlsSecret: "vault-cert"

startupProbe:
  httpGet:
    path: /hc
    port: 5000
  initialDelaySeconds: 15
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /hc
    port: 5000

livenessProbe:
  httpGet:
    path: /hc
    port: 5000

resources:
  limits:
    cpu: 750m
    memory: 1280Mi
  requests:
    cpu: 500m
    memory: 800Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 6
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

**Key fields explained:**
- `framework: dotnet` — Tells the Helm base chart this is a .NET service
- `partOf` — Logical grouping (e.g., `biz-your-service`)
- `istio.enabled/tls` — Istio service mesh with mTLS (always enabled)
- `image.url` — Harness artifact variable (populated during deployment)
- `vault.role` — Vault role name matching Keystone provisioning
- Probe `path` — Must match your health check endpoint path
- `autoscaling` — Adjust min/max replicas based on expected load

### Environment-Specific Overrides

Create three environment override files:

**iac/values.Integration.yaml:**
```yaml
istio:
  hostName: your-service.int.uwm.com

podAnnotations:
  env: INT
  team: YOUR-TEAM

autoscaling:
  minReplicas: 1
  maxReplicas: 3
```

**iac/values.Staging.yaml:**
```yaml
istio:
  hostName: your-service.stage.uwm.com

podAnnotations:
  env: STG
  team: YOUR-TEAM

autoscaling:
  minReplicas: 2
  maxReplicas: 4

resources:
  limits:
    cpu: 500m
    memory: 1024Mi
  requests:
    cpu: 250m
    memory: 512Mi
```

**iac/values.Production.yaml:**
```yaml
istio:
  hostName: your-service.uwm.com

podAnnotations:
  env: PRD
  team: YOUR-TEAM

autoscaling:
  minReplicas: 3
  maxReplicas: 6
```

**How value overlaying works:**
1. Harness clones `kubernetes-templates` repo (base chart)
2. Reads base chart `values.yaml` → overlays your `iac/values.yaml` → overlays environment-specific `values.{Environment}.yaml`
3. Runs `helm template` to generate K8s manifests
4. Applies with `kubectl apply`

---

## Step 3: Jenkinsfile Configuration

The Jenkinsfile uses UWM's `buildPipeline` DSL, a shared library that wraps all CI/CD steps.

### Standard Jenkinsfile

```groovy
buildPipeline {
    majorVersion = 1
    portDeploy = true
    useCheckmarx = true
    checkmarxConfig = [
        preset: '44'
    ]
}
```

### Available buildPipeline Options

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `majorVersion` | int | Yes | Major version number. New services start at 1. |
| `portDeploy` | bool | Yes | Triggers Port deployment steps. Required for CD. |
| `useCheckmarx` | bool | Recommended | Enables Checkmarx SAST security scanning. |
| `checkmarxConfig` | map | No | Checkmarx configuration (e.g., `preset: '44'`). |
| `newcbk8s` | bool | No | New container-based K8s deployment flag. |
| `useFeatureEnvironments` | bool | No | Enables feature environment support. |
| `namespaceOverride` | string | No | Custom K8s namespace (default: `uwm-${bbProjectKey}`). |

**For new services**, start with:
```groovy
buildPipeline {
    majorVersion = 1
    portDeploy = true
    useCheckmarx = true
    checkmarxConfig = [preset: '44']
}
```

---

## Step 4: Health Check Endpoint

Health checks are critical for Kubernetes probes (startup, readiness, liveness). The endpoint path must match what's configured in `values.yaml`.

### Recommended: USFS Library Pattern

The `USFS.Library.Extensions.Diagnostics.HealthChecks` package provides a standard implementation:

```csharp
// Program.cs or Startup.cs — service registration
builder.Services.AddUSFSHealthCheck(builder.Configuration);

// Program.cs — middleware pipeline
app.UseUSFSHealthCheck();
```

This maps to the `/hc` endpoint automatically.

### Alternative: Custom Controller Pattern

If you need custom health logic (e.g., database connectivity checks):

```csharp
[ApiController]
[Route("[controller]")]
[AllowAnonymous]
[ExcludeFromCodeCoverage]
public class HealthCheckController : ControllerBase
{
    private readonly YourDbContext _context;

    public HealthCheckController(YourDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        try
        {
            var canConnect = await _context.Database.CanConnectAsync();
            if (canConnect)
                return Ok(new { Status = "Healthy" });

            return StatusCode(503, new { Status = "Unhealthy", Reason = "Database unavailable" });
        }
        catch (Exception ex)
        {
            return StatusCode(503, new { Status = "Unhealthy", Reason = ex.Message });
        }
    }
}
```

This maps to `/healthcheck` (derived from controller name minus "Controller" suffix).

### Health Check Requirements

- **MUST allow anonymous access** — Kubernetes probes cannot authenticate. Use `[AllowAnonymous]` attribute or `.AllowAnonymous()` on the endpoint.
- **Endpoint path must match values.yaml probes** — If your health check is at `/hc`, all three probes in values.yaml must use `path: /hc`.
- **Return 200 for healthy, 503 for unhealthy** — Standard HTTP status codes.
- **Consider database connectivity** — Include a `CanConnectAsync()` or `SELECT 1` check if your service depends on a database.
- **Exclude from code coverage** — Use `[ExcludeFromCodeCoverage]` to avoid inflating coverage numbers.

---

## Step 5: Environment-Specific appsettings

Create configuration files for each deployment environment:

```
src/UWMC.Business.YourService/
  appsettings.json                  # Base/shared configuration
  appsettings.Development.json      # Local development
  appsettings.Integration.json      # INT environment
  appsettings.Staging.json          # STG environment
  appsettings.Production.json       # PRD environment
```

The active environment is set via the `ASPNETCORE_ENVIRONMENT` variable in Helm values (`env.ASPNETCORE_ENVIRONMENT: ${env.name}`).

**Key configuration differences by environment:**
- `ApplicationEdgeUrl` — GUP edge URL per environment
- Database connection strings — Vault-injected per environment
- External service URLs — Different base URLs per environment
- Logging levels — More verbose in Development/Integration
- Feature flag configuration — Different namespaces per environment

---

## Step 6: docker-compose for Local Development

Create a `dockercompose/` directory at the repo root:

### dockercompose/.env
```env
BACKEND_IMAGE_NAME=cell-biz-your-service
BACKEND_DOCKERFILE_PATH=src/UWMC.Business.YourService/Dockerfile
BACKEND_PORT=5000
RUN_SONAR=false
LOCAL_DB_PASSWORD=L0caldev
LOCAL_DB_PORT=14333
```

### dockercompose/docker-compose.yml

**Minimal (no local database):**
```yaml
services:
  uwmc.business.yourservice:
    container_name: UWMC.Business.YourService_backend
    image: ${DOCKER_REGISTRY-}${BACKEND_IMAGE_NAME}
    build:
      context: ../
      dockerfile: ${BACKEND_DOCKERFILE_PATH}
      args:
        RUN_SONAR: ${RUN_SONAR}
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:${BACKEND_PORT}
    networks:
      - local_dev
    ports:
      - ${BACKEND_PORT}:${BACKEND_PORT}

networks:
  local_dev:
    driver: bridge
```

**With local SQL Server:**
```yaml
services:
  uwmc.business.yourservice:
    # ... same as above ...
    depends_on:
      sql.server:
        condition: service_healthy

  sql.server:
    image: artifacts.uwm.com/microsoft/mssql/server:2022-CU13-ubuntu-22.04
    container_name: sql_server_local
    environment:
      - ACCEPT_EULA=Y
      - MSSQL_SA_PASSWORD=${LOCAL_DB_PASSWORD}
    ports:
      - ${LOCAL_DB_PORT}:1433
    healthcheck:
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "${LOCAL_DB_PASSWORD}", "-C", "-Q", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  local_dev:
    driver: bridge
```

---

## Step 7: RepoMetaData.json

Create `RepoMetaData.json` at the repository root to document service metadata:

```json
{
  "Parent_Product": "YOUR-PRODUCT",
  "Application_Tier": "2",
  "Ownership": {
    "SVP": "SVP Name",
    "VP": "VP Name"
  },
  "Repository_Maintainer": {
    "Team_Lead": "Lead Name",
    "Application_Architects": ["Architect Name"],
    "Senior_Developers": ["Dev 1", "Dev 2"],
    "Deploy_Authority": ["Release Team"]
  },
  "Hosting": {
    "OS_Name": "Linux",
    "Cloud_Provider_Name": "Azure",
    "Hosting Location": "K8s Cluster"
  },
  "Down_Stream_Dependency": {
    "Internal": {
      "Build_Time": {
        "Build_File_Location": [],
        "Dependency_List": []
      },
      "Run_Time": []
    },
    "External": {
      "Build_Time": [],
      "Run_Time": []
    }
  },
  "Up_Stream_Dependency": {
    "InternalConsumer": [],
    "ExternalConsumer": []
  },
  "Persistent_DB": [{
    "Name": "your-service-db",
    "Database_Type": "SQL Server",
    "Data_Retention_Policy": {"TTL": "N/A", "Archivable": "N/A"}
  }],
  "Cache_DB": [],
  "Message_Broker": {"Name": "N/A"},
  "UWM_MicroService_Version": "V3",
  "Feature_Flag_Location": "Harness"
}
```

---

## Step 8: PactFlow Contract Testing Configuration

Create `iac/pacts.json` for contract testing integration:

```json
{
  "version": 1,
  "pacticipant": "CELL-BIZ-YOUR-SERVICE",
  "baseUrl": "https://uwm1.pactflow.io",
  "oasPath": "./openapi.yaml",
  "verificationPath": "./verifier.txt",
  "blockRelease": true,
  "skipPactFlow": false
}
```

**Key fields:**
- `pacticipant` — Uppercase repo name (e.g., `CELL-BIZ-YOUR-SERVICE`)
- `blockRelease: true` — **Required for CD readiness.** Blocks release if contract verification fails.
- `skipPactFlow: false` — Set to `true` only during initial development before contracts exist

---

## Step 9: Static Analysis Gates

These gates are enforced by the CI pipeline (via the SDK image's `dotnet-build-test-analyze-publish.sh` script):

| Gate | Threshold | Tool |
|------|-----------|------|
| Code Coverage | >= 80% | SonarQube (baked into SDK image) |
| Mutation Score | >= 80 | Stryker.NET (run locally and in pipeline) |
| Security Scanning | No High/Critical | Checkmarx SAST (via Jenkinsfile `useCheckmarx`) |
| Dependency Vulnerabilities | No High/Critical | Snyk / ArmorCode |

---

## Step 10: CD Readiness Checklist

Before a service is approved for Continuous Deployment, all of the following must be met:

1. **80% Mutation Score** — Verified via pipeline and locally with Stryker.NET
2. **Integration Test Suite** — Comprehensive hermetic tests using TestContainers within the codebase
3. **E2E Test Suites** — End-to-end tests in TestKube for INT, STG, and PRD environments
4. **Contract Testing** — PactFlow with `blockRelease: true` in `iac/pacts.json`
5. **Defect Tracking** — Team working agreement for defect-driven test coverage expansion
6. **CUJs with SLOs** — Critical User Journeys with Service Level Objectives defined in runbook
7. **Alerting and Monitoring** — PagerDuty on-call rotation and Dynatrace dashboards configured
8. **Availability and Latency Monitoring** — All endpoints monitored
9. **Site Reliability Guardian (SRG)** — Configured in Dynatrace for upper and lower environments
10. **Performance Testing** — TestKube performance tests and Dynatrace synthetic monitoring
11. **Safe Database Deployment** — Team members completed CI course for Safe DB
12. **Snyk/ArmorCode Security** — High and Critical vulnerabilities block PRs
13. **Feature Flags** — New features guarded with Harness feature flags

</the_process>

<examples>

<example>
<scenario>Setting up a new business service for deployment</scenario>

<code>
# CORRECT: Complete deployment configuration

# 1. Dockerfile with UWM base images
# src/UWMC.Business.LoanConditions/Dockerfile
FROM artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:8.0-redhat AS build-kestrel-env
ARG BRANCH_NAME
ARG RUN_SONAR
WORKDIR /app
COPY src src
COPY test test
COPY .git .git
COPY *.sln *.json Copyright.lic ./
RUN /app/dotnet-build-test-analyze-publish.sh "$BRANCH_NAME" "$RUN_SONAR"

FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:8.0-redhat
ENV ASPNETCORE_URLS=http://*:5000
EXPOSE 5000
RUN /tmp/hardening.sh
WORKDIR /app
USER uwm
COPY --from=build-kestrel-env /app/publish .
ENTRYPOINT ["dotnet", "UWMC.Business.LoanConditions.dll"]

# 2. Jenkinsfile
buildPipeline {
    majorVersion = 1
    portDeploy = true
    useCheckmarx = true
    checkmarxConfig = [preset: '44']
}

# 3. iac/values.yaml with probes matching /hc endpoint
# 4. Health check via AddUSFSHealthCheck() → /hc
# 5. RepoMetaData.json with ownership and dependencies
# 6. iac/pacts.json with blockRelease: true
</code>
</example>

<example>
<scenario>Developer uses custom Docker base image</scenario>

<code>
# WRONG: Custom base image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# ...
FROM mcr.microsoft.com/dotnet/aspnet:8.0
</code>

<why_it_fails>
- UWM base images include SonarQube analysis tooling (SDK) and security hardening scripts (runtime)
- The `dotnet-build-test-analyze-publish.sh` script is baked into the UWM SDK image — it won't exist in Microsoft's image
- The `/tmp/hardening.sh` script is baked into the UWM runtime image — security hardening will fail
- Deployment will be rejected because the image doesn't meet UWM security requirements
- Must use `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar` and `uwm-aspnet-runtime`
</why_it_fails>
</example>

<example>
<scenario>Health check endpoint requires authentication</scenario>

<code>
# WRONG: Health check behind auth
[ApiController]
[Route("[controller]")]
[Authorize]  // <-- Kubernetes probes cannot authenticate!
public class HealthCheckController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok("Healthy");
}
</code>

<why_it_fails>
- Kubernetes startup, readiness, and liveness probes make HTTP requests without auth tokens
- If the health check requires auth, probes will get 401 responses
- K8s will think the pod is unhealthy and continuously restart it
- Must use `[AllowAnonymous]` on health check endpoints
</why_it_fails>

<correction>
[ApiController]
[Route("[controller]")]
[AllowAnonymous]
[ExcludeFromCodeCoverage]
public class HealthCheckController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new { Status = "Healthy" });
}
</correction>
</example>

<example>
<scenario>Probe path in values.yaml doesn't match actual health check endpoint</scenario>

<code>
# WRONG: Mismatch between values.yaml and actual endpoint

# values.yaml says:
startupProbe:
  httpGet:
    path: /hc        # <-- expects /hc
    port: 5000

# But the controller maps to /healthcheck
[Route("[controller]")]      # HealthCheckController → /healthcheck
public class HealthCheckController : ControllerBase { }
</code>

<why_it_fails>
- K8s probes hit /hc but the endpoint is at /healthcheck
- Probes get 404 responses → pod marked unhealthy → continuous restarts
- The probe path in values.yaml MUST match the actual endpoint path
</why_it_fails>
</example>

<example>
<scenario>Dockerfile runs as root</scenario>

<code>
# WRONG: Missing hardening and user switch
FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:8.0-redhat
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "UWMC.Business.YourService.dll"]
# Missing: RUN /tmp/hardening.sh
# Missing: USER uwm
# Service runs as root — security violation
</code>

<why_it_fails>
- Container Image Hardening Standard requires explicit non-root user
- `/tmp/hardening.sh` removes unnecessary packages and tightens permissions
- Running as root is a security violation that will be flagged in reviews
</why_it_fails>

<correction>
FROM artifacts.uwm.com/build-images/uwm-aspnet-runtime:8.0-redhat
ENV ASPNETCORE_URLS=http://*:5000
EXPOSE 5000
RUN /tmp/hardening.sh        # Security hardening BEFORE user switch
WORKDIR /app
USER uwm                     # Non-root user AFTER hardening
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "UWMC.Business.YourService.dll"]
</correction>
</example>

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **ALWAYS use UWM base Docker images** — `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar` (build) and `uwm-aspnet-runtime` (runtime). The SDK image includes SonarQube tooling; the runtime includes hardening scripts. Custom images will fail deployment.

2. **ALWAYS run security hardening** — `RUN /tmp/hardening.sh` followed by `USER uwm`. Both are mandatory. The hardening script must run before switching to non-root user.

3. **ALWAYS expose port 5000** — `ENV ASPNETCORE_URLS=http://*:5000` and `EXPOSE 5000`. All v3 services use port 5000. Do not change the port.

4. **Health checks MUST be anonymous** — Use `[AllowAnonymous]` attribute. Kubernetes probes cannot authenticate. Authenticated health checks cause infinite restart loops.

5. **Health check path MUST match values.yaml probes** — If your endpoint is `/hc`, all probes in values.yaml must use `path: /hc`. Mismatches cause pod restarts.

6. **ALWAYS enable Checkmarx** — Security scanning is required for production code. Set `useCheckmarx = true` in Jenkinsfile.

7. **ALWAYS use COPY instead of ADD** in Dockerfiles — Per the Container Image Hardening Standard.

8. **NEVER store secrets in Dockerfiles** — Use Vault for all secrets. No `ENV SECRET=...` or `ARG PASSWORD=...`.

9. **PactFlow `blockRelease` must be `true` for CD** — Contract test failures must block releases. Set `blockRelease: true` in `iac/pacts.json`.

10. **ALWAYS include `portDeploy = true`** in Jenkinsfile — Required for the Harness deployment pipeline to trigger.

## Common Mistakes

- "I'll use port 8080 like other frameworks" → UWM standardizes on port 5000. No exceptions.
- "Hardening slows down my local builds" → Hardening runs in the runtime stage only. Build stage is unaffected.
- "I don't need Checkmarx for this small service" → All production code requires security scanning. Enable it from the start.
- "I'll set blockRelease to false temporarily" → Keep it true. False means contract breaks deploy to production undetected.
- "My health check is simple, I don't need AllowAnonymous" → K8s probes don't have tokens. Without AllowAnonymous, probes fail → pod restarts infinitely.

</critical_rules>

<verification_checklist>

Before claiming deployment preparation complete, verify ALL of the following:

### Dockerfile
- [ ] Build stage uses `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat`
- [ ] Runtime stage uses `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat`
- [ ] Security hardening: `RUN /tmp/hardening.sh` present in runtime stage
- [ ] Non-root user: `USER uwm` present after hardening
- [ ] Port: `ENV ASPNETCORE_URLS=http://*:5000` and `EXPOSE 5000`
- [ ] Uses `COPY` not `ADD`
- [ ] No secrets in Dockerfile
- [ ] ENTRYPOINT references correct assembly name

### Helm Configuration
- [ ] `iac/values.yaml` exists with `framework: dotnet` and `containerPort: 5000`
- [ ] Vault enabled with correct role name
- [ ] Startup, readiness, and liveness probes configured
- [ ] Probe paths match actual health check endpoint
- [ ] Resource limits and requests defined
- [ ] Autoscaling configured (minReplicas, maxReplicas, CPU/memory targets)
- [ ] Environment override files exist: `values.Integration.yaml`, `values.Staging.yaml`, `values.Production.yaml`
- [ ] Each environment file has correct `istio.hostName` (int/stage/prod URLs)

### Jenkinsfile
- [ ] `buildPipeline` with `majorVersion` set
- [ ] `portDeploy = true`
- [ ] `useCheckmarx = true` with `checkmarxConfig`

### Health Check
- [ ] Health check endpoint defined and returns 200 OK when healthy
- [ ] Endpoint allows anonymous access (`[AllowAnonymous]`)
- [ ] Endpoint path matches values.yaml probe paths
- [ ] Database connectivity check included (if service has a database)

### Other Configuration
- [ ] Environment-specific appsettings files exist (Development, Integration, Staging, Production)
- [ ] `RepoMetaData.json` exists with correct ownership and metadata
- [ ] `iac/pacts.json` exists with `blockRelease: true`
- [ ] `dockercompose/docker-compose.yml` exists for local development
- [ ] `dockercompose/.env` exists with correct build configuration

### CD Readiness (for production deployment approval)
- [ ] Stryker mutation score >= 80
- [ ] SonarQube code coverage >= 80%
- [ ] Integration tests pass with TestContainers
- [ ] E2E smoke tests exist in TestKube
- [ ] PactFlow contracts verified
- [ ] PagerDuty on-call rotation configured
- [ ] Dynatrace dashboards and SRG configured
- [ ] Feature flags guard new features

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-business-service` orchestrator (Phase 6 — final phase)
- Developers directly when setting up deployment configuration

**Prerequisites (should be complete before this phase):**
- `create-v3-service` (Phase 1) — Keystone provisioning done
- `design-api` (Phase 2) — API endpoints designed
- `implement-feature` (Phase 3) — Business logic implemented with TDD
- `integrate-infrastructure` (Phase 4) — GUP, Vault, Kafka, EF Core configured
- `test-strategy` (Phase 5) — Integration, contract, and E2E tests written

**This skill does NOT depend on** but works alongside:
- `test-strategy` — CD Readiness requires test artifacts from Phase 5

</integration>

<resources>

**Confluence Documentation:**
- Container Image Hardening Standard: https://kb.uwm.com/display/ITSTD/Container+Image+Hardening+Standard
- CI/CD Qualifying Readiness Checklist: https://kb.uwm.com/pages/viewpage.action?pageId=1511560835
- CD PE Validation: https://kb.uwm.com/display/PE/Continuous+Deployment%28CD%29+Principal+Engineering+%28PE%29+Validation
- Helm Base Chart: https://kb.uwm.com/display/STACKTREK/K8s+%7C+Helm+Base+Chart
- ArgoCD Helm Chart Configuration: https://kb.uwm.com/display/STACKTREK/ArgoCD+%7C+Helm+Chart+Configuration+for+Automated+Deploy+Process

**UWM Docker Base Images:**
- Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat` (8.0 or 10.0)
- Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat` (8.0 or 10.0)
- SQL Server (local dev): `artifacts.uwm.com/microsoft/mssql/server:2022-CU13-ubuntu-22.04`

**Reference Services (verified patterns):**
- `cell-biz-borrower` — net8.0, USFS health check at /hc
- `cell-biz-broker-preferences` — net8.0, custom HealthCheckController at /healthcheck
- `cell-biz-condition` — net8.0, USFS health check, PactFlow configured
- `cell-keystone` — net10.0, custom Healthz controller at /api/healthz, KEDA autoscaling

**Health Check Libraries:**
- `USFS.Library.Extensions.Diagnostics.HealthChecks` — Standard `/hc` endpoint (recommended)

**PactFlow:**
- UWM PactFlow instance: `https://uwm1.pactflow.io`

**When stuck:**
- Deployment failures → Check Harness pipeline logs, verify values.yaml
- Health check issues → Verify probe path matches endpoint, check [AllowAnonymous]
- SonarQube gate failures → Check code coverage locally before pushing
- CD Readiness questions → Principal Engineering team

</resources>
