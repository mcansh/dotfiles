---
name: design-api
description: Use when designing HTTP API endpoints for a v3 business service - covers REST standards, DTO design, versioning, error handling, and API security per UWM standards
---

<skill_overview>
Guides the design of REST API endpoints for v3 business services following UWM's API standards. Covers resource naming (kebab-case per Confluence standard), versioning (v{integer} URL path via Asp.Versioning.Mvc), DTO design with FluentValidation, error handling with ProblemDetails (RFC 7807), Swagger documentation via Swashbuckle, and the 10 API security requirements from UWM's API Security Standard. Also handles the decision of when to use HTTP vs async (Kafka) for long-running operations.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - REST conventions (kebab-case, v{integer} versioning) and API security requirements are rigid per UWM standards. Specific endpoint design, DTO structure, and validation rules adapt to business requirements.
</rigidity_level>

<quick_reference>

| Aspect | Standard | Example |
|--------|----------|---------|
| Resource naming | kebab-case, plural nouns | `/v1/loan-conditions` |
| Versioning | `v{integer}` URL path prefix | `/v1/`, `/v2/` |
| Versioning package | `Asp.Versioning.Mvc.ApiExplorer` 8.1.0 | `[ApiVersion("1")]` |
| HTTP verbs | GET=read, POST=create, PUT=replace, PATCH=update, DELETE=remove | Standard REST |
| Query params | camelCase | `?pageSize=25&sortBy=createdDate` |
| Error responses | RFC 7807 ProblemDetails | `new ProblemDetails { Title = "...", Status = 400 }` |
| Long-running ops | Prefer Kafka async; HTTP 202 if must be HTTP | POST returns 202 |
| Request validation | `FluentValidation.AspNetCore` 11.3.x | `RuleFor(x => x.Name).NotEmpty()` |
| API docs | `Swashbuckle.AspNetCore` 6.6.x+ | Auto-generated Swagger UI |
| Controller base | `ControllerBase` with `[ApiController]` | Enables auto model validation |

</quick_reference>

<when_to_use>
- Planning new endpoints for a v3 business service
- Designing request/response DTOs
- Deciding between synchronous HTTP and asynchronous (Kafka) communication
- Reviewing existing API design against UWM standards
- Planning bulk or long-running operations
- NOT for: Implementation (use implement-feature), infrastructure setup (use integrate-infrastructure)
</when_to_use>

<the_process>

## 1. Identify Resources and Capabilities

Map business capabilities to REST resources. Use plural nouns (not verbs).

**Standard (Confluence ITSTD):**
- Resources SHOULD be nouns: `/v1/loan-conditions`, `/v1/borrowers`
- For API Gateway: MUST use kebab-case
- For internal services: SHOULD use kebab-case

**Reality check:** Many existing services use PascalCase RPC-style routes (e.g., `GetBorrowers`, `RunBorrowerValidationRules`). For **new** services, follow the standard. For existing services, maintain consistency with existing routes.

```
Business capability           → REST resource
"Manage loan conditions"      → /v1/loan-conditions
"Track borrower information"  → /v1/borrowers
"Process applications"        → /v1/applications
```

## 2. Set Up API Versioning

**Package:** `Asp.Versioning.Mvc.ApiExplorer` 8.1.0

The standard is URL path versioning: `{host}/v{integer}/{resource}`.

### Registration

```csharp
// Program.cs or ServiceCollectionExtensions.cs
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
})
.AddApiExplorer(options =>
{
    options.SubstituteApiVersionInUrl = true;
    options.GroupNameFormat = "'v'VVV";
});
```

### Controller Versioning

```csharp
[ApiController]
[ApiVersion("1")]
[Route("v{v:apiVersion}/[controller]")]
public class LoanConditionsController : ControllerBase
{
    // GET /v1/loan-conditions/{loanNumber}
    [HttpGet("{loanNumber}")]
    public async Task<IActionResult> GetByLoanNumber(string loanNumber) { ... }
}

// V2 controller (when breaking changes needed)
[ApiController]
[ApiVersion("2")]
[Route("v{v:apiVersion}/[controller]")]
public class LoanConditionsController : ControllerBase
{
    // GET /v2/loan-conditions/{loanNumber}
    [HttpGet("{loanNumber}")]
    public async Task<IActionResult> GetByLoanNumber(string loanNumber) { ... }
}
```

