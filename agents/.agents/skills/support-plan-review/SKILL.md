---
name: support-plan-review
description: Use when a team needs to assess their project's support readiness before production launch — walks through UWM Support Planning requirements (mandatory, recommended, ideal state), identifies gaps, and helps create actionable tasks to close them. Triggered by "support plan", "support review", "launch readiness", or "support checklist".
---

<skill_overview>
Interactive support readiness assessment. Walks the team through three tiers of support planning questions defined by the UWM Support Practice Council. For each item, determines current status (done, in progress, not started, N/A), captures answers, identifies gaps, and produces a summary with actionable tasks for anything missing.

Designed to be run **during development** — not the week before launch. The earlier teams engage, the fewer surprises at go-live.
</skill_overview>

<rigidity_level>
HIGH FREEDOM in conversation style and how questions are asked — adapt to the team's context and project type. LOW FREEDOM in coverage — every item in all three tiers must be addressed. Never skip a question silently.
</rigidity_level>

<quick_reference>
| Step | Action |
|------|--------|
| 0 | Check for existing `support-plan.md` — resume if found |
| 1 | Collect project context (name, type, timeline) |
| 2 | Walk through Tier 1: Mandatory requirements |
| 3 | Walk through Tier 2: Strongly recommended |
| 4 | Walk through Tier 3: Ideal state |
| 5 | Generate gap summary with tasks |
</quick_reference>

<when_to_use>
- User says "support plan", "support review", "support checklist", or "launch readiness"
- User asks about what's needed before going to production
- User mentions preparing for a rollout or launch
- User references Support Planning or the Support Practice Council
</when_to_use>

<the_process>

## Step 0: Check for Existing Plan File

Before starting a new assessment, check if a `support-plan.md` already exists in the project root (or a path the user specifies).

- **If found:** Read it, show the user the current state, and ask where they'd like to pick up. Resume from the first incomplete tier or item.
- **If not found:** Start fresh. Create `support-plan.md` after Step 1 (once you have project context) using the Step 5 format template from the start — all items default to `NOT STARTED`. Update it after each tier is completed.

The plan file is the persistence mechanism — it survives across sessions. Always keep it up to date as you progress through the review.

**Known limitation:** The plan file is updated after each completed tier, not after each individual answer. If a session ends mid-tier, answers collected during that tier may need to be re-gathered.

## Step 1: Collect Project Context

Before starting the assessment, gather baseline information:

1. **Solution name** — What is the project/feature called?
2. **Type** — Is this a new solution, an addition to an existing solution, or replacing a current solution/feature?
3. **Target launch date** — When is production launch planned?
4. **Team** — Who owns this? (team name, PdM/PO, tech lead)

If the user has already provided some of this context (e.g., you know the project from prior conversation), confirm what you know and ask only for what's missing.

## Step 2: Tier 1 — Minimum Mandatory Requirements at Launch

These items **must** be answered before go-live. No exceptions.

Walk through each category below. For each item, ask the user for their answer, then record the status: DONE, IN PROGRESS, NOT STARTED, or N/A.

### 1.1 Solution Identity
Carry forward from Step 1 — confirm the answers already collected and record them:
- Name & description of the solution
- Is this new / an addition to an existing solution?
- Is this replacing a current solution/feature? If yes, which one?

### 1.2 Users & User Groups
Who uses this? Check all that apply and capture specifics:
- Borrower
- Broker / LO
- Internal UWM Teams/TMs
- Permission-based groups — if yes, provide specific access permission rules

### 1.3 Access Points
Where/how is the solution accessed? (Ask the user to provide or describe a screenshot of the access point)
- Within an existing application — provide specific navigation and access points per user/group
- Stand-alone solution / access point — provide specific site and access points per user/group

### 1.4 Issue & Question Paths
What path should users follow for both issues and/or questions?
- Contact Sales/AE (or other relevant business team)
- Submit CR (provide any specific direction on field selections)
- Submit YouSupport ticket
- Contact Service Desk (x4500)
- Contact Tech Pros
- Direct Email to specific contact or group (identify how these will be tracked)

At least one path must be defined. Ask which paths apply and capture specifics for each.

### 1.5 Incident Escalation
If an incident arises, what is the escalation path beyond normal process of posting in Performance? Who should be notified for investigating?
- Owning Team
- PdM / PO
- Leadership
- Specific Team Members

