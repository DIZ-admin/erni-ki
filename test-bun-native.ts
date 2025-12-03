// Test native TypeScript execution with Bun
interface User {
  id: number;
  name: string;
  email: string;
}

const users: User[] = [
  { id: 1, name: 'Alice', email: 'alice@example.com' },
  { id: 2, name: 'Bob', email: 'bob@example.com' },
];

// Test async/await with fetch
async function fetchExample() {
  try {
    const response = await fetch('https://api.github.com/repos/oven-sh/bun');
    const data = await response.json();
    return {
      name: data.name,
      stars: data.stargazers_count,
      description: data.description,
    };
  } catch (error) {
    console.error('Fetch failed:', error);
    return null;
  }
}

// Main execution
console.log('🎯 Testing Bun native TypeScript execution\n');

console.log('📋 Users:');
users.forEach(user => {
  console.log(`  - ${user.name} <${user.email}>`);
});

console.log('\n🌐 Fetching Bun repo info...');
const repoInfo = await fetchExample();

if (repoInfo) {
  console.log(`\n⭐ ${repoInfo.name}`);
  console.log(`   Stars: ${repoInfo.stars}`);
  console.log(`   Description: ${repoInfo.description}`);
}

console.log('\n✅ TypeScript executed natively without compilation!');
