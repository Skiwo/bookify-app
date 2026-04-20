# Norwegian Payroll — How POP Handles Taxes and Salaries

A practical guide to understanding how money flows through POP, what Norwegian tax rules apply, and why the system works the way it does.

---

## Why POP Is Involved in Payroll

When a freelancer is an **individual** (not a company), POP acts as their **legal employer** in Norway. This means:

- POP withholds income tax from each payment and sends it to the Norwegian Tax Authority (Skatteetaten)
- POP pays **employer's social contribution** (arbeidsgiveravgift) on top of each salary
- POP files monthly **payroll reports** (A-melding) to Skatteetaten
- The freelancer receives a **salary slip** (lønnslipp) for each payment

When a freelancer operates through a **company** (ENK or AS), none of this applies — they invoice directly, no tax is withheld, and POP just pays the invoice amount.

---

## Individual Payout — How the Math Works

A partner submits a work invoice for **10,000 NOK**. Here's where that money goes:

```
Partner pays:        10,000 NOK
                          │
                          │ minus POP fee (4.9%)
                          ▼
                      ─────────────────────────────────
                      gross_payout_amount = 9,510 NOK
                      ─────────────────────────────────
                          │
                          │ split between gross salary and employer tax
                          │ (employer tax is 14.1% OF gross salary,
                          │  embedded within gross_payout_amount)
                          ▼
                      ─────────────────────────────────
                      gross_salary      = 8,334 NOK   → freelancer's "brutto"
                      employer_tax      = 1,176 NOK   → POP pays to Skatteetaten
                      ─────────────────────────────────
                          │
                          │ minus income tax withheld (35%)
                          ▼
                      ─────────────────────────────────
                      salary_tax        = 2,900 NOK   → withheld, sent to Skatteetaten
                      payout_amount     = 5,434 NOK   → freelancer receives this
                      ─────────────────────────────────

Breakdown of 10,000 NOK:
  → 5,434  freelancer receives (54.3%)
  →   490  POP fee (4.9%)
  → 1,176  employer tax, paid by POP (11.8%)
  → 2,900  income tax withheld (29.0%)
```

### The Formulas

```
amount              = unit_price × quantity
platform_fee_amount = amount × platform_fee_rate         (default 4.9%)

gross_payout_amount = amount − platform_fee_amount − insurance_deduction

employer_tax_amount = gross_payout_amount / (1 + employer_tax_rate) × employer_tax_rate
gross_salary        = gross_payout_amount − employer_tax_amount

salary_tax_amount   = gross_salary × salary_tax_rate × salary_tax_multiplier
payout_amount       = gross_salary − salary_tax_amount
```

### Default Rates

| Rate | Default | What it is |
|------|---------|------------|
| `platform_fee` | **4.9%** | POP's service fee |
| `employer_tax` | **14.1%** | Arbeidsgiveravgift — employer's social contribution |
| `salary_tax` | **35%** | Skattetrekk — income tax withheld |

These are defaults. A freelance profile can have custom rates, and a `ClientSetting` can override the `platform_fee` for specific clients.

### Why Employer Tax Is Calculated Differently

Employer tax is **14.1% of gross salary** — not of the invoice amount. But since the invoice amount already *includes* the employer tax, we have to work backwards:

```
gross_payout_amount = gross_salary + employer_tax
                    = gross_salary + (gross_salary × 0.141)
                    = gross_salary × (1 + 0.141)
                    = gross_salary × 1.141

So:  gross_salary = gross_payout_amount / 1.141
     employer_tax = gross_payout_amount − gross_salary
```

---

## Tax Modes — Frikort and Half Tax

Not every payment is taxed at full rate. Norway has two special cases:

### Frikort (Zero Tax)

A **frikort** (tax-free card) is issued by Skatteetaten to people whose annual income is below a threshold (~88,000 NOK in 2024). It means: **don't withhold any income tax** from this person.

In POP, when a freelancer has a frikort for the year, admin sets `salary_tax_mode = zero` on their invoices. The multiplier becomes `0`, so no tax is withheld:

```
salary_tax_amount = gross_salary × 0.35 × 0 = 0
payout_amount     = gross_salary            (freelancer gets full gross salary)
```

Note: employer tax still applies — frikort only affects the freelancer's portion.

### Half Tax (`salary_tax_mode = half`)

The multiplier becomes `0.5`, so only half the normal tax is withheld:

```
salary_tax_amount = gross_salary × 0.35 × 0.5 = gross_salary × 0.175
```

Used when a person has multiple income sources and their tax card specifies a lower withholding rate for secondary income.

### Summary

| Mode | Multiplier | Example (gross_salary = 8,334) |
|------|-----------|-------------------------------|
| `normal` | 1.0 | Tax withheld: **2,900 NOK** |
| `half` | 0.5 | Tax withheld: **1,458 NOK** |
| `zero` | 0.0 | Tax withheld: **0 NOK** (frikort) |

