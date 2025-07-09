# Claude Custom Commands

Custom commands provide reusable automation for common development tasks. Each markdown file in this directory becomes a command accessible via forward slash (/).

## Available Commands

- `/audit` - Comprehensive dependency audit for security and updates
- `/test-gen` - Automatic test generation for specified files
- `/vuln-fix` - Security vulnerability detection and fixing
- `/perf-optimize` - Performance analysis and optimization

## How to Use

1. In Claude Code, type `/` followed by the command name
2. Add any arguments after the command
3. Claude will execute the tasks defined in the command file

### Examples
```
/audit
/test-gen src/utils/calculator.js
/vuln-fix --focus authentication
/perf-optimize frontend/components/
```

## Creating New Commands

1. Create a new `.md` file in this directory
2. The filename becomes the command name
3. Use `$arguments` placeholder to accept runtime arguments
4. Define clear tasks and expected outputs

### Command Template
```markdown
# Command Name

Brief description of what this command does.

## Tasks
1. First task
2. Second task
3. Third task

## Arguments
$arguments - Description of expected arguments

## Output
Description of what the command produces
```

## Best Practices

- Keep commands focused on a single purpose
- Provide clear task descriptions
- Include example usage
- Document expected inputs and outputs
- Make commands idempotent when possible