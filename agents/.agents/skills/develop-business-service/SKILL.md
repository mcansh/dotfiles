---
name: develop-business-service
description: Golden path for developing v3 business services at UWM - automatically guides through service creation, API design, TDD implementation, infrastructure integration, testing, and deployment
---

<skill_overview>
The golden path for v3 business service development at UWM. This orchestrator auto-detects your project's current state and chains through the appropriate development phases without requiring you to choose individual skills. It enforces UWM standards (PII masking, GUP auth, testing requirements, REST conventions) continuously throughout all phases.
</skill_overview>

<philosophy>
## The Business Service Is Everything

The v3 business service (cell-biz-*) is the **heart and soul** of all software development at UWM. It contains the **secret sauce** — the differentiating factors, the reason customers choose this business instead of competitors. Every architectural decision in this skill exists to protect that truth.

### Four Non-Negotiable Principles

1. **100% of business logic lives in the service layer.** Not "most of it." Not "the important parts." All of it. Validation, orchestration, rules, calculations, state transitions — if it's business logic, it belongs in the service.

2. **The service layer is the differentiating factor.** BFFs, frontends, databases, message brokers — these are commodity infrastructure. The business service is what makes UWM different from competitors. Treat it accordingly.

3. **100% of business capabilities must be executable via the service's HTTP API alone.** If a capability requires a specific frontend, a specific database query, or a specific message sequence to function — the service API is incomplete. A curl command should be able to exercise every business capability.

4. **No implicit state via shared databases or frontends.** If two services need the same data, one calls the other's API. If a frontend workflow requires multi-step coordination, the service exposes an API that encapsulates it. Shared state is shared coupling.

### Philosophy-Level Anti-Patterns

These explain **why** certain rules exist (see `critical_rules` for the specific prohibitions):

- **NO business logic in BFFs.** BFFs aggregate and shape data for frontends. They are thin pass-throughs. The moment a BFF contains an `if` statement about a loan condition, business logic has leaked out of the service.
- **NO shared-database implicit coupling.** Each service owns its data exclusively. "Just read from their table" is how monoliths are born. Call the API.
- **NO frontend-required workflows.** If the only way to complete a business process is to click through a specific UI flow, the API is incomplete. The service must stand alone.
- **NO scattering logic across transport layers.** Whether a request arrives via HTTP or Kafka, the same service-layer code executes the business logic. Transport is plumbing, not architecture.
</philosophy>

<rigidity_level>
MEDIUM FREEDOM - Phase ordering is rigid: create → design → implement → integrate → test → deploy. Specific guidance within each phase adapts to context. Standards enforcement is rigid and never skipped. Context detection determines which phase to start from.
</rigidity_level>

<quick_reference>

| Phase | Skill | When | Key Standards Enforced |
|-------|-------|------|----------------------|
| 1. Create | `create-v3-service` | New service needed | Keystone/ARCOM, UWM base Dockerfile, StarterKit |
| 2. Design | `design-api` | Planning endpoints/capabilities | REST kebab-case, v{integer} versioning, API security |
| 3. Implement | `implement-feature` | Writing business logic | Strict TDD, .feature specs, Stryker ≥80, coverage ≥80% |
| 4. Integrate | `integrate-infrastructure` | Connecting to external systems | GUP auth, Kafka, Vault, EF Core, feature flags |
| 5. Test | `test-strategy` | Adding non-unit tests | TestContainers, WireMock, PactFlow, E2E smoke |
| 6. Deploy | `prepare-deployment` | Preparing for CI/CD | Dockerfile, Helm, Jenkinsfile, health checks |

**Continuous enforcement at ALL phases:**
- PII/NPI masking via `[PersonallyIdentifiableInformation]` / `[NonpublicPersonalInformation]` from UWMC.Library.Logging
- GUP auth via UWMC.Library.User.Passport (no custom auth)
- One service per database
- .feature files are specs, NOT executable tests
- 80% coverage + 80 mutation score

</quick_reference>

