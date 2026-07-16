---
name: implement-feature
description: Implement business logic with strict TDD - write .feature specs, derive xUnit tests, achieve >=80 mutation score and >=80% coverage
---

<skill_overview>
Guides strict TDD implementation of business logic in v3 (.NET) business services. The workflow starts with writing .feature files as human-readable specifications (NOT executable tests), then deriving xUnit test cases from those specifications. Tests are written FIRST (RED), then minimal implementation code (GREEN), then refactor. Stryker.NET mutation testing validates test quality with a minimum score of 80. Code coverage must stay at or above 80%. All PII/NPI fields must have masking attributes from UWMC.Library.Logging. Unit test boundaries exist at the component edge - mock only infrastructure layer dependencies (repositories, HTTP clients, message handlers), never business logic (services, orchestrators, validators).
</skill_overview>

<rigidity_level>
LOW FREEDOM - The TDD cycle (RED-GREEN-REFACTOR) is rigid and must not be skipped or reordered. The .feature-as-spec pattern is rigid - .feature files are NEVER executed directly. Stryker mutation score >= 80 and code coverage >= 80% are rigid thresholds. What adapts: the business logic approach, test data strategy, and specific implementation patterns.
</rigidity_level>

<quick_reference>

| Step | Action | Output | Key Rule |
|------|--------|--------|----------|
| 1. Understand | Read Jira story, identify business rules | List of rules to encode | Know what you're building |
| 2. Specify | Write .feature file with scenarios | Specification document | NOT executable - spec only |
| 3. Test (RED) | Derive xUnit tests from .feature | All new tests FAIL | If tests pass, they're tautological |
| 4. Implement (GREEN) | Write minimum code to pass | All tests PASS | Fix implementation, not tests |
| 5. Mutate | Run Stryker.NET on unit tests | Score >= 80 | Never run Stryker on integration tests |
| 6. Refactor | Improve code, tests stay green | Clean code, tests pass | Re-run Stryker after significant changes |
| 7. Coverage | Check via dotnet test --collect | >= 80% on new code | SonarQube enforces this gate |
| 8. PII/NPI | Verify masking attributes | All sensitive fields masked | Use UWMC.Library.Logging attributes |

**Mock boundaries:**
- OK to mock: `IRepository`, `IHttpClient`, `IMessageProducer`, `IFeatureFlagService` (infrastructure)
- DO NOT mock: `IService`, `IOrchestrator`, `IValidator` (business logic)
- Use REAL AutoMapper: `new MapperConfiguration(cfg => cfg.AddMaps(typeof(YourProfile))).CreateMapper()`

</quick_reference>

<when_to_use>
- Implementing new business logic in a v3 service
- Adding new endpoints with business rules
- Modifying existing business logic (requires tests first)
- Any code that processes, transforms, or validates business data
- Adding business rules to existing capabilities
- NOT for: API design (use design-api), infrastructure setup (use integrate-infrastructure), integration/contract/E2E tests (use test-strategy), deployment (use prepare-deployment)
</when_to_use>

<the_process>

## Step 1: Understand the Requirement

Before writing any code or tests:

1. Read the Jira story/feature description
2. Identify the business capability being implemented
3. List the specific business rules that must be encoded
4. Identify which DTOs/models are involved (from design-api phase)
5. Identify infrastructure dependencies (database, external services, Kafka)
6. Check if this extends an existing capability or creates a new one

**Output:** A clear understanding of what business rules need to be encoded and what the expected inputs/outputs are.

## Step 2: Write .feature Specification

Create a .feature file in the test project's `Specifications/` directory. If the service has an existing convention for spec file location, follow that instead.

**CRITICAL: .feature files are SPECIFICATION DOCUMENTS. They are NOT executable tests. Do NOT install SpecFlow, Cucumber, Reqnroll, or any BDD test runner.**

The .feature file serves as:
- A human-readable description of business behavior
- The source from which xUnit test cases are derived
- Living documentation of what the service does

**Format:** Gherkin-style Feature/Scenario/Given-When-Then.