**Versioning rules:**
- Version at beginning of path: `/v1/resource` (not `/resource/v1`)
- Integer only: `v1`, `v2`, `v3` (no `v1.1` or `v1-beta`)
- New version only for breaking changes (response shape changes, removed fields)
- Non-breaking changes (new optional fields, new endpoints) do NOT require a version bump

## 3. Design Controller Structure

### Base Pattern

All controllers use `ControllerBase` with `[ApiController]`:

```csharp
[ApiController]
[ApiVersion("1")]
[Route("v{v:apiVersion}/loan-conditions")]
public class LoanConditionsController : ControllerBase
{
    private readonly IConditionOrchestrator _orchestrator;
    private readonly ILogger<LoanConditionsController> _logger;

    public LoanConditionsController(
        IConditionOrchestrator orchestrator,
        ILogger<LoanConditionsController> logger)
    {
        _orchestrator = orchestrator;
        _logger = logger;
    }

    [HttpGet("{loanNumber}")]
    [ProducesResponseType(typeof(ConditionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByLoanNumber(string loanNumber)
    {
        var result = await _orchestrator.GetConditions(loanNumber);
        if (result == null)
            return NotFound(new ProblemDetails
            {
                Title = "Loan not found",
                Status = StatusCodes.Status404NotFound
            });
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(ConditionResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateConditionRequest request)
    {
        var result = await _orchestrator.CreateCondition(request);
        return CreatedAtAction(
            nameof(GetByLoanNumber),
            new { loanNumber = result.LoanNumber },
            result);
    }
}
```

**Key `[ApiController]` behaviors:**
- Automatic model validation (returns 400 for invalid models)
- Automatic `[FromBody]` inference for complex types
- Automatic `[FromRoute]` / `[FromQuery]` inference for simple types
- ProblemDetails responses for automatic 400s

### Action Return Types

Prefer `Task<IActionResult>` over direct DTO returns. This allows:
- Returning different status codes
- Using `[ProducesResponseType]` for Swagger documentation
- Consistent error handling

```csharp
// PREFERRED: IActionResult with ProducesResponseType
[HttpGet("{id}")]
[ProducesResponseType(typeof(ConditionResponse), StatusCodes.Status200OK)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
public async Task<IActionResult> GetById(int id) { ... }

// ACCEPTABLE for simple cases: direct DTO return
[HttpGet("{loanNumber}")]
public async Task<ConditionResponse> GetByLoan(string loanNumber) { ... }
```

## 4. Design DTOs (Data Transfer Objects)

### Directory Structure

```
Dto/
├── V1/
│   ├── Conditions/
│   │   ├── CreateConditionRequest.cs
│   │   ├── UpdateConditionRequest.cs
│   │   └── ConditionResponse.cs
│   └── Borrowers/
│       ├── BorrowerRequest.cs
│       └── BorrowerResponse.cs
└── V2/
    └── Conditions/
        └── ConditionResponse.cs   (breaking changes only)
```

### Naming Convention

- Request DTOs: `{Action}{Resource}Request` — `CreateConditionRequest`, `UpdateBorrowerRequest`
- Response DTOs: `{Resource}Response` — `ConditionResponse`, `BorrowerResponse`
- Internal DTOs: `{Resource}Dto` — `ApplicationDto`, `ProjectDto`

### DTO Design

```csharp
// Request DTO — properties the client sends
public class CreateConditionRequest
{
    public string LoanNumber { get; set; }
    public string ConditionName { get; set; }
    public string Description { get; set; }
    public int? Priority { get; set; }
}

// Response DTO — properties the client receives
public class ConditionResponse
{
    public int Id { get; set; }
    public string LoanNumber { get; set; }
    public string ConditionName { get; set; }
    public string Status { get; set; }
    public DateTime CreatedDate { get; set; }

    [PersonallyIdentifiableInformation]
    public string BorrowerName { get; set; }
}
```

### PII/NPI Masking on DTOs