<when_to_use>
Use this skill when:
- Creating a brand new v3 business service (cell-biz-*)
- Adding a new capability or feature to an existing v3 service
- Setting up infrastructure integrations (GUP, Kafka, database) for a v3 service
- Any backend development work on a cell-biz-* service
- Onboarding to v3 service development at UWM

Do NOT use this skill for:
- BFF development (cell-bff-*) - different patterns apply
- UI/frontend development (cell-ui-*) - separate concern
- Data service development (cell-data-*) - deprecated pattern, not creating new ones
- Non-.NET projects - this skill is specific to C#/.NET v3 microservices
</when_to_use>

<the_process>

## Step 1: Context Detection

Before starting any work, detect the current state of the project to determine which phase to begin from.

**Run these checks using Glob and Grep tools:**

```
Check 1: Is there a .csproj or .sln file?
  → Glob for **/*.csproj, **/*.sln
  → YES: Existing project. Proceed to phase detection.
  → NO: New service. Start from Phase 1 (create-v3-service).

Check 2: Is there a StarterKitFeatures.json?
  → Glob for **/StarterKitFeatures.json
  → YES: Starter kit already applied. Phase 1 complete.

Check 3: Does the Dockerfile use UWM base images?
  → Grep for "artifacts.uwm.com/build-images" in **/Dockerfile
  → YES: Deployment base configured. Phase 6 partially complete.

Check 4: Is UWMC.Library.User.Passport referenced?
  → Grep for "UWMC.Library.User.Passport" in **/*.csproj
  → YES: GUP auth already integrated. Phase 4 (auth) complete.

Check 5: Is there a test project with TestContainers?
  → Grep for "Testcontainers" or "TestContainers" in **/*.csproj
  → YES: Integration test infrastructure exists. Phase 5 partially complete.

Check 6: Are there unit test projects?
  → Glob for **/*Tests*.csproj, **/*Test*.csproj
  → YES: Unit testing set up.

Check 7: Is there a Kafka messaging reference?
  → Grep for "UWMC.Library.Messaging.Kafka" in **/*.csproj
  → YES: Kafka integration exists. Phase 4 (messaging) complete.
```

**Present detection results to the user:**

```
Context Detection Results:
- Project type: [New service / Existing v3 service]
- .NET version: [version from .csproj TargetFramework]
- Starter kit: [Applied / Not found]
- GUP auth: [Configured / Not configured]
- Kafka: [Configured / Not configured]
- Database: [EF Core found / Not found]
- Unit tests: [Found / Not found]
- Integration tests: [TestContainers found / Not found]
- Dockerfile: [UWM base images / Custom / Not found]

Starting from Phase [N]: [phase name].
```

---

## Step 2: Phase Execution

For each applicable phase, follow this pattern:

1. **Announce the phase:**
   "Phase [N]: [Phase Name] - Loading uwm-business-service-dev:[skill-name]"

2. **Load the sub-skill:**
   Use the Skill tool to load `uwm-business-service-dev:[skill-name]`

3. **Follow the sub-skill's instructions completely.**
   If the sub-skill is still a stub (contains "To be expanded"), provide inline guidance based on the process steps listed in the stub and the reference patterns below.

4. **Run the standards checkpoint** for that phase before moving to the next.

**Phase ordering is RIGID.** Always follow: 1 → 2 → 3 → 4 → 5 → 6.
Skip phases only when context detection confirms they are already complete.

**For existing services adding a feature**, the typical flow is:
- Skip to Phase 2 (design-api) to plan the new endpoints
- Phase 3 (implement-feature) for TDD implementation
- Phase 5 (test-strategy) to add/update integration and contract tests
- Skip Phase 4 and 6 if infrastructure and deployment are already configured

---

## Step 3: Standards Checkpoints Between Phases

After completing each phase, verify these criteria before proceeding:

### After Phase 1 (create-v3-service):
- [ ] Bitbucket repository exists (or Keystone submission started)
- [ ] StarterKitFeatures.json is present and configured
- [ ] Dockerfile uses UWM base images:
  - Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar`
  - Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime`
