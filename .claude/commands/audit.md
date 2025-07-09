# Dependency Audit Command

Perform a comprehensive audit of project dependencies to identify security vulnerabilities, outdated packages, and licensing issues.

## Tasks

1. **Security Vulnerability Scan**
   - Check npm packages using `npm audit` if package.json exists
   - Check Python packages using `pip-audit` if requirements.txt exists
   - Identify critical, high, medium, and low severity vulnerabilities

2. **Outdated Package Detection**
   - List all packages that have newer versions available
   - Categorize updates by major, minor, and patch versions
   - Highlight packages that haven't been updated in over 6 months

3. **License Compliance Check**
   - Scan all dependencies for their licenses
   - Flag any packages with restrictive licenses (GPL, AGPL)
   - Ensure compatibility with project's license

4. **Dependency Tree Analysis**
   - Identify duplicate packages with different versions
   - Find unused dependencies
   - Detect circular dependencies

5. **Generate Audit Report**
   - Create a markdown report with all findings
   - Include remediation recommendations
   - Prioritize issues by severity and impact

## Arguments
$arguments

## Output
Generate a comprehensive audit report in markdown format, saved as `dependency-audit-$(date +%Y%m%d).md`