---
name: test-strategy
description: Use when adding integration, contract, and E2E tests after functional code is written - TestContainers, WireMock, PactFlow, minimal E2E smoke tests
---

<skill_overview>
Guides the creation of non-unit tests for v3 business services AFTER functional code and unit tests are written and passing. Covers hermetic integration tests using TestContainers with UWMC.Library.Testing.MsSql (DbFixture), WireMock for external HTTP service isolation, PactFlow for OAS-based bi-directional contract testing, and minimal E2E smoke tests. The testing pyramid is 80% unit / 15% integration / 5% E2E. Integration tests MUST use real containerized dependencies (not mocks), test through public API endpoints only, and organize fixtures with xUnit CollectionDefinitions.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Test infrastructure patterns (TestContainers via UWMC.Library.Testing.*, CollectionDefinitions, Dependencies/ folder, WebApplicationFixture) are rigid. Specific test scenarios and assertion strategies adapt to business requirements. E2E count must be minimal (5% of total).
</rigidity_level>

<quick_reference>

| Test Type | Tool / Package | Purpose | Distribution |
|-----------|---------------|---------|-------------|
| Integration (hermetic) | `UWMC.Library.Testing.MsSql` + `WireMock` | Verify component interactions via real containers | 15% |
| Contract | `UWMC.Library.Testing.PactFlow` | OAS-based bi-directional contract verification | Part of integration |
| E2E Smoke | RestSharp / TestKube | Validate CUJs after deployment | 5% |

**Integration test infrastructure mapping:**

| Dependency | Test Double | Package |
|-----------|-------------|---------|
| SQL Database | TestContainers SQL Server | `UWMC.Library.Testing.MsSql` |
| Cosmos DB | Azurite emulator | `UWMC.Library.Testing.CosmosDb` |
| Redis | TestContainers Redis | `UWMC.Library.Testing.Redis` |
| Kafka | TestContainers Kafka | `UWMC.Library.Testing.Kafka` |
| External HTTP APIs | WireMock | `UWMC.Library.Testing.WireMock` |
| GUP Auth | Mock IPolicyEvaluator | Hand-written (copy pattern below) |
| Feature Flags | Mock IFeatureFlagManager | Moq (same as unit tests) |

</quick_reference>

<when_to_use>
- After functional code and unit tests are written and passing (Phase 3 complete)
- Setting up hermetic integration test infrastructure for a v3 service
- Adding OAS-based contract tests with PactFlow
- Creating E2E smoke tests for critical user journeys
- NOT for: Unit tests (use implement-feature), API design (use design-api)
- NOT for: Stateless services with no infrastructure dependencies — use WebApplicationFactory with mocked services instead of full TestContainers
</when_to_use>

<the_process>

## 0. Prerequisites

Before starting integration tests:
- [ ] Functional code is implemented and unit tests pass (Phase 3)
- [ ] Infrastructure is configured (Phase 4 — auth, database, Kafka)
- [ ] `public partial class Program;` at end of Program.cs (required for WebApplicationFactory)
- [ ] Docker Desktop or Docker Engine installed (required for TestContainers)

## 1. Create Integration Test Project

### Project Structure

```
test/
├── {ServiceName}.UnitTests/           (already exists from Phase 3)
│   └── {ServiceName}.UnitTests.csproj
└── {ServiceName}.IntegrationTests/
    ├── {ServiceName}.IntegrationTests.csproj
    ├── Dependencies/
    │   ├── Authentication/
    │   │   └── MockAuthPolicyEvaluator.cs
    │   ├── TestContainer/
    │   │   └── ServiceDbFixture.cs
    │   ├── WireMockServer/
    │   │   └── ServiceMockServer.cs
    │   ├── FeatureFlags/
    │   │   └── FeatureFlagFixture.cs (if applicable)
    │   └── DateTimeFixture/ (if applicable)
    ├── WebApplication/
    │   ├── WebApplicationFixture.cs
    │   └── WebApplicationFixtureCollection.cs
    ├── Tests/
    │   ├── ConditionEndpointTests.cs
    │   └── BorrowerEndpointTests.cs
    ├── PactProviderTests/
    │   └── ProviderApiTests.cs
    ├── TestData/
    │   └── *.json
    └── xunit.runner.json
```

