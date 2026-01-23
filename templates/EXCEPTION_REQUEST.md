# Security Exception Request

## Request Information

| Field | Value |
|-------|-------|
| Request ID | EXC-YYYY-NNN |
| Date | YYYY-MM-DD |
| Requestor | Name (email) |
| Team | Team name |
| Approver | (Security team use) |

---

## Exception Details

### Control Being Excepted

Identify the specific security control:

- [ ] Checkov rule: `CKV_AWS_XXX`
- [ ] tfsec rule: `aws-xxx-xxx`
- [ ] AWS Config rule: `rule-name`
- [ ] Other: _________________

### Resource(s) Affected

```
Resource type:
Resource name/ID:
Terraform file path:
```

---

## Business Justification

### Why is this exception needed?

_Explain the business requirement that conflicts with the security control._

### What alternatives were considered?

| Alternative | Reason Not Viable |
|-------------|-------------------|
| | |
| | |

### What is the impact of NOT granting this exception?

_Describe the business impact if the exception is denied._

---

## Risk Assessment

### Threat Scenario

_What could go wrong if this control is not in place?_

### Likelihood

- [ ] High - Attack is actively attempted or common
- [ ] Medium - Attack is possible but not common
- [ ] Low - Attack requires significant effort or access

### Impact

- [ ] Critical - Data breach, significant financial loss, regulatory penalty
- [ ] High - Service disruption, data exposure (non-sensitive)
- [ ] Medium - Limited exposure, contained impact
- [ ] Low - Minimal impact, easily recoverable

### Risk Level

| | Low Impact | Medium Impact | High Impact | Critical Impact |
|---|---|---|---|---|
| **High Likelihood** | Medium | High | Critical | Critical |
| **Medium Likelihood** | Low | Medium | High | Critical |
| **Low Likelihood** | Low | Low | Medium | High |

**Assessed Risk Level:** _______________

---

## Compensating Controls

_List controls that reduce the risk of this exception._

| Compensating Control | How It Mitigates Risk |
|---------------------|----------------------|
| | |
| | |
| | |

---

## Exception Scope

### Duration

- [ ] Permanent (annual review required)
- [ ] Temporary - Expires: YYYY-MM-DD
- [ ] Conditional - Until: _________________

### Environment(s)

- [ ] Production
- [ ] Non-production
- [ ] Shared services
- [ ] All environments

---

## Implementation

### Code Change Required

```hcl
# Example: Adding Checkov skip annotation
resource "aws_xxx" "example" {
  #checkov:skip=CKV_AWS_XXX:Exception EXC-YYYY-NNN - Brief reason

  # resource configuration
}
```

### Monitoring

_How will this exception be monitored?_

| Metric/Alert | Purpose |
|--------------|---------|
| | |

---

## Review and Approval

### Security Review

| Criteria | Assessment |
|----------|------------|
| Business justification valid | Yes / No / Needs clarification |
| Risk assessment accurate | Yes / No / Needs adjustment |
| Compensating controls adequate | Yes / No / Needs enhancement |
| Scope appropriately limited | Yes / No / Needs narrowing |
| Duration reasonable | Yes / No / Needs adjustment |

### Decision

- [ ] **Approved** - Exception granted as requested
- [ ] **Approved with conditions** - See notes below
- [ ] **Denied** - See notes below
- [ ] **Deferred** - More information required

### Conditions (if applicable)

_List any conditions that must be met._

1.
2.
3.

### Notes

_Additional notes from security review._

---

## Signatures

| Role | Name | Date |
|------|------|------|
| Requestor | | |
| Security Reviewer | | |
| Approver | | |

---

## Post-Approval Tracking

### Implementation Checklist

- [ ] Skip annotation added to code
- [ ] Exception documented in registry
- [ ] Compensating controls implemented
- [ ] Monitoring configured
- [ ] Review reminder set (if temporary)

### Registry Entry

| Field | Value |
|-------|-------|
| Exception ID | |
| Status | Active |
| Next Review | |
| Owner | |

---

*Template version: 1.0*