Any DTO field that may appear in logs MUST have masking attributes:

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
}
```

### AutoMapper Profiles

Map between domain models and DTOs:

```csharp
// Mappings/ConditionProfile.cs
public class ConditionProfile : Profile
{
    public ConditionProfile()
    {
        CreateMap<Condition, ConditionResponse>();
        CreateMap<CreateConditionRequest, Condition>()
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => "Pending"));
    }
}
```

Register via assembly scanning:
```csharp
builder.Services.AddAutoMapper(typeof(Program).Assembly);
```

## 5. Add Request Validation

**Package:** `FluentValidation.AspNetCore` 11.3.x (confirmed in cell-biz-borrower and cell-keystone)

### Registration

Two patterns exist:

```csharp
// Pattern 1: Auto-registration (borrower pattern)
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblies(new[] { typeof(Program).Assembly });

// Pattern 2: Manual registration (keystone pattern)
builder.Services.AddTransient<IValidator<CreateConditionRequest>, CreateConditionRequestValidator>();
builder.Services.AddTransient<IValidator<UpdateConditionRequest>, UpdateConditionRequestValidator>();
```

### Validator Classes

```csharp
public class CreateConditionRequestValidator : AbstractValidator<CreateConditionRequest>
{
    public CreateConditionRequestValidator()
    {
        RuleFor(x => x.LoanNumber)
            .NotEmpty().WithMessage("Loan number is required")
            .MaximumLength(20);

        RuleFor(x => x.ConditionName)
            .NotEmpty().WithMessage("Condition name is required")
            .MaximumLength(200);

        RuleFor(x => x.Priority)
            .InclusiveBetween(1, 5)
            .When(x => x.Priority.HasValue);
    }
}
```

### Validation with Rule Sets (Keystone pattern)

```csharp
// Define rule sets for different operations
public class ApplicationDtoValidator : AbstractValidator<ApplicationDto>
{
    public ApplicationDtoValidator()
    {
        RuleSet("Create", () =>
        {
            RuleFor(x => x.Name).NotEmpty();
            RuleFor(x => x.TeamId).GreaterThan(0);
        });

        RuleSet("Update", () =>
        {
            RuleFor(x => x.Id).GreaterThan(0);
        });
    }
}

// In controller — validate specific rule sets
await _validator.ValidateAsync(dto, options =>
    options.IncludeRuleSets("Create").ThrowOnFailures());
```

**Note:** Some older services (cell-biz-condition) use `System.ComponentModel.DataAnnotations` (`[Required]`, `[Range]`, `[MinLength]`) instead of FluentValidation. For new services, prefer FluentValidation for complex validation logic.

## 6. Design Error Handling

### Standard: RFC 7807 ProblemDetails

UWM's API Governance Strategy mandates RFC 7807/ProblemDetails for consistent error responses.

```csharp
// Return ProblemDetails for client errors
return BadRequest(new ProblemDetails
{
    Title = "Invalid loan identifier",
    Status = StatusCodes.Status400BadRequest,
    Detail = "Loan number must be numeric and 10 digits"
});

// Return ProblemDetails for not found
return NotFound(new ProblemDetails
{
    Title = "Condition not found",
    Status = StatusCodes.Status404NotFound
});
```

### Global Exception Handler (Keystone pattern)

```csharp
// Extensions/WebApplicationExtensions.cs
public static WebApplication UseGlobalExceptionHandler(this WebApplication app)
{
    app.UseExceptionHandler(errorApp =>
    {
        errorApp.Run(async context =>
        {
            var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;

            var (statusCode, message) = exception switch
            {
                ValidationException ex => (400, ex.Message),
                ArgumentException ex => (400, ex.Message),
                KeyNotFoundException => (404, "Resource not found"),
                UnauthorizedAccessException => (401, "Unauthorized"),
                _ => (500, "An unexpected error occurred")
            };

            context.Response.StatusCode = statusCode;
            context.Response.ContentType = "application/problem+json";

            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Title = message,
                Status = statusCode
            });
        });
    });

    return app;
}
```

### Error Response Rules

- **400 Bad Request**: Validation errors, invalid input — include field-level details
- **401 Unauthorized**: Missing or invalid authentication
- **403 Forbidden**: Authenticated but insufficient permissions
- **404 Not Found**: Resource doesn't exist
- **500 Internal Server Error**: Generic message only — details logged server-side
- **NEVER** expose stack traces, connection strings, or internal state in error responses
- Use `app.UseDeveloperExceptionPage()` ONLY in Development environment

## 7. Evaluate Sync vs Async Operations

For each operation, decide the communication pattern:

| Operation Type | Pattern | Example |
|---------------|---------|---------|
| Queries (< 1 sec) | Synchronous GET | `GET /v1/conditions/{loanNumber}` |
| Fast mutations (< 1 sec) | Synchronous POST/PUT/PATCH | `POST /v1/conditions` |
| Long-running (> 1 sec) | Kafka event | Publish event, consumer processes |
| Must be HTTP but slow | HTTP 202 Accepted | POST returns 202, poll status endpoint |

### HTTP 202 Pattern (when Kafka not feasible)

```csharp
[HttpPost("bulk-update")]
[ProducesResponseType(StatusCodes.Status202Accepted)]
public async Task<IActionResult> BulkUpdate([FromBody] BulkUpdateRequest request)
{
    var jobId = await _orchestrator.QueueBulkUpdate(request);
    return AcceptedAtAction(
        nameof(GetBulkUpdateStatus),
        new { jobId },
        new { jobId, status = "Queued" });
}