### .csproj Configuration

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Core test frameworks -->
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />
    <PackageReference Include="xunit" Version="2.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.*" />

    <!-- UWM Testing Libraries -->
    <PackageReference Include="UWMC.Library.Testing.AspNetCore" Version="5.*" />
    <PackageReference Include="UWMC.Library.Testing.MsSql" Version="5.*" />
    <PackageReference Include="UWMC.Library.Testing.WireMock" Version="5.*" />
    <PackageReference Include="UWMC.Library.Testing.PactFlow" Version="3001.*" />

    <!-- Add per infrastructure needs -->
    <!-- <PackageReference Include="UWMC.Library.Testing.Kafka" Version="5.*" /> -->
    <!-- <PackageReference Include="UWMC.Library.Testing.Redis" Version="5.*" /> -->
    <!-- <PackageReference Include="UWMC.Library.Testing.CosmosDb" Version="5.*" /> -->

    <!-- HTTP client for tests -->
    <PackageReference Include="RestSharp" Version="112.*" />

    <!-- Snapshot testing -->
    <PackageReference Include="Verify.Xunit" Version="*" />

    <!-- Assertions -->
    <PackageReference Include="CompareNETObjects" Version="4.*" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\{ServiceName}\{ServiceName}.csproj" />
  </ItemGroup>

  <!-- Copy test data to output -->
  <ItemGroup>
    <None Update="TestData\**\*">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
```

### xunit.runner.json

```json
{
  "$schema": "https://xunit.net/schema/current/xunit.runner.schema.json",
  "diagnosticMessages": false
}
```

## 2. Create Dependency Fixtures

Each infrastructure dependency gets its own fixture class in the `Dependencies/` folder. Containers are expensive — pass them via CollectionDefinition. WireMock is cheap — new it up directly.

### Database Fixture (UWMC.Library.Testing.MsSql)

```csharp
// Dependencies/TestContainer/ServiceDbFixture.cs
using UWMC.Library.Testing.MsSql;

public class ServiceDbFixture : DbFixture<YourDbContext>
{
    public ServiceDbFixture(IMessageSink messageSink)
        : base(messageSink,
            password: "P@ssw0rd123!",
            containerName: "SERVICE_SQL",
            dbName: "YourServiceDb")
    { }

    public void ConfigureConfiguration(IConfigurationBuilder configBuilder)
    {
        // Override connection string to point at TestContainer
        ConnectionStrings.SetConnectionString("YourDb", ConnectionString);
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();
        // Run seed scripts if needed
        // await MigrateSqlScriptsAsync(Path.Combine("Dependencies", "Scripts"));
    }
}
```

### WireMock Fixture (UWMC.Library.Testing.WireMock)

```csharp
// Dependencies/WireMockServer/ServiceMockServer.cs
using UWMC.Library.Testing.WireMock;

public class ServiceMockServer : IAsyncLifetime
{
    public UwmcWireMockServer MockServer { get; }

    public ServiceMockServer(IMessageSink messageSink)
    {
        MockServer = new UwmcWireMockServer(
            new UwmcWireMockServerOptions
            {
                UseProxy = false,  // Hermetically sealed
                UseSsl = false
            },
            messageSink);
    }

    public void ConfigureConfiguration(IConfigurationBuilder configBuilder)
    {
        // Redirect downstream service URLs to WireMock
        MockServer.ReplaceConfigurationHost(
            configBuilder,
            "DownstreamServices:ConditionApi",
            "CONDITION-SERVICE");
    }

