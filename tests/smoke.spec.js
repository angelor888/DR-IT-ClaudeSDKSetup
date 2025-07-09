/**
 * Smoke Test Suite
 * Basic tests to ensure the project structure and scripts are functional
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('DR-IT-ClaudeSDKSetup Smoke Tests', () => {
  const projectRoot = path.join(__dirname, '..');
  
  describe('Project Structure', () => {
    test('should have required directories', () => {
      const requiredDirs = [
        'configs',
        'scripts', 
        'sdk-examples',
        'SOPs',
        'docs',
        'tests'
      ];
      
      requiredDirs.forEach(dir => {
        const dirPath = path.join(projectRoot, dir);
        expect(fs.existsSync(dirPath)).toBe(true);
      });
    });
    
    test('should have Claude.md files', () => {
      const claudeMdFiles = [
        'Claude.md',
        'configs/Claude.md',
        'scripts/Claude.md',
        'sdk-examples/Claude.md',
        'SOPs/Claude.md'
      ];
      
      claudeMdFiles.forEach(file => {
        const filePath = path.join(projectRoot, file);
        expect(fs.existsSync(filePath)).toBe(true);
      });
    });
  });
  
  describe('Scripts', () => {
    test('should have executable setup scripts', () => {
      const scripts = [
        'scripts/setup-all.sh',
        'scripts/setup-mcp.sh',
        'scripts/setup-sdk.sh',
        'scripts/setup-autoupdate.sh',
        'scripts/setup-dev-toolchain.sh',
        'scripts/verify-installation.sh',
        'scripts/verify-toolchain.sh'
      ];
      
      scripts.forEach(script => {
        const scriptPath = path.join(projectRoot, script);
        expect(fs.existsSync(scriptPath)).toBe(true);
        
        // Check if executable
        const stats = fs.statSync(scriptPath);
        const isExecutable = (stats.mode & 0o111) !== 0;
        expect(isExecutable).toBe(true);
      });
    });
  });
  
  describe('Configuration Files', () => {
    test('should have valid JSON configs', () => {
      const jsonFiles = [
        'configs/claude-desktop-config.json'
      ];
      
      jsonFiles.forEach(file => {
        const filePath = path.join(projectRoot, file);
        expect(fs.existsSync(filePath)).toBe(true);
        
        // Validate JSON
        const content = fs.readFileSync(filePath, 'utf8');
        expect(() => JSON.parse(content)).not.toThrow();
      });
    });
    
    test('should have docker-compose.yml', () => {
      const dockerComposePath = path.join(projectRoot, 'configs/docker-compose.yml');
      expect(fs.existsSync(dockerComposePath)).toBe(true);
    });
  });
  
  describe('SDK Examples', () => {
    test('should have Python examples', () => {
      const pythonExamplesDir = path.join(projectRoot, 'sdk-examples/python');
      expect(fs.existsSync(pythonExamplesDir)).toBe(true);
      
      const pythonFiles = fs.readdirSync(pythonExamplesDir)
        .filter(f => f.endsWith('.py'));
      expect(pythonFiles.length).toBeGreaterThan(0);
    });
    
    test('should have TypeScript examples', () => {
      const tsExamplesDir = path.join(projectRoot, 'sdk-examples/typescript');
      expect(fs.existsSync(tsExamplesDir)).toBe(true);
      
      const tsFiles = fs.readdirSync(tsExamplesDir)
        .filter(f => f.endsWith('.ts'));
      expect(tsFiles.length).toBeGreaterThan(0);
    });
  });
  
  describe('Installation Script', () => {
    test('should have main install.sh', () => {
      const installPath = path.join(projectRoot, 'install.sh');
      expect(fs.existsSync(installPath)).toBe(true);
      
      // Check if executable
      const stats = fs.statSync(installPath);
      const isExecutable = (stats.mode & 0o111) !== 0;
      expect(isExecutable).toBe(true);
    });
  });
});

// Entry point check - ensure the project can be imported without errors
describe('Entry Point', () => {
  test('should load without throwing', () => {
    expect(() => {
      // Since this is a setup/configuration project, 
      // we just verify the structure exists
      const projectPackage = path.join(__dirname, '..', 'package.json');
      if (fs.existsSync(projectPackage)) {
        require(projectPackage);
      }
    }).not.toThrow();
  });
});