- [ ] .NET project targets net8.0 or net10.0
- [ ] Solution structure follows cell-biz-* conventions

### After Phase 2 (design-api):
- [ ] REST endpoints use kebab-case for resource names
- [ ] API versioning follows `v{integer}` pattern (e.g., `/v1/resource`)
- [ ] Request/response DTOs are defined
- [ ] FluentValidation validators are planned for request DTOs
- [ ] Error responses don't expose system details
- [ ] Long-running operations use async pattern (Kafka preferred, or HTTP 202)

### After Phase 3 (implement-feature):
- [ ] .feature files exist as specification documents (NOT configured as executable tests)
- [ ] xUnit unit tests exist at component boundary
- [ ] Unit tests mock ONLY infrastructure layer (repositories, HTTP clients, message handlers)
- [ ] Unit tests do NOT mock business logic (services, orchestrators, validators, mappers)
- [ ] Run Stryker.NET: mutation score ≥ 80
- [ ] Code coverage ≥ 80% on new code
- [ ] PII/NPI fields have `[PersonallyIdentifiableInformation]` or `[NonpublicPersonalInformation]` attributes
- [ ] Structured logging uses < 50 user-defined properties
- [ ] No PII/NPI logged without masking attributes

### After Phase 4 (integrate-infrastructure):
- [ ] GUP authentication configured:
  - `UWMC.Library.User.Passport` NuGet package installed
  - `AddPassport(Configuration)` called AFTER other auth services
  - `UsePassport()` called BEFORE other middleware
  - `MapPassportEndpoints()` called if service serves UI (BFF pattern)
  - `ApplicationEdgeUrl` configured in appsettings for all environments
  - Health check endpoint allows anonymous: `.AllowAnonymous()`
  - HttpClientFactory used (NOT `new HttpClient()`) for header propagation
- [ ] Vault integration configured:
  - `UWMC.Vault` package installed
  - `AddVaultSecrets()` called in Program.cs
- [ ] Kafka configured (if needed):
  - HTTP API and Kafka consumer are SEPARATE repositories
  - `UWMC.Library.Messaging.Kafka` package installed
- [ ] Feature flags configured (if needed):
  - `UWMC.Library.FeatureFlags` packages installed
  - Namespace set to service name (e.g., `cell-biz-your-service`)
- [ ] Database access follows one-service-per-database rule

### After Phase 5 (test-strategy):
- [ ] Hermetic integration tests using TestContainers:
  - DbFixture class for SQL/Cosmos containers
  - xUnit CollectionDefinitions to manage container lifecycle
  - WireMock for external HTTP service isolation
  - Mock Auth Policy Evaluator for GUP auth
  - CustomWebApplicationFactory for app hosting
  - Tests call public API endpoints only (client perspective)
- [ ] Contract tests defined (PactFlow):
  - Consumer contracts specify expected requests/responses
  - Provider verification planned
- [ ] E2E smoke tests (minimal count):
  - Critical user journeys only
  - API smoke tests via RestSharp
- [ ] All test projects exclude integration/E2E from Stryker mutation testing

### After Phase 6 (prepare-deployment):
- [ ] Multi-stage Dockerfile:
  - Build stage: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat`
  - Runtime stage: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat`
  - Security hardening: `RUN /tmp/hardening.sh`
  - Non-root user: `USER uwm`
  - Port 5000: `ENV ASPNETCORE_URLS=http://*:5000`
- [ ] Helm values.yaml configured:
  - `framework: dotnet`
  - `containerPort: 5000`
  - Vault enabled with service role
  - Liveness probe on health check endpoint
  - Resource limits and autoscaling defined
- [ ] Jenkinsfile configured:
  - `buildPipeline` with `portDeploy = true`
  - Checkmarx security scanning enabled
- [ ] Health check endpoint defined and responds 200 OK
- [ ] Environment-specific appsettings files exist (Development, Integration, Staging, Production)