```gherkin
Feature: Add Loan Condition
  As a loan processor
  I need to add conditions to loans
  So that required documentation is tracked before closing

  Scenario: Add condition to active loan
    Given a loan with number "1234567890" in "Active" status
    And a condition type "Appraisal" with description "Property appraisal required"
    When I submit the add condition request
    Then the condition is created with status "Pending"
    And the condition has a unique identifier
    And the created timestamp is set to current UTC time

  Scenario: Reject condition on inactive loan
    Given a loan with number "9876543210" in "Closed" status
    And a condition type "Appraisal"
    When I submit the add condition request
    Then the request is rejected with a validation error
    And the error message contains "Cannot add conditions to closed loans"

  Scenario: Reject duplicate condition
    Given a loan with number "1234567890" in "Active" status
    And a condition type "Appraisal" already exists on the loan
    When I submit the add condition request
    Then the request is rejected with a conflict error
    And the error message contains "Condition type already exists"

  Scenario: Reject missing required fields
    Given a loan with number "1234567890" in "Active" status
    And a condition request with no condition type
    When I submit the add condition request
    Then the request is rejected with a validation error
    And the error lists "ConditionType" as required

  Scenario: Condition data excludes PII from logs
    Given a loan with number "1234567890" in "Active" status
    And a condition with borrower name "John Smith" and SSN "123-45-6789"
    When the condition is created
    Then the borrower name and SSN are masked in log output
    And only the loan number and condition type appear in logs
```

**Guidelines for .feature files:**
- Include happy path, validation failures, edge cases, and error scenarios
- Use realistic UWM business data (loan numbers, condition types, borrower scenarios)
- Each scenario should map to one or more xUnit test methods
- Cover at least 5 scenarios per feature
- Name the .feature file after the capability: `AddLoanCondition.feature`, `EvaluateConditionRules.feature`

## Step 3: Derive xUnit Tests from .feature Spec (RED)

For each scenario in the .feature file, create one or more xUnit test methods. Tests go in the unit test project (e.g., `test/UWMC.Business.[Name].Tests/`).

**Test naming convention:** `MethodName_Scenario_ExpectedResult` with underscores. This is the dominant pattern across UWM v3 services.

```csharp
using Moq;
using Xunit;

namespace UWMC.Business.Condition.Tests.Services;

public class LoanConditionServiceTests
{
    private readonly Mock<ILoanConditionRepository> _mockRepo;
    private readonly Mock<ILoanRepository> _mockLoanRepo;
    private readonly LoanConditionValidator _validator; // REAL validator, not mocked
    private readonly LoanConditionService _service;

    public LoanConditionServiceTests()
    {
        _mockRepo = new Mock<ILoanConditionRepository>(MockBehavior.Strict);
        _mockLoanRepo = new Mock<ILoanRepository>(MockBehavior.Strict);
        _validator = new LoanConditionValidator();
        _service = new LoanConditionService(
            _mockRepo.Object, _mockLoanRepo.Object, _validator);
    }

    // Derived from: "Add condition to active loan"
    [Fact]
    public async Task AddCondition_ActiveLoan_CreatesWithPendingStatus()
    {
        // Arrange
        _mockLoanRepo
            .Setup(r => r.GetLoanStatusAsync(It.Is<string>(ln => ln == "1234567890")))
            .ReturnsAsync("Active");
        _mockRepo
            .Setup(r => r.ExistsAsync("1234567890", "Appraisal"))
            .ReturnsAsync(false);
        _mockRepo
            .Setup(r => r.CreateAsync(It.Is<LoanCondition>(c =>
                c.Status == ConditionStatus.Pending)))
            .ReturnsAsync(new LoanCondition
            {
                Id = Guid.NewGuid(), Status = ConditionStatus.Pending,
                CreatedUtc = DateTime.UtcNow
            });

        var request = new AddConditionRequest
        {
            LoanNumber = "1234567890", ConditionType = "Appraisal",
            Description = "Property appraisal required"
        };

        // Act
        var result = await _service.AddConditionAsync(request);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.Equal(ConditionStatus.Pending, result.Value.Status);
        Assert.NotEqual(Guid.Empty, result.Value.Id);
        _mockRepo.Verify(r => r.CreateAsync(It.IsAny<LoanCondition>()), Times.Once);
    }

    // Derived from: "Reject condition on inactive loan" - uses Theory for multiple statuses
    [Theory]
    [InlineData("Closed")]
    [InlineData("Cancelled")]
    [InlineData("Denied")]
    public async Task AddCondition_InactiveLoan_ReturnsValidationError(string loanStatus)
    {
        // Arrange
        _mockLoanRepo
            .Setup(r => r.GetLoanStatusAsync(It.Is<string>(ln => ln == "9876543210")))
            .ReturnsAsync(loanStatus);

        var request = new AddConditionRequest
            { LoanNumber = "9876543210", ConditionType = "Appraisal" };

        // Act
        var result = await _service.AddConditionAsync(request);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Contains("Cannot add conditions to", result.Error);
    }

    // Continue with one test per remaining .feature scenario:
    // AddCondition_DuplicateConditionType_ReturnsConflict()
    // AddCondition_MissingConditionType_ReturnsValidationError()
}
```