[HttpGet("bulk-update/{jobId}/status")]
public async Task<IActionResult> GetBulkUpdateStatus(string jobId)
{
    var status = await _orchestrator.GetJobStatus(jobId);
    return Ok(status);
}
```

If async is needed via Kafka, the consumer goes in a separate repo: `cell-biz-{name}-consumer`. See integrate-infrastructure skill for Kafka setup.

## 8. Configure Swagger/OpenAPI

**Package:** `Swashbuckle.AspNetCore` 6.6.2+

### Basic Setup

```csharp
// Program.cs
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    // Include XML comments for endpoint documentation
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
        options.IncludeXmlComments(xmlPath);

    // Avoid schema naming conflicts
    options.CustomSchemaIds(type => type.FullName);

    // Bearer token auth in Swagger UI
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});
```

### Enable XML Comments in .csproj

```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1591</NoWarn>
</PropertyGroup>
```

### Versioned Swagger Docs (with Asp.Versioning)

```csharp
// ConfigureSwaggerOptions.cs
public class ConfigureSwaggerOptions : IConfigureOptions<SwaggerGenOptions>
{
    private readonly IApiVersionDescriptionProvider _provider;

    public ConfigureSwaggerOptions(IApiVersionDescriptionProvider provider)
        => _provider = provider;

    public void Configure(SwaggerGenOptions options)
    {
        foreach (var description in _provider.ApiVersionDescriptions)
        {
            options.SwaggerDoc(description.GroupName, new OpenApiInfo
            {
                Title = "Loan Conditions API",
                Version = description.ApiVersion.ToString()
            });
        }
    }
}

