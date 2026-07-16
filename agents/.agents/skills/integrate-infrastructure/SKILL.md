---
name: integrate-infrastructure
description: Use when connecting a v3 service to infrastructure - GUP auth, Kafka (UWMC.Library.Messaging.Kafka), EF Core, Vault (UWMC.Vault), feature flags (UWMC.Library.FeatureFlags)
---

<skill_overview>
Guides integration of v3 business services with UWM infrastructure components. Covers two authentication paradigms (legacy ADFS JWT Bearer for business services, UWMC.Library.User.Passport for BFF/UI services), secret management via UWMC.Vault, database access via Entity Framework Core, Kafka messaging via UWMC.Library.Messaging.Kafka, and feature flags via UWMC.Library.FeatureFlags. The middleware ordering and DI registration sequence in Program.cs is critical — incorrect ordering causes silent auth failures or missing secrets.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Program.cs registration order is rigid (Vault FIRST, then services, then auth). Middleware pipeline order is rigid. One-service-per-database rule is rigid. Kafka consumer in separate repo is rigid. Package names are exact.
</rigidity_level>

<quick_reference>

| Integration | Package | Key Setup | Required? |
|-------------|---------|-----------|-----------|
| Auth (Biz Service) | `USFS.Library.Authentication` | `AddUsfsAuthenticationServices()`, `UseUsfsAuthentication()` | YES |
| Auth (BFF/UI) | `UWMC.Library.User.Passport` | `AddPassport()`, `UsePassport()`, `MapPassportEndpoints()` | YES (BFF only) |
| Vault | `UWMC.Vault` | `builder.AddVaultSecrets()` — MUST be FIRST | YES |
| Database | `Microsoft.EntityFrameworkCore.SqlServer` | `AddDbContext<T>()` with Vault credentials | If DB needed |
| Kafka | `UWMC.Library.Messaging.Kafka` | `AddUWMCMessagingKafka()`, separate consumer repo | If events needed |
| Feature Flags | `UWMC.Library.FeatureFlags.Split` | `AddUWMCFeatureFlags()` with Split/Harness provider | If gradual rollout |
| Health Check | `USFS.Library.HealthCheck` | `AddUSFSHealthCheck()`, `UseUSFSHealthCheck()` | YES |
| Logging | `USFS.Library.Logging` | `AddUSFSLogging()` | YES |

</quick_reference>

<when_to_use>
- Setting up authentication on a new or existing v3 service
- Adding Kafka producer or consumer capabilities
- Configuring database access with Entity Framework Core
- Setting up Vault integration for secrets management
- Adding feature flag support
- Wiring up a complete Program.cs for a new v3 service
- NOT for: API design (use design-api), business logic implementation (use implement-feature), test setup (use test-strategy)
</when_to_use>

<the_process>

## 0. Determine Service Type

Before configuring infrastructure, identify which service type you are building. This determines the authentication paradigm:

| Service Type | Repo Pattern | Auth Paradigm | Auth Package |
|-------------|-------------|---------------|-------------|
| Business Service | `cell-biz-{name}` | ADFS JWT Bearer | `USFS.Library.Authentication` |
| Kafka Consumer | `cell-biz-{name}-consumer` | Service account / no HTTP auth | N/A (background worker) |
| BFF | `cell-bff-{name}` or `cell-biz-bff-{name}` | Passport (cookie + bearer) | `UWMC.Library.User.Passport` |
| UI Service | `cell-ui-{name}` | Passport endpoints | `UWMC.Library.User.Passport` |

**Key discovery from real services:** Most business services (cell-biz-*) do NOT use UWMC.Library.User.Passport. They use ADFS JWT Bearer authentication via `USFS.Library.Authentication`. The Passport library is primarily used by BFF and UI-facing services that need cookie-based auth and login endpoints.

## 1. Program.cs Registration Order (Critical)

The order of registration in Program.cs matters. Vault MUST come first because subsequent registrations (database, Kafka) read secrets from configuration that Vault populates.

### Business Service Pattern (cell-biz-*)

This is the pattern used by cell-biz-borrower, cell-biz-condition, and cell-keystone:

```csharp
using USFS.Library.Logging;
using USFS.Library.HealthCheck;

var builder = WebApplication.CreateBuilder(args);

// ── 1. VAULT (MUST BE FIRST) ──────────────────────────────────
// Vault populates configuration with secrets (DB passwords, API keys).
// Everything below may depend on these secrets.
if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();

// ── 2. CONNECTION STRING OVERWRITE ────────────────────────────
// Some services overwrite connection strings after Vault loads them.
// This is for rotating credential patterns (see Database section).
ConnectionStrings.OverwriteConfiguration(builder.Configuration);

// ── 3. LOGGING ────────────────────────────────────────────────
builder.Services.AddUSFSLogging(builder.Configuration);

// ── 4. APPLICATION SERVICES ───────────────────────────────────
// AutoMapper, validators, repositories, orchestrators
builder.Services.AddAutoMapper(typeof(Program).Assembly);
builder.Services.AddTransient<IConditionRepository, ConditionRepository>();
builder.Services.AddTransient<IConditionOrchestrator, ConditionOrchestrator>();

// ── 5. KAFKA (if needed) ──────────────────────────────────────
var username = builder.Configuration["KafkaServiceAccount:Username"];
var pw = builder.Configuration["KafkaServiceAccount:Password"];
builder.Services.AddUWMCMessagingKafka(
    builder.Configuration, $"{username}@shoremortgage.com", pw);

// ── 6. HEALTH CHECK ──────────────────────────────────────────
builder.Services.AddUSFSHealthCheck(builder.Configuration);

// ── 7. AUTH ───────────────────────────────────────────────────
builder.Services.AddUsfsAuthenticationServices(builder.Configuration);
builder.Services.AddControllers();
builder.Services.AddAuthorization();

// ── 8. DATABASE ──────────────────────────────────────────────
builder.Services.BindDbContext(builder.Configuration);

// ── 9. FEATURE FLAGS (if needed) ─────────────────────────────
builder.Services.AddUWMCFeatureFlags(ffBuilder =>
{
    var splitSettings = new SplitSettings();
    builder.Configuration.Bind(SplitSettings.BindingLocation, splitSettings);
    ffBuilder.AddSplit("Split", splitSettings);
});
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<IFeatureFlagManagerFactory>().Get("Split"));

var app = builder.Build();

// ── MIDDLEWARE PIPELINE (order matters) ───────────────────────
app.UseRouting();
app.UseUsfsAuthentication();           // Auth middleware
app.UseUSFSHealthCheck();              // Health check (anonymous)
app.MapControllers().RequireAuthorization();  // All endpoints require auth
app.UseSqlDatabase<MigrationDbContext>();     // Apply DB migrations
app.UseUWMCMessagingConsumers(true,          // Start Kafka consumers
    typeof(Program).Assembly);

await app.RunAsync();

// REQUIRED: Enables WebApplicationFactory for integration tests
public partial class Program;
```

### BFF/UI Service Pattern (cell-bff-* / cell-ui-*)

This pattern uses UWMC.Library.User.Passport for cookie-based auth with login endpoints:

```csharp
using UWMC.Library.User.Passport.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Vault first (same as biz service)
if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();

// Passport replaces manual auth setup
builder.Services.AddPassport(builder.Configuration);

// Your application services...
builder.Services.AddHttpClient<IDownstreamService, DownstreamService>();

var app = builder.Build();

// UsePassport() internally calls:
//   UseForwardedHeaders(), UseRouting(),
//   UseAuthentication(), UseAuthorization(),
//   PassportLoggingMiddleware
// DO NOT call these manually when using UsePassport().
app.UsePassport();

// MapPassportEndpoints() registers /passport and /login routes
app.MapPassportEndpoints();

app.MapControllers().RequireAuthorization();

app.Run();
public partial class Program;
```

**Passport appsettings.json:**
```json
{
  "Passport": {
    "ApplicationEdgeUrl": "https://your-service.int.uwm.com",
    "CookieDomain": ".uwm.com"
  }
}
```

**Passport authorization attributes:**
```csharp
// AND logic — user must be in ALL required groups
[RequireSecurityGroup("GRP-YourTeam")]

// OR logic — overrides RequireSecurityGroup
[AllowSecurityGroup("GRP-OtherTeam")]

// Role-based (>= v2.23.0)
[RequireOrganizationRole("Broker Admin")]
[RequireExactOrganizationRole("External Broker Admin")]
```

### Dev/Test Auth Bypass

Both patterns support a `NOAUTH` preprocessor directive for local development:

```csharp
#if NOAUTH
    // Skip auth setup entirely for local dev
    builder.Services.AddAuthorization();
#else
    builder.Services.AddUsfsAuthenticationServices(builder.Configuration);
    builder.Services.AddAuthorization();
#endif
```