**Key UWM test patterns:**
- `MockBehavior.Strict` for repositories and key dependencies; Loose for loggers
- REAL AutoMapper: `new MapperConfiguration(cfg => cfg.AddMaps(typeof(Profile))).CreateMapper()`
- `[Fact]` for single cases, `[Theory]` + `[InlineData]` for parameterized
- `It.Is<T>(t => condition)` for specific mock setups (not `It.IsAny<T>()`)
- JSON test data for complex objects: `TestHelper.GetDeserializedObject<T>("TestData/file.json")`
- Deep comparison: `ComparisonHelper.AssertComparisonResult(expected, actual, "message")`
- Verify calls: `_mock.Verify(r => r.Method(...), Times.Once)`

**Run tests - ALL must FAIL (RED):**
```bash
dotnet test test/UWMC.Business.[Name].Tests/UWMC.Business.[Name].Tests.csproj
```

## Step 4: Implement Minimum Code (GREEN)

Write the absolute minimum code to make the failing tests pass. Follow these patterns:

```csharp
using UWMC.Library.Logging;

namespace UWMC.Business.Condition.Services;

public class LoanConditionService : ILoanConditionService
{
    private readonly ILoanConditionRepository _conditionRepository;
    private readonly ILoanRepository _loanRepository;
    private readonly LoanConditionValidator _validator;
    private readonly ILogger<LoanConditionService> _logger;

    // Constructor DI - inject infrastructure as interfaces, validators as concrete
    public LoanConditionService(
        ILoanConditionRepository conditionRepository,
        ILoanRepository loanRepository,
        LoanConditionValidator validator,
        ILogger<LoanConditionService> logger)
    {
        _conditionRepository = conditionRepository;
        _loanRepository = loanRepository;
        _validator = validator;
        _logger = logger;
    }

    public async Task<Result<LoanCondition>> AddConditionAsync(AddConditionRequest request)
    {
        // Validate → check business rules → execute → log
        var validationResult = _validator.Validate(request);
        if (!validationResult.IsValid)
            return Result<LoanCondition>.Failure(
                string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

        var loanStatus = await _loanRepository.GetLoanStatusAsync(request.LoanNumber);
        if (loanStatus != "Active")
            return Result<LoanCondition>.Failure(
                $"Cannot add conditions to {loanStatus.ToLower()} loans");

        // ... business logic, then log with structured properties (< 50 user-defined)
        _logger.LogInformation(
            "Created condition {ConditionType} on loan {LoanNumber}",
            request.ConditionType, request.LoanNumber);

        return Result<LoanCondition>.Success(created);
    }
}
```