    public Task InitializeAsync() => MockServer.StartAsync();
    public Task DisposeAsync() => MockServer.StopAsync();
}
```

### Mock Auth Policy Evaluator

This is the standard pattern for bypassing GUP auth in integration tests. No library provides this — each service implements its own:

```csharp
// Dependencies/Authentication/MockAuthPolicyEvaluator.cs
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;

public class MockAuthPolicyEvaluator : IPolicyEvaluator
{
    public string DestinyId { get; set; } = "1449989";
    public string Email { get; set; } = "testuser@uwmco.com";
    public string Name { get; set; } = "Test User";
    public PolicyAuthorizationResult AuthorizationResult { get; set; }
        = PolicyAuthorizationResult.Success();

    public Task<AuthenticateResult> AuthenticateAsync(
        AuthorizationPolicy policy, HttpContext context)
    {
        var claims = new[]
        {
            new Claim("DestinyId", DestinyId),
            new Claim(ClaimTypes.Email, Email),
            new Claim(ClaimTypes.Name, Name),
        };

        var identity = new ClaimsIdentity(claims, "Bearer");
        context.User = new ClaimsPrincipal(identity);

        var ticket = new AuthenticationTicket(
            context.User,
            new AuthenticationProperties(),
            JwtBearerDefaults.AuthenticationScheme);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }

    public Task<PolicyAuthorizationResult> AuthorizeAsync(
        AuthorizationPolicy policy,
        AuthenticateResult authenticationResult,
        HttpContext context,
        object resource)
    {
        return Task.FromResult(AuthorizationResult);
    }
}
```

## 3. Create WebApplicationFixture

The WebApplicationFixture is the central orchestrator that coordinates all dependency fixtures:

```csharp
// WebApplication/WebApplicationFixture.cs
using UWMC.Library.Testing.AspNetCore;

public sealed class WebApplicationFixture : IWebApplicationFixture<Program>, IAsyncLifetime
{
    private readonly IMessageSink _messageSink;

    // Dependency fixtures
    public ServiceDbFixture DbFixture { get; }
    public ServiceMockServer WireMock { get; }
    public MockAuthPolicyEvaluator AuthFixture { get; }

    // The factory for creating test HTTP clients
    public MinimalWebApplicationFactory<Program> Factory { get; private set; }

    public WebApplicationFixture(IMessageSink messageSink)
    {
        _messageSink = messageSink;
        DbFixture = new ServiceDbFixture(messageSink);
        WireMock = new ServiceMockServer(messageSink);
        AuthFixture = new MockAuthPolicyEvaluator();
    }

    public async Task InitializeAsync()
    {
        // Start containers in parallel (expensive resources)
        await Task.WhenAll(
            DbFixture.InitializeAsync(),
            WireMock.InitializeAsync()
        );

        // Create the web application factory after containers are ready
        Factory = new MinimalWebApplicationFactory<Program>(
            _messageSink,
            ConfigureServices,
            ConfigureConfiguration,
            useVault: false);
    }

    private void ConfigureServices(IServiceCollection services)
    {
        // Replace auth with mock
        services.RemoveAll<IPolicyEvaluator>();
        services.AddSingleton<IPolicyEvaluator>(AuthFixture);
    }

    private void ConfigureConfiguration(IConfigurationBuilder configBuilder)
    {
        // Point infrastructure at test doubles
        DbFixture.ConfigureConfiguration(configBuilder);
        WireMock.ConfigureConfiguration(configBuilder);

        // Disable Vault in tests
        configBuilder.AddInMemoryCollection(new Dictionary<string, string>
        {
            { "UseVault", "false" }
        });
    }

    public async Task DisposeAsync()
    {
        Factory?.Dispose();
        await WireMock.DisposeAsync();
        await DbFixture.DisposeAsync();
    }
}
```

### Collection Definition

```csharp
// WebApplication/WebApplicationFixtureCollection.cs
[CollectionDefinition(nameof(WebApplicationFixtureCollection))]
public class WebApplicationFixtureCollection
    : ICollectionFixture<WebApplicationFixture>;