This is set in the `.csproj` file under a specific build configuration, not in production code.

## 2. Vault Integration

**Package:** `UWMC.Vault`

Vault provides secrets (database credentials, API keys, client secrets) at runtime. It MUST be called first in Program.cs because all other registrations may depend on secrets.

### Setup

```csharp
// Program.cs — MUST be the first builder extension called
if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();
```

The conditional check (`UseVault`) allows disabling Vault in local development and test environments by setting `"UseVault": false` in `appsettings.Development.json`.

### Configuration

```json
// appsettings.json
{
  "UseVault": true,
  "Vault": {
    "Address": "https://vault.uwm.com",
    "RoleName": "cell-biz-your-service"
  }
}

// appsettings.Development.json (disable Vault locally)
{
  "UseVault": false
}
```

### Legacy Pattern

Older services use `USFS.Library.Extensions.Configuration.Secrets`:

```csharp
// Legacy — found in older Startup.cs services
config.AddVault(env.EnvironmentName);
```

For new services, always use `UWMC.Vault` with `builder.AddVaultSecrets()`.

### What Vault Provides

After `AddVaultSecrets()`, these values are available via `IConfiguration`:
- Database credentials: `Configuration["DbRoleName:Username"]`, `Configuration["DbRoleName:Password"]`
- Kafka service account: `Configuration["KafkaServiceAccount:Username"]`, `Configuration["KafkaServiceAccount:Password"]`
- API keys for downstream services
- Client secrets for OAuth/OIDC

**NEVER hardcode or commit secrets.** If a value is sensitive, it belongs in Vault.

## 3. Database (Entity Framework Core)

**Package:** `Microsoft.EntityFrameworkCore.SqlServer`

### One-Service-Per-Database Rule

Each v3 service owns its database exclusively. No other service reads or writes to it.

**Exceptions (same team, same domain only):**
- CQRS pattern (read/write split with separate DbContexts)
- HTTP/Kafka split (cell-biz-{name} and cell-biz-{name}-consumer share the database)

### Registration Patterns

Three patterns exist in production. Use the one that matches your service's credential management:

**Pattern 1: Simple AddDbContext (Windows Auth / Single Credential)**
```csharp
// Used when connection string comes directly from configuration
builder.Services.AddDbContext<YourDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("YourDb")));
```

**Pattern 2: Rotating Credentials via Vault (Keystone Pattern)**
```csharp
// Used when Vault provides rotating username/password separately
var dbRoleName = builder.Configuration["DbRoleName"];
builder.Services.AddDbContext<YourDbContext>(options =>
    options.UseSqlServer(string.Format(
        builder.Configuration.GetConnectionString("Db"),
        dbRoleName,
        builder.Configuration[$"{dbRoleName}:Username"],
        builder.Configuration[$"{dbRoleName}:Password"])));
```

With a connection string template in appsettings:
```json
{
  "ConnectionStrings": {
    "Db": "Server=sql-server.uwm.com;Database=YourDb;User Id={1};Password={2};TrustServerCertificate=True"
  },
  "DbRoleName": "cell-biz-your-service"
}
```

**Pattern 3: Manual DbContextOptionsBuilder**
```csharp
// Used when you need custom configuration (e.g., CosmosDB)
builder.Services.AddDbContext<YourDbContext>((sp, options) =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    options.UseSqlServer(config.GetConnectionString("YourDb"),
        sqlOptions => sqlOptions.EnableRetryOnFailure());
});
```

### DbContext Structure

```csharp
public class YourDbContext : DbContext
{
    public YourDbContext(DbContextOptions<YourDbContext> options)
        : base(options) { }

    public DbSet<Condition> Conditions { get; set; }
    public DbSet<LoanDocument> LoanDocuments { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply all configurations from this assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(YourDbContext).Assembly);
    }
}
```

Entity configurations go in separate files:
```csharp
// Data/Configurations/ConditionConfiguration.cs
public class ConditionConfiguration : IEntityTypeConfiguration<Condition>
{
    public void Configure(EntityTypeBuilder<Condition> builder)
    {
        builder.ToTable("Conditions");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Name).HasMaxLength(200).IsRequired();
    }
}
```

### Migrations

Two migration approaches exist at UWM:

**Redgate Migrations (most common in modern services):**
- Migrations live in versioned folders (e.g., `Migrations/V1__Initial.sql`)
- Applied on startup via `app.UseSqlDatabase<RedgateMigrationDbContext>()`
- Requires `UWMC.Library.Database.Redgate` or similar package