**Implementation guidelines:**
- Constructor DI, repository pattern, follow existing service patterns
- Use AutoMapper if already configured; otherwise manual mapping (don't add AutoMapper for one feature)
- Apply PII/NPI masking attributes on DTOs immediately (Step 8)
- `UWMC.Library.Logging` for structured logging - never `Console.Write`, < 50 user-defined properties
- Register in DI via extension methods: `services.AddScoped<ILoanConditionService, LoanConditionService>()`

## Step 5: Verify GREEN

Run all tests - new tests must pass, and no existing tests should regress:

```bash
dotnet test test/UWMC.Business.[Name].Tests/UWMC.Business.[Name].Tests.csproj
```

- If new tests fail: fix the implementation, not the tests
- If existing tests fail: you introduced a regression - investigate and fix
- ALL tests must pass before proceeding

## Step 6: Run Stryker Mutation Testing

Run Stryker.NET on the **unit test project only**. Never run Stryker on integration or E2E tests.

**If stryker-config.json exists** at the solution or test project level, use it:
```bash
dotnet stryker
```

**If no stryker-config.json exists**, create one. Place it in the test project directory:

```json
{
  "stryker-config": {
    "project": "../../src/UWMC.Business.[Name]/UWMC.Business.[Name].csproj",
    "test-case-filter": "FullyQualifiedName~UWMC.Business.[Name].Tests",
    "reporters": ["html", "json", "progress"],
    "threshold-high": 80,
    "threshold-low": 60,
    "threshold-break": 50,
    "ignore-mutations": ["block"],
    "ignore-methods": [
      "*Log", "*LogInformation", "*LogWarning", "*LogError",
      "*LogTrace", "*LogDebug", "*LogCritical",
      "ConfigureAwait", "Console.Write*",
      "*Exception.ctor", "*BeginScope"
    ],
    "mutate": [
      "!**/Generated/**",
      "!**/*.g.cs",
      "!**/Program.cs",
      "!**/Startup.cs"
    ]
  }
}
```

**Run Stryker:**
```bash
cd test/UWMC.Business.[Name].Tests
dotnet stryker --open-report
```

**For large test suites**, use incremental mutation testing:
```bash
dotnet stryker --since:main
```

**Target: mutation score >= 80.**

**Interpreting Stryker results:**

Stryker replaces parts of your code with mutations (e.g., changing `==` to `!=`, `>` to `>=`, removing statements) and checks if your tests catch the change. A "surviving mutant" means your tests did NOT detect the mutation - your tests are weak for that code path.

Example Stryker output:
```
Mutation testing:  100% (345/345)    Killed: 290    Survived: 42    Timeout: 13
Score: 83.8%

Surviving mutants:
1. src/Services/LoanConditionService.cs:42
   - Replaced '==' with '!=' in status check
   → Tests don't verify the exact status comparison

2. src/Services/LoanConditionService.cs:58
   - Removed 'await _conditionRepository.ExistsAsync(...)' call
   → No test verifies the duplicate check is actually called

3. src/Services/LoanConditionService.cs:71
   - Changed 'ConditionStatus.Pending' to 'ConditionStatus.Active'
   → Tests don't assert the exact status value set on creation
```

**Fixing surviving mutants:**
1. For mutant #1: Add a test that specifically asserts active loans are accepted (not just that inactive ones are rejected)
2. For mutant #2: Add `_mockRepository.Verify(r => r.ExistsAsync(...), Times.Once)` to the duplicate test
3. For mutant #3: Add `Assert.Equal(ConditionStatus.Pending, result.Value.Status)` in the happy path test

**Acceptable non-testable surviving mutants:**
- Logging method call mutations (covered by `ignore-methods` config)
- Exception constructor mutations
- `ConfigureAwait` mutations
- String mutations on log message templates

## Step 7: Refactor

With tests green and Stryker score >= 80:

1. Clean up implementation: extract methods, rename for clarity, apply DRY
2. Run tests after EACH refactoring step - tests must stay green
3. Re-run Stryker after significant refactoring to ensure score is maintained
4. Do not change test assertions during refactoring - only change implementation

## Step 8: Check Coverage and PII/NPI Compliance

### Coverage

```bash
dotnet test test/UWMC.Business.[Name].Tests/UWMC.Business.[Name].Tests.csproj \
  --collect:"XPlat Code Coverage"
```

- Target: >= 80% on new/modified code
- SonarQube enforces this gate in the CI pipeline
- For very small changes (e.g., a 2-line fix), the 80% threshold applies to the new/modified code, not necessarily the overall project percentage
- If below 80%: identify untested paths and add test cases

### PII/NPI Compliance

All DTOs and models containing sensitive data MUST have masking attributes from `UWMC.Library.Logging`:

```csharp
using UWMC.Library.Logging;

public class LoanConditionResponse
{
    public Guid ConditionId { get; set; }                    // Not sensitive
    public string LoanNumber { get; set; }                   // Not sensitive (internal ID)
    public string ConditionType { get; set; }                // Not sensitive

    [PersonallyIdentifiableInformation]
    public string BorrowerName { get; set; }                 // PII - masked in logs

    [PersonallyIdentifiableInformation]
    public string BorrowerEmail { get; set; }                // PII - masked in logs

    [PersonallyIdentifiableInformation]
    public string BorrowerPhone { get; set; }                // PII - masked in logs

    [PersonallyIdentifiableInformation]
    public string BorrowerSSN { get; set; }                  // PII - masked in logs

    [NonpublicPersonalInformation]
    public decimal? CreditScore { get; set; }                // NPI - masked in logs

    [NonpublicPersonalInformation]
    public decimal? Income { get; set; }                     // NPI - masked in logs

    [PersonallyIdentifiableInformation]
    public string PropertyAddress { get; set; }              // PII - masked in logs

    public ConditionStatus Status { get; set; }              // Not sensitive
    public DateTime CreatedUtc { get; set; }                 // Not sensitive
}
```

**Common PII fields:** SSN, Name, Address, Phone, Email, DateOfBirth, DriverLicenseNumber
**Common NPI fields:** CreditScore, Income, AccountNumber, LoanBalance, DebtToIncomeRatio

## Step 9: Commit

After all checks pass, stage the changes and invoke `/uwm-cyborg-sdlc:commit` to generate the commit message from the staged diff. The commit skill will classify the type as `feat` and produce a Conventional Commits-compliant message with an Implemented-By trailer.

</the_process>

<examples>

## Example 1: Full TDD Walkthrough - Loan Condition Service

Using the .feature specification and test class from Steps 2-4 above (the `AddLoanCondition.feature` and `LoanConditionServiceTests` examples), here is the complete RED → GREEN → Stryker flow:

```bash
# 1. RED: all tests fail (no implementation yet)
dotnet test test/UWMC.Business.Condition.Tests/ --filter "LoanConditionServiceTests"
# Expected: 6 tests failed (4 Facts + 1 Theory with 3 InlineData = 6 test cases)

# 2. Implement LoanConditionService, LoanConditionValidator, DI registration
#    (see Step 4 for service implementation pattern)

# 3. GREEN: all tests pass
dotnet test test/UWMC.Business.Condition.Tests/ --filter "LoanConditionServiceTests"
# Expected: 6 tests passed

# 4. MUTATE: run Stryker
cd test/UWMC.Business.Condition.Tests
dotnet stryker --open-report
```

### Interpreting Stryker Output

```
Mutation testing:  100% (28/28)    Killed: 24    Survived: 3    Timeout: 1
Score: 85.7%

Surviving mutants:
1. LoanConditionService.cs:42 - Changed '!=' to '==' in status check
   → Tests only verify rejections, not that active loans ARE accepted
   FIX: The happy path test already asserts IsSuccess - verify the mock
        _mockLoanRepo.Verify(r => r.GetLoanStatusAsync("1234567890"), Times.Once);

2. LoanConditionService.cs:58 - Removed ExistsAsync call entirely
   → No test verifies the duplicate check is actually called
   FIX: Add to happy path test:
        _mockConditionRepo.Verify(r => r.ExistsAsync("1234567890", "Appraisal"), Times.Once);

3. LoanConditionService.cs:72 - Changed ConditionStatus.Pending to ConditionStatus.Active
   → Tests don't assert the exact status value on the object passed to CreateAsync
   FIX: Already covered by the It.Is<> constraint in mock setup; ensure assertion
        checks result.Value.Status == ConditionStatus.Pending
```

After fixing these three gaps, Stryker score rises to 96%.

## Example 2: Adding a Business Rule to Existing Capability

A developer needs to add a new rule: "Conditions of type 'Final Inspection' can only be added after the loan has an existing 'Appraisal' condition that is 'Satisfied'."

### Updated .feature Specification

Add these scenarios to the existing `AddLoanCondition.feature`:

```gherkin
  Scenario: Final Inspection requires satisfied Appraisal
    Given a loan with number "1234567890" in "Active" status
    And an existing "Appraisal" condition with status "Satisfied"
    When I add a condition of type "Final Inspection"
    Then the condition is created with status "Pending"

  Scenario: Final Inspection rejected without satisfied Appraisal
    Given a loan with number "1234567890" in "Active" status
    And an existing "Appraisal" condition with status "Pending"
    When I add a condition of type "Final Inspection"
    Then the request is rejected with a validation error
    And the error contains "Appraisal must be satisfied before Final Inspection"
```

### New Test Methods

Add to the existing `LoanConditionServiceTests` class:

```csharp
[Fact]
public async Task AddCondition_FinalInspectionWithSatisfiedAppraisal_Succeeds()
{
    // Arrange
    _mockLoanRepo
        .Setup(r => r.GetLoanStatusAsync("1234567890"))
        .ReturnsAsync("Active");
    _mockConditionRepo
        .Setup(r => r.ExistsAsync("1234567890", "Final Inspection"))
        .ReturnsAsync(false);
    _mockConditionRepo
        .Setup(r => r.GetConditionStatusAsync("1234567890", "Appraisal"))
        .ReturnsAsync(ConditionStatus.Satisfied);
    _mockConditionRepo
        .Setup(r => r.CreateAsync(It.IsAny<LoanCondition>()))
        .ReturnsAsync(new LoanCondition
        {
            Id = Guid.NewGuid(),
            Status = ConditionStatus.Pending,
            CreatedUtc = DateTime.UtcNow
        });

    var request = new AddConditionRequest
    {
        LoanNumber = "1234567890",
        ConditionType = "Final Inspection"
    };

    // Act
    var result = await _service.AddConditionAsync(request);

    // Assert
    Assert.True(result.IsSuccess);
    Assert.Equal(ConditionStatus.Pending, result.Value.Status);
}

[Theory]
[InlineData(ConditionStatus.Pending)]
[InlineData(ConditionStatus.Waived)]
public async Task AddCondition_FinalInspectionWithoutSatisfiedAppraisal_ReturnsError(
    ConditionStatus appraisalStatus)
{
    // Arrange
    _mockLoanRepo
        .Setup(r => r.GetLoanStatusAsync("1234567890"))
        .ReturnsAsync("Active");
    _mockConditionRepo
        .Setup(r => r.ExistsAsync("1234567890", "Final Inspection"))
        .ReturnsAsync(false);
    _mockConditionRepo
        .Setup(r => r.GetConditionStatusAsync("1234567890", "Appraisal"))
        .ReturnsAsync(appraisalStatus);

    var request = new AddConditionRequest
    {
        LoanNumber = "1234567890",
        ConditionType = "Final Inspection"
    };

    // Act
    var result = await _service.AddConditionAsync(request);

    // Assert
    Assert.False(result.IsSuccess);
    Assert.Contains("Appraisal must be satisfied", result.Error);
}
```

### Implementation Change

Add the prerequisite check to `AddConditionAsync`:

```csharp
// After duplicate check, before creation:
if (request.ConditionType == "Final Inspection")
{
    var appraisalStatus = await _conditionRepository
        .GetConditionStatusAsync(request.LoanNumber, "Appraisal");
    if (appraisalStatus != ConditionStatus.Satisfied)
    {
        return Result<LoanCondition>.Failure(
            "Appraisal must be satisfied before Final Inspection can be added");
    }
}
```

### Regression Verification

```bash
# Run ALL tests, not just new ones
dotnet test test/UWMC.Business.Condition.Tests/

# Run Stryker to verify new code is covered by mutations
cd test/UWMC.Business.Condition.Tests
dotnet stryker --since:main --open-report
```

All 7 original tests must still pass alongside the 2 new tests.

</examples>

<critical_rules>

1. **NEVER execute .feature files directly** - They are specifications for deriving xUnit tests. Do NOT install or configure SpecFlow, Cucumber, Reqnroll, or any BDD test runner.
2. **NEVER write implementation before tests** - Tests MUST fail (RED) before implementation exists. If tests pass without implementation, they are tautological - rewrite them.
3. **NEVER mock business logic** - Mock only infrastructure layer (repositories, HTTP clients, message handlers, feature flag services). Use REAL validators, mappers (via `MapperConfiguration`), and orchestrators.
4. **ALWAYS run Stryker after implementation** - Mutation score must be >= 80. Surviving mutants reveal weak test assertions.
5. **NEVER defer PII/NPI masking** - Apply `[PersonallyIdentifiableInformation]` and `[NonpublicPersonalInformation]` attributes from `UWMC.Library.Logging` immediately, not "later."
6. **ALWAYS run the full test suite** after GREEN, not just new tests. Catch regressions early.
7. **ALWAYS keep coverage >= 80%** on new/modified code. SonarQube enforces this gate.
8. **NEVER commit with failing tests**, low Stryker score, or missing PII masking attributes.
9. **Unit test boundaries at component edge** - Do not test internal implementation details. Test public behavior through the service/orchestrator interface.
10. **NEVER run Stryker on integration or E2E tests** - Mutation testing applies to unit tests only.
11. **Use `MockBehavior.Strict`** for repository and key domain dependencies. Use default behavior only for loggers and non-critical dependencies.
12. **Use `It.Is<T>(t => condition)`** for mock setups. Avoid `It.IsAny<T>()` unless the value genuinely does not matter for the test.
13. **Verify mock interactions** where behavior depends on a call being made. Use `_mock.Verify(x => x.Method(...), Times.Once)`.

</critical_rules>

<verification_checklist>

- [ ] .feature specification covers happy path, edge cases, and error scenarios (minimum 5 scenarios)
- [ ] All xUnit tests derived from .feature scenarios (clear mapping via comments)
- [ ] Tests failed before implementation (RED verified)
- [ ] Tests pass after implementation (GREEN verified)
- [ ] Stryker mutation score >= 80 (run on unit tests only)
- [ ] Code coverage >= 80% on new/modified code
- [ ] PII/NPI fields have masking attributes from UWMC.Library.Logging
- [ ] Only infrastructure layer mocked - business logic uses real instances
- [ ] No regression in existing tests (full test suite passed)
- [ ] Structured logging with UWMC.Library.Logging (no Console.Write)
- [ ] No BDD test runners installed (no SpecFlow, Cucumber, Reqnroll)
- [ ] DI registration via extension methods in the service project
- [ ] MockBehavior.Strict used for key dependencies

</verification_checklist>

<integration>

**Called by:** `develop-business-service` orchestrator (Phase 3: Implement)

**Works with:**
- `hyperpowers:test-driven-development` - TDD workflow aligns (RED-GREEN-REFACTOR cycle)
- `hyperpowers:sre-task-refinement` - Validates test quality in task specs

**Preceded by:** `design-api` (Phase 2) - provides the DTOs, endpoints, and API contract being implemented

**Followed by:** `integrate-infrastructure` (Phase 4) or `test-strategy` (Phase 5) - adds GUP auth, Kafka, database infrastructure, then integration/contract/E2E tests

**Dependency:** Unit tests from this phase feed into `test-strategy` phase. Integration tests build on the working unit-tested code.

</integration>

<resources>

**UWM Standards:**
- Testing Bible: https://kb.uwm.com/display/TESTAUTO/Test+Automation
- PII/NPI Masking: UWMC.Library.Logging documentation on Confluence

**Tools:**
- Stryker.NET: https://stryker-mutator.io/docs/stryker-net/introduction/
- xUnit: https://xunit.net/docs/getting-started/netcore/cmdline
- Moq: https://github.com/devlooped/moq
- CompareNETObjects: https://github.com/GregFinzer/Compare-Net-Objects

**UWM NuGet Packages (Unit Tests):**
- `xunit` - Test framework
- `xunit.runner.visualstudio` - VS test runner
- `Moq` (4.x, pinned below 5.0) - Mocking framework
- `Microsoft.NET.Test.Sdk` - Test SDK
- `CompareNETObjects` - Deep object comparison for complex assertions

**UWM NuGet Packages (Integration Tests - used in test-strategy phase):**
- `UWMC.Library.Testing.AspNetCore` - WebApplicationFactory helpers
- `UWMC.Library.Testing.MsSql` - SQL Server TestContainers
- `UWMC.Library.Testing.WireMock` - WireMock HTTP mock server
- `UWMC.Library.Testing.PactFlow` - Consumer-driven contract testing
- `UWMC.Library.Testing.Kafka` - Kafka testing utilities
- `UWMC.Library.Testing.EntityFrameworkCore` - EF Core test helpers

**Gherkin Reference:** https://cucumber.io/docs/gherkin/reference/ (for .feature file syntax only - NOT for test execution)

**Existing Service Examples:**
- cell-biz-broker-preferences: Mature service with orchestrator-per-method test organization
- cell-biz-condition: NRules-based business rules with JSON test data fixtures
- cell-biz-borrower: Repository pattern with ComparisonHelper deep assertions

</resources>