`salary_tax_mode` only has effect if `freelance_profile.tax_cuts? = true` (Norwegian individual profiles). For international freelancers it's always `1`.

Tax mode is set by admin based on the freelancer's tax card from Skatteetaten.

---

## Tax Cards (Skattekort)

A **skattekort** (tax card) is a document from Skatteetaten that tells the employer how much tax to withhold. POP requests tax cards in bulk once a year:

1. Admin generates an XML request listing freelancers' personal numbers
2. The XML is manually uploaded to Skatteetaten
3. Skatteetaten returns a response XML with each person's tax card data
4. Admin uploads the response to POP (`/admin/tax_cards`)
5. POP updates each freelancer's `salary_tax` rate on their profile

If a freelancer has a **frikort**, their tax card comes back with `trekkfri = true` — admin then sets `salary_tax_mode = zero` on their invoices.

POP operates as two employers for tax card purposes:

| Employer | Sub-entity org number |
|----------|----------------------|
| Payout Partner (POP) | `824423482` |
| Salita | `976268385` |

Each freelancer needs to set their frikort for the right org number on `skatteetaten.no`.

---

## A-Melding — Monthly Payroll Reporting

Every employer in Norway must file an **A-melding** to Skatteetaten by the 5th of each month, reporting all salaries paid in the previous month. POP does this for all individual payouts.

The A-melding contains, per freelancer:
- Personal number
- Gross salary
- Tax withheld
- Employer tax
- Income type and description

In POP, each `SalarySlip` is linked to an `AMelding` record. Status flow:

```
pending → approved → submitted → accepted → scheduled → paid
```

The freelancer's salary slip shows `pending` until the A-melding is accepted by Skatteetaten.

---

## Line Types — What Gets Taxed

Not all lines on an invoice are taxed the same way:

| Line type | Employer tax | Income tax | What it represents |
|-----------|-------------|------------|--------------------|
| `work` | ✅ Yes | ✅ Yes | Standard billable hours |
| `benefit` | ✅ Yes | ✅ Yes | Fringe benefits (company phone, etc.) |
| `extra` | ✅ Yes | ✅ Yes | Additional compensation |
| `expense` | ❌ No | ❌ No | Reimbursed costs (receipt required) |
| `mileage` | Split | Split | Travel compensation — up to 3.50 NOK/km is tax-free; above that is taxed |
| `diet` | Split | Split | Per diem — split into non-taxable and taxable portions |

**Expense lines** are fully passed through — 1,000 NOK expense = 1,000 NOK payout. No deductions.

**Mileage** has a legal cap of **3.50 NOK/km** (350 øre). If the rate is 3.50 or below: no tax. If above: the excess is treated as salary.

**Diet** lines have two explicit fields: `diet_non_taxable_unit_price` and `diet_taxable_unit_price`. The non-taxable portion is passed through; the taxable portion goes through the full salary calculation.

---

## Organization Payouts — No Payroll

When a freelancer uses a company (ENK or AS), POP does **not** act as employer. The flow is:

- No income tax is withheld
- No employer tax is paid
- No A-melding is filed
- No salary slip is generated
- `payout_amount = amount` (the full invoice amount, minus POP fee)

The company is responsible for paying its own taxes. POP just processes the payment.

---

## Insurance Deduction

Some clients (via `ClientSetting`) have **occupational injury insurance** (yrkesskadeforsikring). For `work` lines, POP deducts an insurance contribution before calculating salary:

```
insurance_deduction = insurance_rate × work_hours
gross_payout_amount = amount − platform_fee − insurance_deduction
```

The rate is per hour and specific to the occupation code. This is set up per-client in the admin panel.

---

## What the Freelancer Sees

After an individual payout is processed, the freelancer receives a **salary slip** (`SalarySlip`) showing:

```
Gross salary (bruttolønn):        8,334 NOK
  − Income tax withheld (35%):   −2,900 NOK
─────────────────────────────────────────
Net payout (nettolønn):           5,434 NOK
```

They can view all their salary slips in the Freelancer Self-Service Portal at `/f/salary_slips`.

The employer tax (1,176 NOK) is paid by POP directly to Skatteetaten — the freelancer doesn't see it on their slip, but it's the reason the math works out to less than 10,000 NOK total.

---

## Quick Reference

| Concept | Norwegian term | POP field |
|---------|---------------|-----------|
| Invoice amount | Fakturabeløp | `amount` |
| POP service fee | Plattformavgift | `platform_fee_amount` |
| Employer's social contribution | Arbeidsgiveravgift | `employer_tax_amount` |
| Freelancer's gross salary | Bruttolønn | `gross_salary` |
| Income tax withheld | Skattetrekk | `salary_tax_amount` |
| Freelancer's net payout | Nettolønn | `payout_amount` |
| Tax-free card | Frikort | `salary_tax_mode = zero` |
| Monthly payroll report | A-melding | `AMelding` model |
| Tax card | Skattekort | `TaxCard` model |
| Salary document | Lønnslipp | `SalarySlip` model |
