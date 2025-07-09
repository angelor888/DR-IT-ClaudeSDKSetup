module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.spec.js'],
  collectCoverageFrom: [
    'scripts/**/*.js',
    'sdk-examples/**/*.js',
    '!**/node_modules/**',
    '!**/venv/**'
  ],
  coverageThreshold: {
    global: {
      branches: 50,
      functions: 50,
      lines: 50,
      statements: 50
    }
  },
  verbose: true,
  testTimeout: 30000
};