---

## Step 4: Continuous Standards Enforcement

These rules are ALWAYS active, regardless of current phase:

### PII/NPI Masking (UWMC.Library.Logging)
```csharp
// CORRECT: Use masking attributes on model properties
public class LoanApplication
{
    public string LoanNumber { get; set; }  // OK to log (approved)

    [PersonallyIdentifiableInformation]
    public string BorrowerName { get; set; }  // Auto-masked in logs

    [NonpublicPersonalInformation]
    public string SSN { get; set; }  // Auto-masked in logs

    [PersonallyIdentifiableInformation]
    public string Email { get; set; }  // Auto-masked in logs
}

// WRONG: Logging PII/NPI without attributes
_logger.LogInformation("Processing for {BorrowerName}", borrower.Name);  // VIOLATION
```

### Authentication (UWMC.Library.User.Passport)
```csharp
// CORRECT: GUP auth setup in Program.cs
builder.Services.AddPassport(builder.Configuration);  // AFTER other auth
// ...
app.UsePassport();  // BEFORE other middleware
app.MapPassportEndpoints();  // For BFF/UI-serving services
app.MapControllers().RequirePassport();  // Or .RequireAuthorization() for Combined scheme

// CORRECT: Authorization attributes
[RequireSecurityGroup("GRP-YourTeam")]
[HttpGet("admin")]
public IActionResult AdminEndpoint() { }

// WRONG: Custom auth middleware
app.UseMiddleware<CustomJwtMiddleware>();  // VIOLATION - use GUP
```

### Testing Boundaries
```csharp
// CORRECT: Mock only infrastructure layer
var mockRepository = new Mock<ILoanRepository>();  // Infrastructure - OK to mock
var mockHttpClient = new Mock<IExternalServiceClient>();  // External dep - OK to mock

var service = new LoanService(mockRepository.Object, mockHttpClient.Object, realMapper, realValidator);

// WRONG: Mocking business logic
var mockValidator = new Mock<ILoanValidator>();  // Business logic - DO NOT mock
var mockMapper = new Mock<ILoanMapper>();  // Business logic - DO NOT mock
var mockOrchestrator = new Mock<ILoanOrchestrator>();  // Business logic - DO NOT mock
```

### .feature Files as Specifications
```gherkin
# This is a SPECIFICATION DOCUMENT, not an executable test.
# Use this to derive xUnit test cases.

Feature: Loan Condition Tracking
  As a loan officer
  I want to track conditions on a loan
  So that I can ensure all requirements are met before closing

  Scenario: Add a new condition to an active loan
    Given an active loan exists with loan number "1234567"
    When I add a condition "Proof of Income" with due date "2026-03-15"
    Then the condition should be created with status "Pending"
    And the loan should have 1 outstanding condition

  Scenario: Satisfy an outstanding condition
    Given an active loan "1234567" has a pending condition "Proof of Income"
    When the condition is marked as satisfied with document "paystub.pdf"
    Then the condition status should be "Satisfied"
    And the loan outstanding condition count should decrease by 1
```

```csharp
// CORRECT: xUnit tests DERIVED FROM the .feature specification
public class LoanConditionServiceTests
{
    [Fact]
    public async Task AddCondition_ActiveLoan_CreatesWithPendingStatus()
    {
        // Arrange - from "Given an active loan exists"
        var mockRepo = new Mock<ILoanConditionRepository>();
        var service = new LoanConditionService(mockRepo.Object, new ConditionValidator());

        // Act - from "When I add a condition"
        var result = await service.AddConditionAsync("1234567", new AddConditionRequest
        {
            Name = "Proof of Income",
            DueDate = new DateTime(2026, 3, 15)
        });

        // Assert - from "Then the condition should be created with status Pending"
        result.Status.Should().Be(ConditionStatus.Pending);
        mockRepo.Verify(r => r.SaveAsync(It.Is<Condition>(c =>
            c.Status == ConditionStatus.Pending && c.Name == "Proof of Income")), Times.Once);
    }
}
```