All four must be identified with names/roles. (See Rule 11 in Critical Rules.)

## Step 3: Tier 2 — Strongly Consider Providing Before Launch

These items should be provided before launch. If they won't be ready by launch, capture the **expected delivery date**.

### 2.1 Product Documentation
Note: These will eventually become mandatory requirements.
- User Guide — exists? Planned?
- Training Materials — exists? Planned?
- System Documentation (Runbook, SDD, etc.) — exists? Planned?
- Internal/External Announcements — planned? Timing?

### 2.2 CR / YouSupport Configuration
- Category / Subcategory defined?
- Routing path for tickets and escalation beyond original intake?
- Incident/RCA assignment process defined?

## Step 4: Tier 3 — Ideal State Support Information

These items represent mature support readiness. Teams should aspire to these but they're not blockers for launch.

### 3.1 Built-in Help
Is there a "Help" option built into the solution?
- Borrowers directed to Broker?
- Broker directed to AE only, or Tech Pros as well?
- AE contacts Service Desk — then what?
  - Service Desk redirects to GGS Proper or Marketing BPT?
  - SN Ticket → Jira Item integration?
  - Email-based support?
- Automated Help Option (e.g., "click here to submit ticket")?

### 3.2 ChatUWM Integration
- Is feature information or help option searchable with ChatUWM?

### 3.3 System / Performance Monitoring
- Dynatrace, Logging, or other observability in place?
- PagerDuty configured?
- Tagging (Teams, etc.) — who should be included in a tag group?
- System Priority Tier assigned?

### 3.4 Post-Launch Ownership
If different than initial roll-out team:
- Team(s) responsible long-term
- Team Member SMEs
- PdM/PO

### 3.5 Usage Data & Analytics
- Location & access to usage data, permissions to access
- Troubleshooting documentation
- System performance reporting
- Product reporting (use, sentiment, etc.)

## Step 5: Generate Gap Summary

After completing all three tiers, generate a summary report:

### Format

```
# Support Plan Review: [Solution Name]
**Reviewed:** [Date]
**Last Updated:** [Date]
**Target Launch:** [Date]
**Team:** [Team Name] | **PdM/PO:** [Name] | **Tech Lead:** [Name]
**Checklist Version:** 2026-04 (Support Practice Council)

## Tier 1: Mandatory (Must have before launch)
| Item | Status | Notes |
|------|--------|-------|
| Solution Identity | DONE | [brief note] |
| Users & User Groups | IN PROGRESS | [what's missing] |
| ... | ... | ... |

**Tier 1 Gaps:** [count] items need attention

<!-- Tier 2 includes Expected Date because these items may ship after launch (see Rule 4) -->
## Tier 2: Strongly Recommended
| Item | Status | Expected Date | Notes |
|------|--------|---------------|-------|
| User Guide | NOT STARTED | TBD | |
| ... | ... | ... | ... |

**Tier 2 Gaps:** [count] items need attention

## Tier 3: Ideal State
| Item | Status | Notes |
|------|--------|-------|
| Built-in Help | N/A | [reason] |
| ... | ... | ... |

**Tier 3 Gaps:** [count] items to consider

## Action Items
1. [Task description] — **Priority: HIGH** (Tier 1 gap)
2. [Task description] — **Priority: MEDIUM** (Tier 2 gap)
3. [Task description] — **Priority: LOW** (Tier 3 gap)
```

### Plan File

The `support-plan.md` file is **always written** — it is the living record of the review and the persistence mechanism for resuming across sessions. Update the `Last Updated` field every time the file is modified.

Write to `support-plan.md` in the project root (or a path the user specifies).

### Task Creation (Jira)

After presenting the summary, ask the user if they want to **create Jira issues** for the gaps. If the Jira MCP is available, use the project the team specifies. Default issue type is **Task** (confirm with the user if their project uses a different scheme). Set priority based on tier:
- Tier 1 gaps → High priority, labeled `support-plan-mandatory`
- Tier 2 gaps → Medium priority, labeled `support-plan-recommended`
- Tier 3 gaps → Low priority, labeled `support-plan-ideal`

If Jira MCP is not available or the user declines, the plan file alone is sufficient — it already contains the full gap analysis and action items.

