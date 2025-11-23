// Global environment setup for erni-ki project tests
import { execSync } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';

export async function setup() {
  console.log('🚀 Setting up test environment...');

  // Create necessary directories for tests
  const testDirs = ['tests/fixtures', 'tests/mocks', 'tests/integration', 'tests/unit', 'coverage'];

  testDirs.forEach(dir => {
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
      console.log(`✅ Directory created: ${dir}`);
    }
  });

  // Check availability of test services
  await checkTestServices();

  // Configure test database (if needed)
  await setupTestDatabase();

  console.log('✅ Test environment ready');
}

export async function teardown() {
  console.log('🧹 Cleaning up test environment...');

  // Clean up test data
  await cleanupTestData();

  console.log('✅ Test environment cleaned');
}

async function checkTestServices() {
  const services = [
    {
      name: 'PostgreSQL',
      command: 'pg_isready -h localhost -p 5432',
      optional: true,
    },
    {
      name: 'Redis',
      command: 'redis-cli -h localhost -p 6379 ping',
      optional: true,
    },
  ];

  for (const service of services) {
    try {
      execSync(service.command, { stdio: 'ignore' });
      console.log(`✅ ${service.name} available`);
    } catch (error) {
      if (service.optional) {
        console.log(`⚠️  ${service.name} unavailable (optional)`);
      } else {
        throw new Error(`❌ ${service.name} unavailable and required for tests`);
      }
    }
  }
}

async function setupTestDatabase() {
  // Here you can add test DB configuration
  // For example, schema creation, migrations, etc.
  console.log('📊 Setting up test database...');

  // Setup example (uncomment if needed)
  /*
  try {
    execSync('createdb test_erni_ki', { stdio: 'ignore' });
    console.log('✅ Test database created');
  } catch (error) {
    console.log('⚠️  Test database already exists or is unavailable');
  }
  */
}

async function cleanupTestData() {
  // Cleanup temporary files and data after tests
  console.log('🗑️  Cleaning up temporary data...');

  // Here you can add cleanup logic
  // For example, deleting test files, clearing cache, etc.
}