### HTTP/Kafka Split Repository Pattern
When a business capability requires both HTTP API endpoints and Kafka message consumers:
- Create **separate repositories**: `cell-biz-your-service` (HTTP API) and `cell-biz-your-service-consumer` (Kafka consumer)
- Both repos share the same business domain but are independently deployable
- Each repo produces its own Docker container (v3 constraint: one container per repo)
- Shared domain models can be published as a NuGet package if needed

### REST API Conventions
```
CORRECT:
  GET    /v1/loan-conditions/{id}          (kebab-case, versioned)
  POST   /v1/loan-conditions               (plural nouns)
  PUT    /v1/loan-conditions/{id}          (full replace)
  PATCH  /v1/loan-conditions/{id}          (partial update)
  DELETE /v1/loan-conditions/{id}

WRONG:
  GET    /api/LoanConditions/{id}          (PascalCase - wrong)
  GET    /v1/get-loan-condition/{id}       (verb in path - wrong)
  GET    /loanConditions/{id}              (camelCase, no version - wrong)
  GET    /v1/loan_conditions/{id}          (snake_case - wrong)
```

---

## Edge Case Handling

### Non-v3 Project Detected
If no .csproj/.sln files are found AND the user hasn't indicated they want to create a new service:

"This directory doesn't contain a .NET project. This skill is designed for v3 (.NET) business services (cell-biz-*).

Options:
1. If you want to **create a new service**, I'll start from Phase 1 (create-v3-service)
2. If this is the **wrong directory**, navigate to your v3 service directory first
3. If this is a **different type of project** (BFF, UI, data), this skill doesn't apply"

### Mid-Project Entry
When context detection shows the project is partially configured:

"I detected an existing v3 service with the following state:
[detection results]

You appear to be at Phase [N]. Options:
1. **Start from Phase [N]** - continue where the project left off
2. **Review earlier phases** - verify previous phases meet current standards
3. **Jump to a specific phase** - if you know what you need"

### No Keystone Access
If the user indicates they can't access Keystone or ARCOM:

"Keystone provisioning requires ARCOM approval. Options:
1. If your service is **already provisioned**, we can skip to Phase 2 (design-api)
2. If you need Keystone access, contact the **Keystone team** on Microsoft Teams
3. If you need ARCOM guidance, the documentation is at https://kb.uwm.com/display/Keystone/"

### Legacy Patterns Detected
If the project uses patterns that don't match current standards (e.g., .NET 6, old Startup.cs pattern without modern minimal API, missing GUP):

"This service uses some legacy patterns:
- [specific legacy pattern detected]

The current v3 standard is:
- [current standard]

Options:
1. **Modernize** - update to current patterns as part of this work
2. **Work within existing patterns** - maintain consistency with what's here
3. **Selective modernization** - update specific areas while keeping others"

### Stub Sub-Skill Loaded
If a sub-skill's SKILL.md is still a stub (contains "To be expanded"):

Do NOT fail silently. Instead:
1. Read the stub's `the_process` section for the high-level steps
2. Provide guidance based on those steps and the standards in this orchestrator
3. Note to the user: "The detailed [skill-name] skill is being developed. I'm providing guidance based on the current process outline and UWM standards."

</the_process>

<examples>

<example>
<scenario>Developer asks to create a brand new loan condition tracking service</scenario>

<code>
User: "I need to build a new business service that tracks loan conditions"

Claude without golden path:
"Sure, let me create a new .NET project..."
[Creates project without Keystone, skips ARCOM, uses custom auth, no testing strategy]
</code>