// Register
builder.Services.AddTransient<IConfigureOptions<SwaggerGenOptions>, ConfigureSwaggerOptions>();
```

### Restrict to Non-Production

```csharp
// Only enable Swagger UI in non-production environments
if (!app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
```

## 9. Apply API Security Requirements

UWM's API Governance Strategy mandates the OWASP API Security Top 10. Key requirements for v3 services:

1. **Object-level authorization** — Check user access per record, not just endpoint-level auth
2. **Authentication** — GUP (see integrate-infrastructure skill). Never custom auth.
3. **Data filtering** — Server-side filtering only. Never rely on client-side filtering.
4. **Rate limiting and pagination** — Validate payload sizes, paginate large result sets
5. **Function-level authorization** — Deny by default. Use `[RequireSecurityGroup]` or `[RequireOrganizationRole]`
6. **Sensitive business flow protection** — Rate limiting for sensitive operations
7. **SSRF prevention** — Validate URIs if fetching remote resources
8. **Security misconfiguration** — TLS, security headers, no unnecessary features exposed
9. **API inventory** — All endpoints documented in Swagger/OpenAPI
10. **3rd party API safety** — Encrypted channels, validate and sanitize data, timeouts

### Pagination Pattern

```csharp
[HttpGet]
public async Task<IActionResult> GetAll(
    [FromQuery] int pageNumber = 1,
    [FromQuery] int pageSize = 25)
{
    pageSize = Math.Min(pageSize, 100); // Cap max page size
    var result = await _orchestrator.GetPaged(pageNumber, pageSize);
    return Ok(new PagedResponse<ConditionResponse>
    {
        Items = result.Items,
        PageNumber = pageNumber,
        PageSize = pageSize,
        TotalCount = result.TotalCount
    });
}
```

</the_process>

<examples>

<example>
<scenario>Designing a new conditions management API for cell-biz-conditions</scenario>

**Step 1: Identify resources**
- Primary resource: `loan-conditions`
- Operations: CRUD + bulk update + rule evaluation

**Step 2: Design endpoints**
```
GET    /v1/loan-conditions/{loanNumber}           → Get all conditions for a loan
GET    /v1/loan-conditions/{loanNumber}/{id}       → Get specific condition
POST   /v1/loan-conditions                         → Create condition
PUT    /v1/loan-conditions/{id}                     → Replace condition
PATCH  /v1/loan-conditions/{id}/status              → Update status only
DELETE /v1/loan-conditions/{id}                     → Remove condition
POST   /v1/loan-conditions/bulk-update              → Bulk update (returns 202)
```

**Step 3: Design DTOs**
```csharp
// Dto/V1/Conditions/CreateConditionRequest.cs
public class CreateConditionRequest
{
    public string LoanNumber { get; set; }
    public string Name { get; set; }
    public string Category { get; set; }
    public int Priority { get; set; }
}

// Dto/V1/Conditions/ConditionResponse.cs
public class ConditionResponse
{
    public int Id { get; set; }
    public string LoanNumber { get; set; }
    public string Name { get; set; }
    public string Status { get; set; }
    public DateTime CreatedDate { get; set; }

    [PersonallyIdentifiableInformation]
    public string AssignedTo { get; set; }
}
```

**Step 4: Add validation**
```csharp
public class CreateConditionRequestValidator : AbstractValidator<CreateConditionRequest>
{
    public CreateConditionRequestValidator()
    {
        RuleFor(x => x.LoanNumber).NotEmpty().MaximumLength(20);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Category).NotEmpty();
        RuleFor(x => x.Priority).InclusiveBetween(1, 5);
    }
}
```
</example>

<example>
<scenario>Adding a V2 endpoint with breaking response changes</scenario>

When a response shape change is required (e.g., splitting a `FullName` field into `FirstName`/`LastName`):

```csharp
// Dto/V2/Borrowers/BorrowerResponse.cs — breaking change
public class BorrowerResponse
{
    public int Id { get; set; }

    [PersonallyIdentifiableInformation]
    public string FirstName { get; set; }  // Was FullName in V1

    [PersonallyIdentifiableInformation]
    public string LastName { get; set; }   // Was FullName in V1
}