**EF Core Standard Migrations:**
- Generated via `dotnet ef migrations add MigrationName`
- Applied on startup via `context.Database.Migrate()` or `app.UseSqlDatabase<T>()`
- Migration files in standard `Migrations/` folder with timestamp prefixes

### Startup Migration Application

```csharp
// After app.Build(), before app.Run()
app.UseSqlDatabase<YourMigrationDbContext>();
```

## 4. Kafka Messaging

**Package:** `UWMC.Library.Messaging.Kafka` (v3.17.0+)

### Architecture: HTTP/Kafka Split

UWM's v3 pattern requires HTTP API and Kafka consumer to be **separate repositories and deployments**:

| Repo | Purpose | Contains |
|------|---------|----------|
| `cell-biz-{name}` | HTTP API + Kafka **producer** | Controllers, business logic, event publishing |
| `cell-biz-{name}-consumer` | Kafka **consumer** | Message handlers, event processing |

Both repos share the same business domain and may share the same database (same team exception to one-service-per-database rule).

### Producer Setup (in cell-biz-{name})

**Registration:**
```csharp
// Program.cs — after Vault (needs Kafka credentials)
var username = builder.Configuration["KafkaServiceAccount:Username"];
var pw = builder.Configuration["KafkaServiceAccount:Password"];
builder.Services.AddUWMCMessagingKafka(
    builder.Configuration, $"{username}@shoremortgage.com", pw);
```

**Producer class:**
```csharp
public interface ILoanEventProducer
{
    EventReturn PublishLoanUpdated(string loanNumber, LoanUpdatedEvent data);
}

public class LoanEventProducer : ILoanEventProducer
{
    private readonly IMessageProducer<string, LoanUpdatedEvent> _producer;

    public LoanEventProducer(IEventProducerBuilder eventProducerBuilder)
    {
        _producer = eventProducerBuilder
            .CreateMessageProducer<string, LoanUpdatedEvent>("LoanUpdatedProducer");
    }

    public EventReturn PublishLoanUpdated(string loanNumber, LoanUpdatedEvent data)
    {
        return _producer.ProduceMessage(
            new Event<string, LoanUpdatedEvent>
            {
                Key = loanNumber,
                Value = data
            });
    }
}
```

**Registration:**
```csharp
builder.Services.AddTransient<ILoanEventProducer, LoanEventProducer>();
```

### Consumer Setup (in cell-biz-{name}-consumer)

**Message handler:**
```csharp
[MessageHandler("LoanUpdatedConsumer")]
public class LoanUpdatedConsumer : IConsumerHandler<string, LoanUpdatedEvent>
{
    private readonly ILoanProcessor _processor;

    public LoanUpdatedConsumer(ILoanProcessor processor)
    {
        _processor = processor;
    }

    public EventReturn HandleMessage(Event<string, LoanUpdatedEvent> message)
    {
        _processor.ProcessLoanUpdate(message.Key, message.Value);
        return EventReturn.Handled;
    }
}
```

**Consumer startup:**
```csharp
// Program.cs of consumer service
app.UseUWMCMessagingConsumers(true, typeof(Program).Assembly);
await app.RunAsync();
```

### Kafka appsettings.json

```json
{
  "Messaging": {
    "Kafka": [
      {
        "ConnectionName": "CFK",
        "SaslMechanism": "Plain",
        "SecurityProtocol": "SaslSsl",
        "BootstrapServers": "kafka-broker.uwm.com:9093",
        "ClientId": "cell-biz-your-service",
        "GroupId": "cell-biz-your-service-group"
      }
    ],
    "Producers": [
      {
        "ConnectionName": "CFK",
        "TopicName": "your-domain.loan-updated.v1",
        "ProducerClass": "LoanEventProducer"
      }
    ],
    "Consumers": [
      {
        "ConnectionName": "CFK",
        "TopicName": "upstream-domain.event-name.v1",
        "ConsumerClass": "LoanUpdatedConsumer"
      }
    ]
  }
}
```

### Kafka Topic Naming Convention

Topics follow: `{domain}.{event-name}.{version}`
- Example: `borrower.profile-updated.v1`
- Example: `conditions.condition-satisfied.v1`

## 5. Feature Flags

**Modern package:** `UWMC.Library.FeatureFlags.Split` (migrating to Harness)

Three providers exist in production. New services should use Split (or Harness when available):