<why_it_fails>
- Skipped Keystone provisioning (service can't deploy without ARCOM approval)
- No GUP auth (custom auth violates standards)
- No testing strategy (will fail SonarQube 80% coverage gate)
- No PII masking considerations (compliance violation)
- Dockerfile won't use UWM base images (deployment will fail)
</why_it_fails>

<correction>
Claude with golden path:

"I'm using uwm-business-service-dev:develop-business-service to guide this development.

**Context Detection Results:**
- Project type: New service (no .csproj found)
- Starting from Phase 1: create-v3-service

**Phase 1: Service Creation**
Loading uwm-business-service-dev:create-v3-service...

Before writing any code, you need to go through Keystone provisioning:
1. Prepare your ARCOM proposal documenting the service's purpose
2. Submit via Keystone UI with:
   - Service name: cell-biz-loan-conditions
   - Project key: [your team's Bitbucket project]
   - Required fields: DNS entry, clusters, ARCOM proposal link
3. Wait for ARCOM approval (architecture review meeting)
4. Once approved, Keystone automatically provisions:
   - Bitbucket repo with starter kit
   - Kubernetes namespaces (integration, staging, production)
   - Vault namespace and configuration
   - DNS entries and certificates
   - ServiceNow CMDB record

**Standards Checkpoint (Phase 1):**
- [ ] ARCOM proposal submitted
- [ ] Keystone provisioning complete
- [ ] StarterKitFeatures.json configured (withRest: true)
- [ ] Dockerfile uses uwm-dotnet-sdk-sonar and uwm-aspnet-runtime base images

**Phase 2: API Design**
Loading uwm-business-service-dev:design-api...

Let's design the REST API for loan condition tracking:
- GET    /v1/loan-conditions/{loanNumber}     - List conditions for a loan
- POST   /v1/loan-conditions                  - Add a new condition
- PATCH  /v1/loan-conditions/{id}/satisfy     - Mark condition as satisfied
- DELETE /v1/loan-conditions/{id}             - Remove a condition

[Continues through all phases with standards enforcement...]"
</correction>
</example>

<example>
<scenario>Developer asks to add a feature to an existing v3 service</scenario>

<code>
User: "Add a bulk condition update endpoint to cell-biz-conditions"

Claude without golden path:
"Let me add a new controller action..."
[Adds endpoint without TDD, skips mutation testing, no integration test updates]
</code>

<why_it_fails>
- No TDD workflow (code written before tests)
- No mutation testing (test quality unknown)
- No integration test updates (new endpoint untested hermetically)
- May not follow REST conventions for bulk operations
- No PII consideration for bulk payloads
</why_it_fails>

<correction>
Claude with golden path:

"I'm using uwm-business-service-dev:develop-business-service.

**Context Detection Results:**
- Project type: Existing v3 service
- .NET version: net8.0
- Starter kit: Applied (StarterKitFeatures.json found)
- GUP auth: Configured (UWMC.Library.User.Passport in .csproj)
- Unit tests: Found (xUnit test project)
- Integration tests: TestContainers configured
- Dockerfile: UWM base images

Starting from Phase 2: design-api (service already provisioned and configured)

**Phase 2: Design the bulk update API**
Loading uwm-business-service-dev:design-api...

For bulk operations, the REST standard says:
- PATCH /v1/loan-conditions/bulk    (partial update multiple resources)
- Request body: array of condition updates
- Response: 200 with results array (success/failure per item)
- Consider: maximum batch size to prevent timeout

**Phase 3: Implement with TDD**
Loading uwm-business-service-dev:implement-feature...

1. Write .feature specification for bulk update scenarios
2. Derive xUnit test cases from the specification
3. Write tests first (RED)
4. Implement BulkUpdateConditionsAsync in LoanConditionService
5. Tests pass (GREEN)
6. Run Stryker: verify mutation score >= 80
7. Verify coverage >= 80%
8. Check: any PII in bulk payloads? Add masking attributes

**Phase 5: Update integration tests**
Loading uwm-business-service-dev:test-strategy...

1. Add integration test for bulk endpoint using TestContainers
2. Test through public API (POST to /v1/loan-conditions/bulk)
3. Update PactFlow consumer contract if consumers exist
4. Add smoke test for bulk endpoint

**Standards Checkpoint Summary:**
- [ ] Endpoint uses kebab-case: /v1/loan-conditions/bulk
- [ ] Stryker mutation score >= 80
- [ ] Coverage >= 80%
- [ ] PII fields masked in DTOs
- [ ] Integration test added
- [ ] Contract updated"
</correction>
</example>

</examples>

<critical_rules>
## Rules That Have No Exceptions

1. **ALWAYS detect context before starting** - Never assume new or existing service
2. **NEVER skip a standards checkpoint between phases** - Each checkpoint catches violations early
3. **ALWAYS announce which phase and sub-skill you're using** - Transparency helps catch errors
4. **NEVER proceed past implement-feature without verifying mutation score >= 80** - Quality gate
5. **NEVER log PII/NPI without masking attributes** - Use `[PersonallyIdentifiableInformation]` and `[NonpublicPersonalInformation]` from UWMC.Library.Logging
6. **ALWAYS use GUP for authentication** - UWMC.Library.User.Passport is mandatory, no custom auth
7. **NEVER combine HTTP API and Kafka consumer in one repo** - V3 pattern requires separate repos
8. **NEVER execute .feature files directly** - They are specifications for writing xUnit tests
9. **NEVER mock business logic in unit tests** - Mock only infrastructure layer (repositories, HTTP clients, message handlers)
10. **ALWAYS use UWM base Docker images** - `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar` and `uwm-aspnet-runtime`
11. **ALWAYS follow REST conventions** - Kebab-case resources, v{integer} versioning, proper HTTP verbs
12. **NEVER skip ARCOM review for new services** - All new services require ARCOM approval via Keystone

## Common Rationalizations (All Mean STOP)

- "This is a simple endpoint, don't need TDD" → Every feature gets TDD. No exceptions.
- "I'll add tests later" → Tests come FIRST. RED-GREEN-REFACTOR.
- "Custom auth is simpler" → GUP is mandatory. No alternatives.
- "One repo for both HTTP and Kafka is easier" → Separate repos. V3 constraint.
- "Mutation testing takes too long" → Quality gate. Score must be >= 80.
- "ARCOM approval is slow, let me just create the repo" → Keystone handles this. Follow the process.
- "This field isn't really PII" → If in doubt, mask it. Check Data Masking Standard.
- "The .feature file runner is set up, let me just execute it" → .feature files are SPECS. Write xUnit tests.
</critical_rules>

<verification_checklist>
Before claiming any unit of work complete:

### Code Quality
- [ ] All new code has unit tests written FIRST (TDD)
- [ ] Stryker.NET mutation score >= 80 on unit tests
- [ ] Code coverage >= 80% on new code (SonarQube gate)
- [ ] No .feature files configured as executable tests
- [ ] Unit tests mock ONLY infrastructure layer

### Standards Compliance
- [ ] PII/NPI fields have masking attributes from UWMC.Library.Logging
- [ ] Structured logging uses < 50 user-defined properties
- [ ] No PII/NPI logged without masking
- [ ] Security logging events captured (login, logout, access attempts)

### API Standards
- [ ] REST endpoints use kebab-case resource names
- [ ] API versioning follows v{integer} pattern
- [ ] Error responses don't expose system details
- [ ] Proper HTTP status codes (client vs server errors)

### Authentication
- [ ] GUP auth configured via UWMC.Library.User.Passport
- [ ] No custom auth implementations
- [ ] Health check endpoint allows anonymous access
- [ ] HttpClientFactory used for service-to-service calls (header propagation)

### Infrastructure
- [ ] Dockerfile uses UWM base images from artifacts.uwm.com
- [ ] One service per database rule followed
- [ ] HTTP API and Kafka consumer in separate repos (if both needed)
- [ ] Vault integration for secrets (no hardcoded credentials)

### Testing
- [ ] Integration tests use TestContainers (not mocked databases)
- [ ] WireMock used for external HTTP service isolation
- [ ] Contract tests defined in PactFlow (if API has consumers)
- [ ] E2E smoke tests exist for critical user journeys (minimal count)

### Pre-Commit
- [ ] Pre-commit hooks pass
- [ ] No TODO comments without issue numbers
- [ ] All changes committed on feature branch
</verification_checklist>

<integration>
**This skill calls (in order):**
1. `uwm-business-service-dev:create-v3-service` - Phase 1: New service provisioning
2. `uwm-business-service-dev:design-api` - Phase 2: API design and planning
3. `uwm-business-service-dev:implement-feature` - Phase 3: TDD implementation
4. `uwm-business-service-dev:integrate-infrastructure` - Phase 4: Infrastructure setup
5. `uwm-business-service-dev:test-strategy` - Phase 5: Integration/contract/E2E tests
6. `uwm-business-service-dev:prepare-deployment` - Phase 6: CI/CD preparation

**This skill works with:**
- `hyperpowers:brainstorming` - For refining requirements before starting development
- `hyperpowers:test-driven-development` - During Phase 3 implementation
- `hyperpowers:verification-before-completion` - Before claiming work is done

**This skill is called by:**
- Developers directly (primary entry point for all v3 backend work)
- The orchestrator is invoked via `uwm-business-service-dev:develop-business-service`

**Prerequisites:**
- `uwm-enterprise-mcp` plugin must be installed (provides Bitbucket, Confluence, Jira, Dynatrace tooling)
</integration>

<resources>
**UWM Standards Documentation:**
- PII/NPI Masking: https://kb.uwm.com/display/CODE/Masking+Personally+Identifiable+Information+%28PII%29+and+Nonpublic+Personal+Information+%28NPI%29+in+Logs
- Testing Bible: https://kb.uwm.com/display/TESTAUTO/Test+Automation
- REST API Standard: https://kb.uwm.com/display/ITSTD/HTTP+API+Must+Follow+ReST
- API Security: https://kb.uwm.com/display/ITSTD/API+Security+Standard
- Code Coverage: https://kb.uwm.com/pages/viewpage.action?pageId=1425571276
- Secure Coding: https://kb.uwm.com/display/ITSTD/Secure+Coding+Standard
- Security Logging: https://kb.uwm.com/display/ITSTD/Security+Logging+Standard
- GUP Onboarding: https://kb.uwm.com/display/GUP/Global+User+Passport%3A+V3+Service+Onboarding+Guide+v1.0
- Keystone: https://kb.uwm.com/display/Keystone/Keystone+System+Design

**Verified UWM Package Names:**
- `UWMC.Library.User.Passport` - GUP authentication
- `UWMC.Library.Logging` - Structured logging with PII/NPI masking attributes
- `UWMC.Library.Messaging.Kafka` - Kafka producer/consumer integration
- `UWMC.Vault` - HashiCorp Vault secret management
- `UWMC.Library.FeatureFlags` - Feature flag integration (Harness)
- `AutoMapper` - Object mapping
- `FluentValidation.AspNetCore` - Request validation
- `Microsoft.EntityFrameworkCore.SqlServer` - EF Core for SQL Server

**UWM Docker Base Images:**
- Build: `artifacts.uwm.com/build-images/uwm-dotnet-sdk-sonar:{version}-redhat`
- Runtime: `artifacts.uwm.com/build-images/uwm-aspnet-runtime:{version}-redhat`

**Reference Services (on Bitbucket):**
- `cell-keystone` (GGF project) - .NET 10.0, modern Program.cs pattern
- `cell-biz-broker-preferences` (Bitbucket) - .NET 8.0, Kafka + Hangfire + CosmosDB
- `cell-biz-borrower` - Data service pattern
- `cell-biz-condition` - Business service with rules engine

**When stuck:**
- Keystone issues → Contact Keystone team on Microsoft Teams
- GUP integration → Check GUP Confluence space or Teams channel
- Testing questions → Testing Support channels on Microsoft Teams
- Standards questions → Software Development Standards Council (SDSC)
</resources>
