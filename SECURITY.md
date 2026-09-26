# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for
receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities to: bitsgenix@gmail.com

**Please do not report security vulnerabilities through public GitHub issues.**

You should receive a response within 48 hours. If for some reason you do not, please follow up to ensure we received your original message.

Please include the following information in your report:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Preferred Languages

We prefer all communications to be in English.

## Policy

We follow the principle of Coordinated Vulnerability Disclosure.

## Extension Security

Since cdin-x is an extension ecosystem, the following security considerations apply:

### Registry Security
- Extensions are validated through `scripts/validate.lua` before being published
- Manifests declare dependencies and minimum cdin version requirements
- The runtime never executes extension source directly from the registry clone
- Official extensions are copied into the user's extension store before loading

### Sandboxing
- Extensions run in the same process as the editor
- Extensions have access to the full Lua API exposed by the C host
- Malicious extensions could potentially access any file the editor can access
- Only install extensions from trusted sources

### Dependency Safety
- Extensions should declare all dependencies in their manifest
- The manager resolves dependencies before loading
- Cycles are rejected at load time