| Provider | Package | Status |
|----------|---------|--------|
| Split | `UWMC.Library.FeatureFlags.Split` | Current standard |
| Harness | (TBD) | Replacing Split |
| Rollout | `UWMC.Library.FeatureFlags.Rollout` | Legacy, do not use for new services |

### Registration

```csharp
// Program.cs
builder.Services.AddUWMCFeatureFlags(ffBuilder =>
{
    var splitSettings = new SplitSettings();
    builder.Configuration.Bind(SplitSettings.BindingLocation, splitSettings);
    ffBuilder.AddSplit("Split", splitSettings);
});

// Register a singleton for convenient injection
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<IFeatureFlagManagerFactory>().Get("Split"));
```

### Usage in Code

```csharp
public class ConditionOrchestrator
{
    private readonly IFeatureFlagManager _featureFlags;

    public ConditionOrchestrator(IFeatureFlagManager featureFlags)
    {
        _featureFlags = featureFlags;
    }

    public async Task<Result> ProcessCondition(ConditionRequest request)
    {
        var useNewLogic = _featureFlags.GetFeatureFlagValue("use-new-condition-logic");

        if (useNewLogic)
        {
            return await ProcessWithNewLogic(request);
        }
        return await ProcessWithLegacyLogic(request);
    }
}
```

### appsettings.json

```json
{
  "FeatureFlags": {
    "DefaultNamespace": "cell-biz-your-service",
    "FetchInterval": 30,
    "EnableConnection": true
  },
  "Split": {
    "ApiKey": "FROM_VAULT"
  }
}
```

### When to Use Feature Flags

- Gradual rollouts of new business logic
- Kill switches for risky operations
- A/B testing different processing paths
- Environment-specific behavior (without appsettings differences)

### Testing with Feature Flags

In unit tests, mock `IFeatureFlagManager`:
```csharp
var mockFeatureFlags = new Mock<IFeatureFlagManager>(MockBehavior.Strict);
mockFeatureFlags
    .Setup(f => f.GetFeatureFlagValue("use-new-condition-logic"))
    .Returns(true);

var orchestrator = new ConditionOrchestrator(mockFeatureFlags.Object);
```

Test BOTH flag states (on and off) to verify behavior under each path.

## 6. Health Checks

**Package:** `USFS.Library.HealthCheck`

Every v3 service MUST expose a health check endpoint that does NOT require authentication.

```csharp
// Program.cs — registration
builder.Services.AddUSFSHealthCheck(builder.Configuration);

// Program.cs — middleware
app.UseUSFSHealthCheck();
```

Or with a dedicated controller:
```csharp
[ApiController]
[AllowAnonymous]
[ExcludeFromCodeCoverage]
[Route("api/[controller]")]
public class HealthzController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok("Healthy");
}
```

**Key:** Health checks MUST be `[AllowAnonymous]` — Kubernetes probes cannot authenticate.

## 7. Logging and PII/NPI Masking

**Package:** `USFS.Library.Logging` (provides `AddUSFSLogging()`)
**PII Package:** `UWMC.Library.Logging` (provides masking attributes)

### Setup

```csharp
builder.Services.AddUSFSLogging(builder.Configuration);
```

### PII/NPI Masking (Required for All Services)

Any class that may be logged or serialized to logs MUST have PII/NPI fields decorated:

```csharp
using UWMC.Library.Logging;

public class BorrowerResponse
{
    public int LoanNumber { get; set; }  // Not PII

    [PersonallyIdentifiableInformation]
    public string BorrowerName { get; set; }

    [PersonallyIdentifiableInformation]
    public string SocialSecurityNumber { get; set; }

    [NonpublicPersonalInformation]
    public decimal Income { get; set; }

    [NonpublicPersonalInformation]
    public string AccountNumber { get; set; }
}
```

**PII vs NPI:**
- `[PersonallyIdentifiableInformation]` — Name, SSN, DOB, address, phone, email
- `[NonpublicPersonalInformation]` — Financial data: income, account numbers, loan terms, credit score

When these attributes are present, the USFS logging infrastructure automatically masks these fields in log output.

## 8. DI Registration Patterns

Organize service registrations in extension methods under an `Extensions/` directory:

```csharp
// Extensions/ServiceCollectionExtensions.cs
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services)
    {
        // Repositories
        services.AddTransient<IConditionRepository, ConditionRepository>();
        services.AddTransient<ILoanRepository, LoanRepository>();

        // Orchestrators / Services
        services.AddTransient<IConditionOrchestrator, ConditionOrchestrator>();

        // AutoMapper
        services.AddAutoMapper(typeof(ServiceCollectionExtensions).Assembly);

        // Validators
        services.AddTransient<IValidator<CreateConditionRequest>,
            CreateConditionRequestValidator>();

        return services;
    }
}
```