```

## 4. Write Integration Tests

All test classes use the `[Collection]` attribute to share the WebApplicationFixture:

```csharp
// Tests/ConditionEndpointTests.cs
[Collection(nameof(WebApplicationFixtureCollection))]
public class ConditionEndpointTests
{
    private readonly WebApplicationFixture _fixture;
    private readonly ITestOutputHelper _output;

    public ConditionEndpointTests(
        WebApplicationFixture fixture,
        ITestOutputHelper output)
    {
        _fixture = fixture;
        _output = output;

        // Register WireMock mappings for this test class
        _fixture.WireMock.MockServer.RegisterPath(
            "Dependencies/WireMockServer/Mappings/ConditionEndpoint");
    }

    [Fact]
    public async Task GetConditions_ValidLoan_Returns200WithConditions()
    {
        // Arrange
        using var client = _fixture.Factory.CreateClient();
        var restClient = new RestClient(client);

        // Act
        var request = new RestRequest("/v1/loan-conditions/1234567890", Method.Get);
        var response = await restClient.ExecuteAsync<ConditionResponse>(request);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(response.Data);
        Assert.Equal("1234567890", response.Data.LoanNumber);
    }

    [Fact]
    public async Task CreateCondition_InvalidRequest_Returns400()
    {
        // Arrange
        using var client = _fixture.Factory.CreateClient();
        var restClient = new RestClient(client);

        var invalidRequest = new CreateConditionRequest
        {
            LoanNumber = "",  // Required field empty
            ConditionName = ""
        };

        // Act
        var request = new RestRequest("/v1/loan-conditions", Method.Post)
            .AddJsonBody(invalidRequest);
        var response = await restClient.ExecuteAsync(request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetConditions_Unauthorized_Returns401()
    {
        // Arrange — configure auth to fail
        _fixture.AuthFixture.AuthorizationResult =
            PolicyAuthorizationResult.Forbid();

        using var client = _fixture.Factory.CreateClient();
        var restClient = new RestClient(client);

        // Act
        var request = new RestRequest("/v1/loan-conditions/1234567890", Method.Get);
        var response = await restClient.ExecuteAsync(request);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

        // Reset auth for other tests
        _fixture.AuthFixture.AuthorizationResult =
            PolicyAuthorizationResult.Success();
    }
}
```

### Test Rules

- **Call public API endpoints only** — Use `RestClient` via `Factory.CreateClient()`. Never call internal methods or database directly.
- **Verify through the API** — If you save data via POST, retrieve it via GET to verify. Do not query the database.
- **WireMock mappings** — Store as JSON files in `Dependencies/WireMockServer/Mappings/` and register per test class.
- **Test data** — Store as JSON files in `TestData/` with `CopyToOutputDirectory: PreserveNewest`.

## 5. Set Up PactFlow Contract Tests

**Package:** `UWMC.Library.Testing.PactFlow` (3000.x / 3001.x)

UWM uses **OAS-based bi-directional** contract testing. This means:
1. Integration tests generate an OpenAPI spec from the running app
2. A verifier file is generated alongside
3. Both are published to PactFlow.io for cross-service contract verification

### Provider-Side Tests

```csharp
// PactProviderTests/ProviderApiTests.cs
[Collection(nameof(WebApplicationFixtureCollection))]
public class ProviderApiTests
{
    private readonly WebApplicationFixture _fixture;
    private readonly ITestOutputHelper _output;
    private const string OpenApi = "openapi.yaml";
    private const string Verifier = "verifier.txt";

    public ProviderApiTests(
        WebApplicationFixture fixture,
        ITestOutputHelper output)
    {
        _fixture = fixture;
        _output = output;
    }

    [Fact]
    public async Task GenerateOasYamlContract()
    {
        var client = _fixture.Factory.CreateClient();
        Assert.True(await _fixture.PactFixture
            .GenerateOpenApiSpec(client, OpenApi));
    }

    [Fact]
    public async Task GenerateVerifierFiles()
    {
        Assert.True(await _fixture.PactFixture
            .GenerateBiDirectionalVerifierFile(Verifier));
    }
}
```

### PactFlow + WireMock Integration

The PactFixture links to WireMock, allowing consumer contracts to validate against WireMock mappings:

```csharp
// In WebApplicationFixture constructor
PactFixture = new PactFixture(new PactSettings { ... });
WireMock = new ServiceMockServer(PactFixture.PactSettings, messageSink);
```

### CD Readiness Requirement

Per UWM's Continuous Deployment Readiness guide, contract testing "should block deploys." PactFlow verification runs in the CI pipeline and must pass before merge.

## 6. Create E2E Smoke Tests (Minimal)

E2E smoke tests are 5% of the total test count. They run against deployed environments (not TestContainers) and verify only critical user journeys.

### Approach: Separate Smoke Test Project or TestKube

Per UWM's CD Readiness guide, smoke tests run in TestKube after deployment. They are typically in a separate project or configuration.

```csharp
// SmokeTests/ConditionApiSmokeTests.cs
public class ConditionApiSmokeTests
{
    private readonly RestClient _client;

    public ConditionApiSmokeTests()
    {
        var baseUrl = Environment.GetEnvironmentVariable("API_BASE_URL")
            ?? "https://cell-biz-conditions.int.uwm.com";
        _client = new RestClient(baseUrl);
    }

    [Fact]
    public async Task HealthCheck_ReturnsOk()
    {
        var request = new RestRequest("/api/healthz", Method.Get);
        var response = await _client.ExecuteAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetConditions_KnownLoan_ReturnsSuccess()
    {
        var request = new RestRequest("/v1/loan-conditions/SMOKE_TEST_LOAN", Method.Get);
        // Add auth token for deployed environment
        request.AddHeader("Authorization", $"Bearer {GetTestToken()}");
        var response = await _client.ExecuteAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

**E2E test rules:**
- Test ONLY critical user journeys (happy path)
- Do NOT test edge cases in E2E (that's what unit and integration tests are for)
- Keep count minimal — each E2E test is expensive to maintain
- Run after deployment, not during build

## 7. Exclude Non-Unit Tests from Stryker

Stryker.NET mutation testing runs ONLY on unit tests. Configure `stryker-config.json` to exclude integration and E2E projects:

```json
{
  "$schema": "https://raw.githubusercontent.com/stryker-mutator/stryker-net/master/src/Stryker.Core/Stryker.Core/stryker-config.schema.json",
  "stryker-config": {
    "project": "src/{ServiceName}/{ServiceName}.csproj",
    "test-projects": [
      "test/{ServiceName}.UnitTests/{ServiceName}.UnitTests.csproj"
    ],
    "reporters": ["html", "json", "dots"],
    "thresholds": {
      "high": 90,
      "low": 80,
      "break": 80
    },
    "ignore-methods": [
      "AddUSFSLogging",
      "AddUSFSHealthCheck",
      "AddVaultSecrets"
    ]
  }
}
```

**Key:** The `test-projects` field explicitly lists ONLY unit test projects. Integration and E2E test projects are NOT included.

## 8. Configure Test Pipeline Order

Tests run in a specific order in CI/CD:

1. **Unit tests** (fast, fail-fast) — `dotnet test {ServiceName}.UnitTests.csproj`
2. **Stryker mutation testing** — `dotnet stryker` (unit tests only)
3. **Integration tests** (slower, requires Docker) — `dotnet test {ServiceName}.IntegrationTests.csproj`
4. **Contract verification** (PactFlow) — Runs as part of integration tests
5. **E2E smoke tests** (after deployment) — Runs in TestKube

## 9. UWMC.Library.Testing.* Package Reference

The Test Automation team (TSTATO project on Bitbucket) maintains an extensive testing library ecosystem. Use the specific packages your service needs:

| Package | Purpose | When to Use |
|---------|---------|-------------|
| `UWMC.Library.Testing.AspNetCore` | WebApplicationFactory, `MinimalWebApplicationFactory<T>`, logging helpers | Always — foundation for all integration tests |
| `UWMC.Library.Testing.MsSql` | `DbFixture<T>` for SQL Server TestContainers | When service has SQL database |
| `UWMC.Library.Testing.WireMock` | `UwmcWireMockServer` with post-processors | When service calls external HTTP APIs |
| `UWMC.Library.Testing.PactFlow` | OAS contract generation, `PactFixture` | For contract testing (CD readiness requirement) |
| `UWMC.Library.Testing.Kafka` | `KafkaFixtureV2`, `BaseTestConsumerV2` | When service produces/consumes Kafka events |
| `UWMC.Library.Testing.Redis` | `RedisFixture` for Redis TestContainers | When service uses Redis cache |
| `UWMC.Library.Testing.CosmosDb` | `CosmosDbFixture` for Cosmos emulator | When service uses Cosmos DB |
| `UWMC.Library.Testing.EntityFrameworkCore` | In-memory DB for simpler tests | For unit-level EF Core tests (not integration) |
| `UWMC.Library.Testing.RestSharp` | RestSharp extensions, Verify helpers | For enhanced RestSharp assertions |

</the_process>

<examples>

<example>
<scenario>Setting up hermetic integration tests for a new business service with SQL database and downstream HTTP dependency</scenario>

**Step 1: Create project** — `test/{ServiceName}.IntegrationTests/`

**Step 2: Create fixtures**

```csharp
// Dependencies/TestContainer/ConditionDbFixture.cs
public class ConditionDbFixture : DbFixture<ConditionDbContext>
{
    public ConditionDbFixture(IMessageSink sink)
        : base(sink, password: "P@ssw0rd123!", containerName: "COND_SQL", dbName: "ConditionDb") { }

    public void ConfigureConfiguration(IConfigurationBuilder config)
        => ConnectionStrings.SetConnectionString("ConditionDb", ConnectionString);
}

// Dependencies/Authentication/MockAuthPolicyEvaluator.cs
// (use the standard IPolicyEvaluator pattern from Section 2)

// Dependencies/WireMockServer/ConditionMockServer.cs
public class ConditionMockServer : IAsyncLifetime
{
    public UwmcWireMockServer MockServer { get; }
    public ConditionMockServer(IMessageSink sink)
    {
        MockServer = new UwmcWireMockServer(
            new UwmcWireMockServerOptions { UseProxy = false }, sink);
    }
    public void ConfigureConfiguration(IConfigurationBuilder config)
        => MockServer.ReplaceConfigurationHost(config, "DownstreamServices:BorrowerApi", "BORROWER");
    public Task InitializeAsync() => MockServer.StartAsync();
    public Task DisposeAsync() => MockServer.StopAsync();
}
```

**Step 3: Create WebApplicationFixture** — Orchestrate all fixtures, start containers in parallel, configure services and configuration.

**Step 4: Write tests**
```csharp
[Collection(nameof(WebApplicationFixtureCollection))]
public class ConditionEndpointTests
{
    [Fact]
    public async Task CreateAndRetrieveCondition_Roundtrip_Succeeds()
    {
        using var client = _fixture.Factory.CreateClient();
        var restClient = new RestClient(client);

        // Create
        var createRequest = new RestRequest("/v1/loan-conditions", Method.Post)
            .AddJsonBody(new { loanNumber = "1234567890", name = "Appraisal", priority = 1 });
        var createResponse = await restClient.ExecuteAsync<ConditionResponse>(createRequest);
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        // Retrieve through API (not database)
        var getRequest = new RestRequest($"/v1/loan-conditions/1234567890", Method.Get);
        var getResponse = await restClient.ExecuteAsync<List<ConditionResponse>>(getRequest);
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        Assert.Contains(getResponse.Data, c => c.Name == "Appraisal");
    }
}
```
</example>

<example>
<scenario>Adding integration tests to a stateless service (no database, no Kafka)</scenario>

Stateless services (like rules engines or calculation services) don't need TestContainers. Use WebApplicationFactory with mocked services directly:

```csharp
// WebApplication/WebApplicationFixture.cs — simplified for stateless
public sealed class WebApplicationFixture : IWebApplicationFixture<Program>
{
    public MinimalWebApplicationFactory<Program> Factory { get; }
    public MockAuthPolicyEvaluator AuthFixture { get; }

    public WebApplicationFixture(IMessageSink messageSink)
    {
        AuthFixture = new MockAuthPolicyEvaluator();
        Factory = new MinimalWebApplicationFactory<Program>(
            messageSink, ConfigureServices, ConfigureConfiguration, useVault: false);
    }

    private void ConfigureServices(IServiceCollection services)
    {
        services.RemoveAll<IPolicyEvaluator>();
        services.AddSingleton<IPolicyEvaluator>(AuthFixture);
    }

    private void ConfigureConfiguration(IConfigurationBuilder config)
    {
        config.AddInMemoryCollection(new Dictionary<string, string>
        {
            { "UseVault", "false" }
        });
    }
}

// Tests/RuleEvaluationTests.cs
[Collection(nameof(WebApplicationCollection))]
public class RuleEvaluationTests
{
    [Fact]
    public async Task EvaluateRules_ValidInput_ReturnsResults()
    {
        using var client = _fixture.Factory.CreateClient();
        var restClient = new RestClient(client);

        var request = new RestRequest("/v1/borrower-validation/run-rules", Method.Post)
            .AddJsonBody(new { loanNumber = "1234567890" });
        var response = await restClient.ExecuteAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

No TestContainers needed — the service is stateless and has no infrastructure dependencies beyond HTTP.
</example>

</examples>

<critical_rules>

1. **NEVER mock databases in integration tests** — Use TestContainers with `UWMC.Library.Testing.MsSql` (DbFixture). Mocking defeats the purpose of integration testing.

2. **Always test through public API endpoints** — Use `RestClient` via `Factory.CreateClient()`. Never call internal methods or query the database directly. If you POST data, use GET to verify it.

3. **Always use CollectionDefinitions** — Containers are expensive. Share them via `[CollectionDefinition]` and `ICollectionFixture<WebApplicationFixture>`. Never create containers per-test.

4. **Never run Stryker on integration/E2E tests** — Mutation testing applies only to unit tests. The `test-projects` field in `stryker-config.json` must list only unit test projects.

5. **Minimize E2E test count** — E2E tests are 5% of total. Only test critical user journeys (happy path). Edge cases belong in unit and integration tests.

6. **WireMock is cheap, containers are expensive** — New up WireMock in constructors. Pass containers via DI (CollectionDefinition). Start containers in parallel via `Task.WhenAll`.

7. **Auth bypass via IPolicyEvaluator** — Replace `IPolicyEvaluator` in test services, not `IAuthorizationHandler`. The IPolicyEvaluator pattern allows testing auth failure scenarios by toggling `AuthorizationResult`.

8. **Disable Vault in tests** — Set `"UseVault": false` via `IConfigurationBuilder.AddInMemoryCollection`. Test infrastructure provides its own secrets.

9. **Integration tests come AFTER unit tests pass** — Never write integration tests before unit tests. The testing pyramid is 80% unit / 15% integration / 5% E2E.

10. **Stateless services skip TestContainers** — If a service has no database, Kafka, or Redis dependencies, use WebApplicationFactory with mocked services only.

</critical_rules>

<edge_cases>

**Docker not available in CI pipeline:**
TestContainers requires Docker. Ensure CI agents have Docker installed and running. Use `xunit.runner.json` with `diagnosticMessages: false` to reduce pipeline noise.

**Container startup timeout:**
TestContainers may fail to start on slow CI agents. The UWMC.Library.Testing packages handle retries internally, but consider increasing timeout if CI is consistently slow.

**Test data isolation between tests:**
Tests sharing the same WebApplicationFixture share the same database. Either use unique identifiers per test (random loan numbers) or reset data between tests. The `Respawn` package (referenced in some services) can truncate tables between tests.

**WireMock mappings conflict between test classes:**
Each test class calls `MockServer.RegisterPath()` in its constructor. Ensure mapping directories don't conflict. Use test-class-specific subdirectories.

**PactFlow not adopted in all services:**
PactFlow is used by 2 of 3 examined services (borrower, condition) but not all. The CD Readiness guide requires it for deployment certification. Include PactFlow even if your team hasn't used it before.

**Legacy Startup.cs services:**
Use `CustomWebApplicationFactory<Startup>` instead of `MinimalWebApplicationFactory<Program>`. The configuration pattern is the same, but the factory constructor differs.

</edge_cases>

<verification_checklist>

Before completing test strategy:

- [ ] Hermetic integration tests using TestContainers:
  - DbFixture class for SQL/Cosmos containers
  - xUnit CollectionDefinitions to manage container lifecycle
  - WireMock for external HTTP service isolation
  - Mock Auth Policy Evaluator for GUP auth
  - CustomWebApplicationFactory or MinimalWebApplicationFactory for app hosting
  - Tests call public API endpoints only (client perspective)
- [ ] Contract tests defined (PactFlow):
  - OAS YAML generated from running application
  - Verifier file generated
  - Provider verification configured
- [ ] E2E smoke tests (minimal count):
  - Critical user journeys only
  - API smoke tests via RestSharp
- [ ] All test projects exclude integration/E2E from Stryker mutation testing
- [ ] `public partial class Program;` at end of Program.cs
- [ ] `Dependencies/` folder contains all test infrastructure fixtures
- [ ] Tests use Assert.* + CompareNETObjects (not FluentAssertions)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-business-service` orchestrator (Phase 5)
- Direct invocation via `/uwm-business-service-dev:test-strategy`

**This skill should be used after:**
- `integrate-infrastructure` (Phase 4) — infrastructure must be configured before testing it

**This skill should be used before:**
- `prepare-deployment` (Phase 6) — tests must pass before deployment

**Related skills:**
- `implement-feature` — writes the unit tests (Phase 3) that run before integration tests
- `integrate-infrastructure` — configures the infrastructure these tests validate

</integration>

<resources>

**UWM packages referenced:**
- `UWMC.Library.Testing.AspNetCore` — WebApplicationFactory, MinimalWebApplicationFactory
- `UWMC.Library.Testing.MsSql` — DbFixture for SQL Server TestContainers
- `UWMC.Library.Testing.WireMock` — UwmcWireMockServer with post-processors
- `UWMC.Library.Testing.PactFlow` — OAS contract generation, PactFixture
- `UWMC.Library.Testing.Kafka` — KafkaFixtureV2, BaseTestConsumerV2
- `UWMC.Library.Testing.Redis` — RedisFixture
- `UWMC.Library.Testing.CosmosDb` — CosmosDbFixture
- `UWMC.Library.Testing.EntityFrameworkCore` — In-memory DB helpers
- `RestSharp` 112.x — HTTP client for test requests
- `Verify.Xunit` — Snapshot-based assertions
- `CompareNETObjects` 4.x — Deep object comparison

**Confluence references:**
- "Test Pyramid" (TESTAUTO) — 80/15/5 distribution
- "Hermetic Integration Testing Flow" (TESTAUTO) — Definitive integration test guide
- "Continuous Deployment Readiness" (CICD) — CD certification requirements including PactFlow and smoke tests

**Reference services:**
- `cell-biz-borrower` (EH) — Full integration test suite with TestContainers, WireMock, PactFlow, Kafka
- `cell-biz-condition` (EH) — Stateless service with WebApplicationFactory-only integration tests
- `cell-biz-broker-preferences` (EH) — SQL + Cosmos + Kafka + WireMock integration tests

**Testing library source:**
- TSTATO project on Bitbucket — 25+ testing libraries maintained by Test Automation team

</resources>
