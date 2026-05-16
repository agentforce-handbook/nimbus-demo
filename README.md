# Nimbus Electronics Demo — Agentforce Handbook Companion Code

Companion code for **"The Agentforce Handbook"** by Abhi Rathna.

This repository contains the Nimbus Electronics demo org metadata referenced throughout the book, including Agent Scripts, Apex actions, Flows, custom objects, and sample data.

## What's Included

| Component | Description | Book Reference |
|-----------|-------------|----------------|
| **NimbusServiceAgent** | Multi-subagent customer service agent with routing | Chapters 4, 9 |
| **NimbusOrderStatusAgent** | Standalone order status lookup agent | Chapter 4 |
| **NimbusWarrantyCheckAction** | Apex invocable action for warranty verification | Chapter 7 |
| **Nimbus_Get_Order_Status** | Flow that looks up orders by number + email | Chapter 4 |
| **Nimbus_Check_If_Order_Late** | Flow that checks if delivery is overdue | Chapter 4 |
| **Nimbus_Get_Shipping_Status** | Flow that returns carrier and tracking info | Chapter 7 |
| **Nimbus_Order__c** | Custom object for demo orders | Chapter 4 |
| **Nimbus_Device_Registration__c** | Custom object for warranty tracking | Chapter 7 |

## Prerequisites

- A Salesforce org with **Agentforce** enabled (Developer Edition or sandbox)
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) installed
- Git

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/agentforce-handbook/nimbus-demo.git
cd nimbus-demo
```

### 2. Authorize your org

```bash
sf org login web --alias nimbus-dev --set-default
```

### 3. Deploy metadata

```bash
sf project deploy start --target-org nimbus-dev
```

### 4. Assign the permission set

```bash
sf org assign permset --name Nimbus_Demo_User --target-org nimbus-dev
```

Also assign the permission set to your Agentforce service agent user:

```bash
sf org assign permset --name Nimbus_Demo_User \
  --on-behalf-of YOUR_AGENT_USER@example.com \
  --target-org nimbus-dev
```

### 5. Import sample data

```bash
sf data import tree --plan data/sample-data-plan.json --target-org nimbus-dev
```

### 6. Open the org and test

```bash
sf org open --target-org nimbus-dev
```

Navigate to **Setup → Agentforce** to see the deployed agents. Open an agent and use the **Preview** panel to test.

## Sample Test Scenarios

### Order Status Lookup
> "What's the status of my order? My email is sarah.chen@example.com"

The agent will verify identity and look up orders for that customer. Sarah has two orders — one shipped (NimbusPad Pro 12) and one that may be late (NimbusBook Air 14, estimated delivery was April 20).

### Warranty Check
> "Is my NimbusPad still under warranty? Serial number NIM-PAD-2024-00142"

The agent will check the device registration and confirm the NimbusPad Pro 12 has Standard coverage through June 2027.

### Expired Warranty
> "I need warranty service for serial NIM-PAD-2022-00999, email alex.kumar@example.com"

The agent will find the 2022 NimbusPad 10 whose warranty expired in March 2024.

## Agent Script Syntax

The agents in this repo use **Agent Script**, Salesforce's domain-specific language for Agentforce agents. Key syntax:

- `@variables.name` — Reference agent variables
- `run @actions.name` — Execute an action
- `@utils.transition to @subagent.name` — Route to a subagent
- `instructions:|` — Static instruction block
- `instructions:->` — Procedural (dynamic) instruction block
- `{!@variables.name}` — Template expression within instructions

For the full Agent Script reference, see [Salesforce Documentation](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script.html).

## Project Structure

```
nimbus-demo/
├── force-app/main/default/
│   ├── aiAuthoringBundles/       # Agent Script definitions
│   │   ├── NimbusServiceAgent/   # Multi-subagent service agent
│   │   └── NimbusOrderStatusAgent/ # Standalone order agent
│   ├── classes/                  # Apex invocable actions
│   ├── flows/                    # Autolaunched flows for agent actions
│   ├── objects/                  # Custom object definitions
│   └── permissionsets/           # Permission set for demo access
├── data/                         # Sample data for testing
└── README.md
```

## Companion Skills (Claude Code)

This repo includes Claude Code skills for building Agentforce agents. Install them by cloning this repo and opening it in Claude Code.

| Skill | Description | Book Reference |
|-------|-------------|----------------|
| `/agentforce:design-agent` | Generate a complete agent design from a business process | Ch4, Ch5 |
| `/agentforce:build-apex-action` | Generate production-ready Apex invocable actions with tests | Ch7 |
| `/agentforce:audit-agent` | Audit agent metadata against handbook best practices | Ch4, Ch5, Ch7 |
| `/agentforce:build-custom-connection` | Build custom connection metadata for Agentforce | Ch11 |

Skills share a common data contract ([agent-design-v1.schema.json](agent-contract/agent-design-v1.schema.json)) and validation rules ([validation-rules.json](validation-rules.json)).

For machine-readable documentation, see [llms.txt](llms.txt).

## License

This code is provided as a companion to "The Agentforce Handbook" for educational purposes. See [LICENSE](LICENSE) for details.