Then in Program.cs:
```csharp
builder.Services.AddApplicationServices();
```

## 9. Environment-Specific Configuration

Create appsettings files for each environment. Values that differ per environment go here; secrets go in Vault.

```
appsettings.json                    # Base / shared values
appsettings.Development.json        # Local dev (UseVault: false)
appsettings.Integration.json        # INT environment
appsettings.Staging.json            # STG environment
appsettings.Production.json         # PRD environment
```

**Common overrides per environment:**
- `UseVault` — `false` in Development, `true` everywhere else
- `ConnectionStrings` — local DB in Development, Vault-provided elsewhere
- `Passport.ApplicationEdgeUrl` — environment-specific URL
- `FeatureFlags.EnableConnection` — `false` in Development
- Kafka bootstrap servers — different per environment

</the_process>

<examples>

<example>
<scenario>Setting up a new business service (cell-biz-conditions) with database and Kafka producer</scenario>

```csharp
// Program.cs — Complete example for a business service
using USFS.Library.Logging;
using USFS.Library.HealthCheck;

var builder = WebApplication.CreateBuilder(args);

// 1. Vault FIRST
if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();

// 2. Logging
builder.Services.AddUSFSLogging(builder.Configuration);

// 3. Application services
builder.Services.AddAutoMapper(typeof(Program).Assembly);
builder.Services.AddTransient<IConditionRepository, ConditionRepository>();
builder.Services.AddTransient<IConditionOrchestrator, ConditionOrchestrator>();

// 4. Kafka producer
var kafkaUser = builder.Configuration["KafkaServiceAccount:Username"];
var kafkaPw = builder.Configuration["KafkaServiceAccount:Password"];
builder.Services.AddUWMCMessagingKafka(
    builder.Configuration, $"{kafkaUser}@shoremortgage.com", kafkaPw);
builder.Services.AddTransient<IConditionEventProducer, ConditionEventProducer>();

// 5. Health check
builder.Services.AddUSFSHealthCheck(builder.Configuration);

// 6. Auth
builder.Services.AddUsfsAuthenticationServices(builder.Configuration);
builder.Services.AddControllers();
builder.Services.AddAuthorization();

// 7. Database with rotating credentials
var dbRole = builder.Configuration["DbRoleName"];
builder.Services.AddDbContext<ConditionDbContext>(options =>
    options.UseSqlServer(string.Format(
        builder.Configuration.GetConnectionString("Db"),
        dbRole,
        builder.Configuration[$"{dbRole}:Username"],
        builder.Configuration[$"{dbRole}:Password"])));

var app = builder.Build();

app.UseRouting();
app.UseUsfsAuthentication();
app.UseUSFSHealthCheck();
app.MapControllers().RequireAuthorization();
app.UseSqlDatabase<ConditionMigrationDbContext>();
app.UseUWMCMessagingConsumers(true, typeof(Program).Assembly);

await app.RunAsync();
public partial class Program;
```
</example>

<example>
<scenario>Setting up a BFF service with Passport auth that proxies to downstream business services</scenario>

```csharp
// Program.cs — BFF with Passport
using UWMC.Library.User.Passport.Extensions;

var builder = WebApplication.CreateBuilder(args);

if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();

builder.Services.AddPassport(builder.Configuration);

// HttpClient for downstream service calls
// Passport automatically propagates auth headers via HttpClientFactory
builder.Services.AddHttpClient<IConditionServiceClient, ConditionServiceClient>(client =>
{
    client.BaseAddress = new Uri(
        builder.Configuration["DownstreamServices:ConditionApi"]);
});

var app = builder.Build();

// UsePassport replaces UseRouting + UseAuthentication + UseAuthorization
app.UsePassport();
app.MapPassportEndpoints();  // Registers /passport and /login
app.MapControllers().RequireAuthorization();

app.Run();
public partial class Program;
```

```json
// appsettings.json for BFF
{
  "Passport": {
    "ApplicationEdgeUrl": "https://cell-bff-conditions.int.uwm.com",
    "CookieDomain": ".uwm.com"
  },
  "DownstreamServices": {
    "ConditionApi": "https://cell-biz-conditions.int.uwm.com"
  }
}
```
</example>