// Controllers/V2/BorrowersController.cs
[ApiController]
[ApiVersion("2")]
[Route("v{v:apiVersion}/borrowers")]
public class BorrowersController : ControllerBase
{
    [HttpGet("{lenderDatabaseId:int}/{loanRecordId:int}")]
    [ProducesResponseType(typeof(V2.BorrowerResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBorrower(int lenderDatabaseId, int loanRecordId)
    {
        // V2 maps to separate first/last name fields
        var result = await _orchestrator.GetBorrowerV2(lenderDatabaseId, loanRecordId);
        return Ok(result);
    }
}
```

The V1 controller continues to serve existing consumers until they migrate.
</example>

</examples>

<critical_rules>

1. **Use kebab-case for resource names** — `loan-conditions` not `loanConditions` or `LoanConditions`. This is the Confluence standard (ITSTD). Existing RPC-style routes in older services should be maintained for backward compatibility.

2. **Always version APIs** with `v{integer}` URL path prefix — `/v1/resource`. Use `Asp.Versioning.Mvc.ApiExplorer` 8.1.0 (NOT the deprecated `Microsoft.AspNetCore.Mvc.Versioning`).

3. **Never expose system details in errors** — No stack traces, connection strings, or internal state. Use ProblemDetails (RFC 7807). `app.UseDeveloperExceptionPage()` only in Development.

4. **Use FluentValidation for request validation** — `FluentValidation.AspNetCore` 11.3.x. Prefer auto-registration (`AddFluentValidationAutoValidation()`) or manual DI registration.

5. **Apply PII/NPI masking attributes** to sensitive DTO fields — `[PersonallyIdentifiableInformation]` and `[NonpublicPersonalInformation]` from `UWMC.Library.Logging`.

6. **Use `[ApiController]` on all controllers** — Enables automatic model validation, auto 400 responses, and parameter binding inference.

7. **Prefer Kafka for long-running operations** — If an operation takes > 1 second, publish an event to Kafka. The consumer lives in a separate repo (`cell-biz-{name}-consumer`). Use HTTP 202 only when Kafka is not feasible.

8. **Swagger in non-production only** — Do not expose Swagger UI in production environments.

9. **Paginate large result sets** — Cap `pageSize` server-side (e.g., max 100). Never return unbounded collections.

10. **BFFs are exempt** from REST conventions — BFFs may tightly couple to UI needs per Confluence standard.

</critical_rules>

<edge_cases>

**Existing service uses PascalCase RPC-style routes:**
Do NOT refactor existing routes to kebab-case (breaking change). Add new endpoints in kebab-case. Document the inconsistency.

**Service needs both V1 and V2 simultaneously:**
Both version controllers can coexist. Use `[ApiVersion("1")]` and `[ApiVersion("2")]` on separate controller classes. Swagger will show both versions.

**Validation needs to access database (e.g., uniqueness check):**
Inject dependencies into FluentValidation validators via constructor. Register validators with DI, not via auto-discovery for complex validators.

**DTO field is PII but never logged:**
Apply `[PersonallyIdentifiableInformation]` anyway — you cannot guarantee a DTO will never appear in logs. Defense in depth.

**Large file upload endpoint:**
Use `[RequestSizeLimit]` attribute. Do not accept unbounded payloads. Configure Kestrel limits in appsettings.

</edge_cases>

<verification_checklist>

Before completing API design:

- [ ] REST endpoints use kebab-case for resource names
- [ ] API versioning follows `v{integer}` pattern (e.g., `/v1/resource`)
- [ ] Request/response DTOs are defined with clear naming convention
- [ ] FluentValidation validators are planned for request DTOs
- [ ] Error responses use ProblemDetails and don't expose system details
- [ ] Long-running operations use async pattern (Kafka preferred, or HTTP 202)
- [ ] `[ProducesResponseType]` attributes on controller actions for Swagger
- [ ] PII/NPI fields have masking attributes
- [ ] Swagger configured with XML comments and Bearer auth
- [ ] Pagination planned for list endpoints (capped page size)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-business-service` orchestrator (Phase 2)
- Direct invocation via `/uwm-business-service-dev:design-api`

**This skill should be used after:**
- `create-v3-service` (Phase 1) — project exists and is provisioned

**This skill should be used before:**
- `implement-feature` (Phase 3) — API contract guides TDD implementation

**Related skills:**
- `integrate-infrastructure` — configures auth, database, Kafka that this skill designs against
- `implement-feature` — implements the API contract designed here with TDD
- `test-strategy` — tests the API through public endpoints

</integration>

<resources>

**UWM packages referenced:**
- `Asp.Versioning.Mvc.ApiExplorer` 8.1.0 — API versioning
- `FluentValidation.AspNetCore` 11.3.x — Request validation
- `Swashbuckle.AspNetCore` 6.6.2+ — Swagger/OpenAPI
- `AutoMapper` 13.x-14.x — DTO-to-domain mapping
- `UWMC.Library.Logging` — PII/NPI masking attributes

**Confluence references:**
- "HTTP API Must Follow ReST" (ITSTD) — REST naming and versioning standards
- "API Governance Strategy" (EArch) — Security requirements, RFC 7807, API-First design
- Microsoft Azure REST API Guidelines — Default for anything not specified by UWM

**Reference services:**
- `cell-biz-borrower` (EH) — FluentValidation, versioned controllers, ProblemDetails
- `cell-biz-condition` (EH) — DataAnnotations validation, stateless service
- `cell-keystone` (GGF) — FluentValidation with rule sets, global exception handler

</resources>
