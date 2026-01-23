# Threat Model

This document describes the threat model for the Cloud Security Landing Zone.

---

## Scope

| In Scope | Out of Scope |
|----------|--------------|
| AWS account security controls | Application-level security |
| IAM and access management | Business logic vulnerabilities |
| Network security | Third-party SaaS integrations |
| Data protection | Physical security |
| Logging and monitoring | Social engineering |

---

## Assets

### Critical Assets

| Asset | Description | Sensitivity |
|-------|-------------|-------------|
| KMS CMK | Master encryption key | Critical |
| CloudTrail logs | Audit trail | High |
| IAM credentials | Access to resources | Critical |
| Terraform state | Infrastructure configuration | High |
| Break-glass role | Emergency administrative access | Critical |

### Supporting Assets

| Asset | Description | Sensitivity |
|-------|-------------|-------------|
| VPC configuration | Network isolation | Medium |
| Security groups | Traffic filtering | Medium |
| Config rules | Compliance monitoring | Low |
| SNS topics | Alert delivery | Low |

---

## Threat Actors

| Actor | Motivation | Capability | Likelihood |
|-------|------------|------------|------------|
| External attacker | Financial gain, disruption | Medium-High | Medium |
| Insider threat | Data theft, sabotage | High | Low |
| Compromised vendor | Supply chain attack | Medium | Low |
| Automated scanner | Opportunistic exploitation | Low-Medium | High |
| Nation state | Espionage, disruption | Very High | Low |

---

## Attack Scenarios

### Scenario 1: Credential Compromise

**Threat:** Attacker obtains IAM user credentials (phishing, leaked secrets).

**Attack path:**
```
Phishing email --> User clicks link --> Credentials harvested
     --> Attacker authenticates --> Access to resources
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| MFA requirement | Credentials alone insufficient |
| Permission boundaries | Limits privilege escalation |
| CloudTrail logging | Detect unusual activity |
| Console login alert | Detect brute force |
| Access key rotation | Reduce exposure window |

**Residual risk:** Medium (MFA bypass techniques exist)

---

### Scenario 2: Privilege Escalation

**Threat:** Compromised role attempts to create higher-privilege role.

**Attack path:**
```
Compromised role --> iam:CreateRole --> New admin role
     --> Assume new role --> Full account access
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| Permission boundaries | New roles inherit boundary |
| IAM policy change alert | Detect role creation |
| Config rule | Detect overly permissive roles |

**Residual risk:** Low (boundary prevents unbounded roles)

---

### Scenario 3: Data Exfiltration

**Threat:** Attacker extracts sensitive data from S3 or databases.

**Attack path:**
```
Compromised credentials --> Access S3 bucket --> Download data
     --> Exfiltrate via allowed egress
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| S3 data events in CloudTrail | Detect bulk access |
| Baseline SG egress restriction | Limit exfiltration paths |
| S3 public access block | Prevent public exposure |
| KMS encryption | Data useless without key access |

**Residual risk:** Medium (HTTPS egress allows some exfiltration)

---

### Scenario 4: Log Tampering

**Threat:** Attacker attempts to delete audit logs to cover tracks.

**Attack path:**
```
Compromised admin --> Delete CloudTrail logs --> No audit trail
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| S3 versioning | Deleted objects recoverable |
| Log file validation | Detect tampering |
| S3 bucket policy | Restrict delete access |
| MFA delete (if enabled) | Require MFA for deletion |

**Residual risk:** Low (versioning preserves deleted logs)

---

### Scenario 5: Cryptographic Key Compromise

**Threat:** Attacker gains access to KMS key and decrypts sensitive data.

**Attack path:**
```
Compromised admin --> kms:Decrypt --> Access encrypted data
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| Key policy restrictions | Limit who can use key |
| CloudTrail logging | Detect key usage |
| KMS deletion alert | Detect key destruction |
| Annual key rotation | Limit exposure of key material |

**Residual risk:** Medium (admin access includes key access)

---

### Scenario 6: Network Lateral Movement

**Threat:** Attacker in one workload moves to others.

**Attack path:**
```
Compromised instance --> Scan internal network --> Find other targets
     --> Exploit vulnerability --> Spread
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| Default deny SG | No implicit connectivity |
| Baseline SG | Restricted egress |
| VPC Flow Logs | Detect scanning |
| Private subnets | No direct internet access |

**Residual risk:** Low (SGs limit lateral movement)

---

### Scenario 7: Supply Chain Attack

**Threat:** Malicious code in Terraform provider or module.

**Attack path:**
```
Compromised provider --> Deployed via Terraform
     --> Backdoor in infrastructure
```

**Controls:**
| Control | Mitigation |
|---------|------------|
| Provider version pinning | Known good versions |
| Provider lock file | Hash verification |
| Code review | Human inspection of changes |
| Checkov/tfsec | Detect suspicious patterns |

**Residual risk:** Medium (sophisticated attacks may evade detection)

---

## Risk Matrix

```
                        IMPACT
              Low    Medium    High    Critical
         +--------+--------+--------+--------+
High     |   M    |   H    |   C    |   C    |
         +--------+--------+--------+--------+
Medium   |   L    |   M    |   H    |   C    |  LIKELIHOOD
         +--------+--------+--------+--------+
Low      |   L    |   L    |   M    |   H    |
         +--------+--------+--------+--------+
Very Low |   L    |   L    |   L    |   M    |
         +--------+--------+--------+--------+

L = Low Risk    M = Medium Risk    H = High Risk    C = Critical Risk
```

### Risk Summary

| Scenario | Likelihood | Impact | Risk Level |
|----------|------------|--------|------------|
| Credential compromise | Medium | High | High |
| Privilege escalation | Low | Critical | Medium |
| Data exfiltration | Medium | High | High |
| Log tampering | Low | High | Medium |
| Key compromise | Low | Critical | Medium |
| Lateral movement | Low | Medium | Low |
| Supply chain | Low | High | Medium |

---

## Mitigations Summary

### Implemented Controls

| Category | Controls |
|----------|----------|
| Identity | MFA, permission boundaries, break-glass monitoring |
| Detection | CloudTrail, 5 alerts, GuardDuty, Config rules |
| Network | VPC isolation, default deny, flow logs |
| Data | KMS encryption, S3 hardening, public block |
| Prevention | Checkov/tfsec gates, policy-as-code |

### Recommended Additional Controls

| Control | Risk Addressed | Priority |
|---------|----------------|----------|
| AWS Organizations SCPs | Privilege escalation | High |
| VPC endpoints | Data exfiltration | Medium |
| S3 Object Lock | Log tampering | Medium |
| AWS Backup | Data destruction | Medium |
| Network ACLs | Lateral movement | Low |

---

## Assumptions

1. AWS infrastructure itself is secure
2. Terraform state is stored securely (encrypted, access controlled)
3. CI/CD pipeline credentials are protected
4. Alert recipients respond to notifications
5. Exception process is followed

---

## Review Schedule

| Review Type | Frequency |
|-------------|-----------|
| Threat model update | Annually |
| Control effectiveness | Quarterly |
| New threat assessment | As needed |
| Post-incident review | After any incident |
