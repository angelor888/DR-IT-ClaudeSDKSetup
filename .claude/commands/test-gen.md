# Test Generation Command

Automatically generate comprehensive test suites for specified files or modules.

## Tasks

1. **Analyze Target Code**
   - Parse the file/module specified in arguments: $arguments
   - Identify all functions, classes, and methods
   - Understand the code's purpose and dependencies

2. **Generate Unit Tests**
   - Create test cases for each function/method
   - Include edge cases and boundary conditions
   - Test error handling and exceptions
   - Ensure proper mocking of external dependencies

3. **Generate Integration Tests** (if applicable)
   - Test interactions between components
   - Verify data flow and transformations
   - Test API endpoints if present

4. **Test Coverage Analysis**
   - Aim for at least 80% code coverage
   - Identify untested code paths
   - Generate tests for uncovered branches

5. **Test Framework Selection**
   - Use Jest for JavaScript/TypeScript
   - Use pytest for Python
   - Use appropriate framework for other languages

## Example Usage
- `/test-gen src/utils/calculator.js` - Generate tests for calculator module
- `/test-gen api/endpoints/` - Generate tests for all API endpoints

## Output
- Create test files following naming convention: `<filename>.spec.js` or `<filename>.test.js`
- Place tests in appropriate test directory
- Include setup and teardown functions
- Add descriptive test names and comments