<example>
<scenario>Adding a Kafka consumer in a separate repository</scenario>

The consumer service lives in a separate repo (`cell-biz-conditions-consumer`) but processes events for the same domain.

```csharp
// Program.cs — Kafka consumer service
var builder = WebApplication.CreateBuilder(args);

if (builder.Configuration.GetValue<bool?>("UseVault") ?? true)
    builder.AddVaultSecrets();

builder.Services.AddUSFSLogging(builder.Configuration);

// Kafka consumer registration
var kafkaUser = builder.Configuration["KafkaServiceAccount:Username"];
var kafkaPw = builder.Configuration["KafkaServiceAccount:Password"];
builder.Services.AddUWMCMessagingKafka(
    builder.Configuration, $"{kafkaUser}@shoremortgage.com", kafkaPw);

// Business logic services (shared domain, may share database)
builder.Services.AddTransient<IConditionProcessor, ConditionProcessor>();

// Database (same DB as HTTP API — allowed for Kafka split)
builder.Services.AddDbContext<ConditionDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Db")));

builder.Services.AddUSFSHealthCheck(builder.Configuration);

var app = builder.Build();

app.UseUSFSHealthCheck();
app.UseUWMCMessagingConsumers(true, typeof(Program).Assembly);

await app.RunAsync();
public partial class Program;
```

```csharp
// Handlers/LoanStatusChangedHandler.cs
[MessageHandler("LoanStatusChangedConsumer")]
public class LoanStatusChangedHandler
    : IConsumerHandler<string, LoanStatusChangedEvent>
{
    private readonly IConditionProcessor _processor;
    private readonly ILogger<LoanStatusChangedHandler> _logger;

    public LoanStatusChangedHandler(
        IConditionProcessor processor,
        ILogger<LoanStatusChangedHandler> logger)
    {
        _processor = processor;
        _logger = logger;
    }

    public EventReturn HandleMessage(
        Event<string, LoanStatusChangedEvent> message)
    {
        _logger.LogInformation(
            "Processing loan status change for {LoanNumber}",
            message.Key);

        _processor.ProcessStatusChange(message.Key, message.Value);
        return EventReturn.Handled;
    }
}
```
</example>

</examples>

<critical_rules>

1. **Vault MUST be first in Program.cs** — `builder.AddVaultSecrets()` MUST be called before any service registration that reads secrets from configuration (database, Kafka, feature flags). Wrong order = missing secrets at runtime.

2. **Know your auth paradigm** — Business services (cell-biz-*) use ADFS JWT Bearer via `AddUsfsAuthenticationServices()`. BFF/UI services use Passport via `AddPassport()` / `UsePassport()`. Using the wrong paradigm causes auth failures.

3. **UsePassport() replaces multiple middleware calls** — When using Passport, do NOT manually call `UseRouting()`, `UseAuthentication()`, or `UseAuthorization()`. `UsePassport()` handles all of these internally. Duplicate calls cause middleware conflicts.

4. **NEVER use `new HttpClient()`** — Always use `HttpClientFactory` (`AddHttpClient<T>()` in DI). Passport and auth libraries rely on `HttpClientFactory` for automatic header propagation in service-to-service calls.

5. **HTTP API and Kafka consumer MUST be separate repos** — The v3 pattern requires one container per repo. The HTTP API service (`cell-biz-{name}`) produces events. The consumer service (`cell-biz-{name}-consumer`) consumes them. They are independently deployable.

6. **One service per database** — Only your service's bounded context accesses your database directly. Exceptions: CQRS read/write split, HTTP/Kafka split (same team, same domain).

7. **NEVER hardcode or commit secrets** — All secrets (passwords, API keys, connection strings with credentials) MUST come from Vault. Use `"UseVault": false` in Development, never fake credentials in appsettings.

8. **Health checks MUST be anonymous** — Kubernetes liveness/readiness probes cannot authenticate. Health check endpoints MUST use `[AllowAnonymous]` or be excluded from auth middleware.

9. **`public partial class Program;`** — This line MUST be at the end of Program.cs. It enables `WebApplicationFactory<Program>` for integration tests. Without it, integration tests cannot reference the entry point.

10. **PII/NPI attributes are required** — Any DTO or model that may appear in logs MUST have `[PersonallyIdentifiableInformation]` and `[NonpublicPersonalInformation]` attributes on sensitive fields. This is a compliance requirement.

</critical_rules>

<edge_cases>