</the_process>

<critical_rules>

## Rules

1. **Cover every item** — All three tiers must be addressed. Never skip items because they seem irrelevant. If an item doesn't apply, record it as N/A with a reason.
2. **Don't interrogate** — Group related questions naturally. Don't fire 30 individual questions. Batch by category and let the user respond conversationally.
3. **Tier 1 gaps are blockers** — Make it clear that Tier 1 items must be resolved before launch. Frame them as blockers in the summary.
4. **Capture expected dates for Tier 2** — If a Tier 2 item won't be ready at launch, always ask for the expected delivery date.
5. **Don't prescribe answers** — The skill asks questions and records answers. Don't tell the team what their escalation path should be — that's their decision.
6. **Adapt to context** — If you already know details about the project (from conversation context or prior sessions), pre-fill what you can and confirm with the user rather than re-asking.
7. **Respect the source** — This question set comes from the UWM Support Practice Council (Jenni Sproul, Support TDM). Reference it as such if the team asks where these requirements come from.
8. **This is not a gate** — The skill helps teams prepare. It doesn't block launches. Frame it as "here's what you need to think about" not "you can't launch until."
9. **Always write the plan file** — `support-plan.md` is not optional. Write it after collecting project context and update it after each tier. This is how sessions resume.
10. **Update Last Updated** — Every time you modify `support-plan.md`, update the `Last Updated` field to the current date.
11. **Incident escalation requires all four roles** — Owning Team, PdM/PO, Leadership, and Specific Team Members must all be identified with names/roles. Do not accept "TBD" for this section — escalation paths must be concrete before launch.

## Common Mistakes to Avoid

- "This looks like a simple internal tool, so I'll skip the user groups question" → **No. Ask it. Internal tools still need support paths.**
- "The team seems busy so I'll only ask Tier 1" → **No. Cover all three tiers. Tier 2 and 3 can be quick if the answer is "not yet."**
- "I'll combine the summary into the conversation" → **No. Generate a clean, structured summary they can share with stakeholders.**

</critical_rules>

<examples>

<example>
<scenario>Team starting a support review for a new feature</scenario>
<interaction>
User: "support plan for the new Loan Calculator feature"
Assistant: "Starting a Support Plan Review for Loan Calculator.

A few things to confirm before we walk through the checklist:
- Is this a brand new feature, or replacing/enhancing something existing?
- What's the target launch date?
- Who's the PdM/PO and tech lead?"

User: "New feature, launching May 15. PdM is Sarah Chen, tech lead is Mike Torres."
Assistant: "Got it. Let's start with the mandatory requirements.

**Users & Access:**
Who uses Loan Calculator? Check all that apply:
- Borrower
- Broker / LO
- Internal UWM Teams/TMs
- Permission-based groups

And where do they access it — within an existing app or standalone?"

[Continues through all tiers...]
</interaction>
</example>

<example>
<scenario>Resuming a partially completed review</scenario>
<interaction>
User: "Let's pick up the support plan for Turbo"
Assistant: [Reads support-plan.md from project root]
"Found your existing support plan (last updated April 10). Tier 1 is complete and Tier 2 is partially done — Product Documentation shows User Guide in progress and Training Materials not started.

Let's continue from System Documentation (Runbook/SDD) — does that exist for Turbo?"
</interaction>
</example>

</examples>

<resources>

**Source:** Support Practice Council question set, version 2026-04. These requirements are still being refined by the Council — expect updates.

**Canonical source:** TBD — the Support Practice Council will publish a KB page with the official checklist. Update this reference when available.

**Checklist Version:** Update the `Checklist Version` in the plan file format template above when the Council publishes revisions. This lets teams know which version they reviewed against. **The checklist version and the plugin version (`plugin.json`) are independent.** The plugin version tracks skill improvements (process changes, bug fixes, new features). The checklist version tracks which Council question set is embedded. Bump them separately — a skill refactor doesn't change the checklist, and a Council update doesn't require a skill rewrite.

**Persistence:** `support-plan.md` in project root (or user-specified path) — always written, updated incrementally.

**Task Tracking (optional):** Jira issues labeled `support-plan-mandatory` / `support-plan-recommended` / `support-plan-ideal` in the team's project. Fallback is the plan file itself.

</resources>