**Vault unavailable in local development:**
Set `"UseVault": false` in `appsettings.Development.json`. Provide local connection strings and fake credentials directly in the Development appsettings file. Never commit real credentials.

**Service needs both Passport AND JWT Bearer auth:**
Some BFFs need to accept both cookie-based (UI) and Bearer token (service-to-service) requests. Use `app.MapControllers().RequireAuthorization()` (not `.RequirePassport()`) to accept either cookie or bearer token.

**Kafka consumer fails and needs retry:**
`EventReturn.Handled` acknowledges the message. If processing fails, throw an exception — the Kafka library handles retry based on configuration. Do not silently swallow errors.

**Database migration conflicts between HTTP and consumer repos:**
When both repos share a database, only ONE repo should own migrations. Typically the HTTP API repo owns migrations, and the consumer repo uses `EnsureCreated()` or reads only.

**Feature flag provider unavailable:**
Set `"EnableConnection": false` in Development appsettings. The `IFeatureFlagManager` returns default values when disconnected. Always code both branches (flag on and off) and test both paths.

**Legacy Startup.cs services:**
Older services use the `Startup.cs` pattern with `ConfigureServices()` and `Configure()`. The registration order is the same, just split across two methods. Do not migrate to top-level statements unless explicitly asked — it touches every line of startup code.

**Service account naming:**
The Kafka service account name typically matches the service name: `cell-biz-your-service`. The `@shoremortgage.com` suffix is appended in code. Vault role names also follow this convention.

</edge_cases>

<verification_checklist>

Before completing infrastructure integration:

- [ ] Program.cs follows correct registration order (Vault first)
- [ ] Correct auth paradigm used (ADFS JWT for biz, Passport for BFF)
- [ ] If using Passport: `UsePassport()` called WITHOUT manual `UseRouting()`/`UseAuthentication()`/`UseAuthorization()`
- [ ] Health check endpoint is anonymous (`[AllowAnonymous]` or excluded from auth)
- [ ] `HttpClientFactory` used for all HTTP calls (no `new HttpClient()`)
- [ ] All secrets come from Vault (no hardcoded credentials)
- [ ] `"UseVault": false` set in `appsettings.Development.json`
- [ ] PII/NPI attributes on all sensitive DTO fields
- [ ] Database follows one-service-per-database rule
- [ ] If Kafka: producer in HTTP API repo, consumer in separate `-consumer` repo
- [ ] Feature flags tested with both on/off states
- [ ] `public partial class Program;` at end of Program.cs
- [ ] All environment-specific appsettings files created

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-business-service` orchestrator (Phase 4)
- Direct invocation via `/uwm-business-service-dev:integrate-infrastructure`

**This skill should be used after:**
- `implement-feature` (Phase 3) — business logic is in place, now connect infrastructure

**This skill should be used before:**
- `test-strategy` (Phase 5) — integration tests need infrastructure configured first

**Related skills:**
- `design-api` — designs the API contract this skill wires up
- `implement-feature` — implements business logic this skill connects to infrastructure
- `test-strategy` — tests the infrastructure integrations this skill configures

</integration>

<resources>

**UWM packages referenced in this skill:**
- `UWMC.Library.User.Passport` — GUP authentication for BFF/UI services
- `USFS.Library.Authentication` — ADFS JWT auth for business services
- `UWMC.Vault` — Modern Vault integration
- `UWMC.Library.Messaging.Kafka` — Kafka producer/consumer framework
- `UWMC.Library.FeatureFlags.Split` — Feature flag management (Split provider)
- `UWMC.Library.FeatureFlags.Abstractions` — Feature flag abstractions
- `USFS.Library.Logging` — Structured logging setup
- `UWMC.Library.Logging` — PII/NPI masking attributes
- `USFS.Library.HealthCheck` — Health check middleware
- `Microsoft.EntityFrameworkCore.SqlServer` — SQL Server EF Core provider

**Confluence references:**
- "Global User Passport System Design" — Full GUP/Passport documentation
- "PII and NPI Masking Standard" — Compliance requirements for log masking
- "V3 Service Onboarding" — New service setup checklist

**Bitbucket reference services:**
- `cell-biz-borrower` (EH project) — Modern Program.cs with full infrastructure stack
- `cell-biz-condition` (EH project) — Legacy Startup.cs, JWT Bearer auth
- `cell-keystone` (GGF project) — Modern .NET with Vault rotating credentials
- `cell-biz-broker-preferences` (EH project) — Kafka + CosmosDB patterns

</resources>
