// Commitlint configuration for the erni-ki project
// Validates Conventional Commits for automated releases

module.exports = {
  // Extend the default configuration
  extends: ['@commitlint/config-conventional'],

  // Parser options
  parserPreset: {
    parserOpts: {
      headerPattern: /^(\w*)(?:\((.*)\))?: (.*)$/,
      headerCorrespondence: ['type', 'scope', 'subject'],
    },
  },

  // Validation rules
  rules: {
    // Commit type
    'type-enum': [
      2,
      'always',
      [
        'feat', // new functionality
        'fix', // bug fix
        'docs', // documentation changes
        'style', // formatting/non-functional style changes
        'refactor', // code refactor
        'perf', // performance improvement
        'test', // adding tests
        'chore', // build related changes or general chores
        'ci', // CI/CD adjustments
        'build', // build system updates
        'revert', // revert changes
        'security', // security fixes
        'deps', // dependency updates
        'config', // configuration changes
        'docker', // Docker changes
        'deploy', // deployment changes
      ],
    ],

    // Allowed scopes
    'scope-enum': [
      2,
      'always',
      [
        'auth', // authentication service
        'nginx', // nginx configuration
        'docker', // docker files
        'compose', // docker-compose changes
        'ci', // CI/CD pipeline
        'docs', // documentation
        'config', // configuration files
        'monitoring', // monitoring stack
        'security', // security changes
        'ollama', // Ollama service
        'openwebui', // Open WebUI
        'postgres', // PostgreSQL
        'redis', // Redis
        'searxng', // SearXNG
        'cloudflare', // Cloudflare
        'tika', // Apache Tika
        'edgetts', // EdgeTTS
        'mcposerver', // MCP Server
        'watchtower', // Watchtower
        'deps', // dependencies
        'tests', // tests
        'lint', // linting
        'format', // formatting
      ],
    ],

    // Required fields formatting
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],

    // Line length
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
    'footer-max-line-length': [2, 'always', 100],

    // Formatting tweaks
    'body-leading-blank': [1, 'always'],
    'footer-leading-blank': [1, 'always'],

    // Optional overrides for breaking changes messaging
    'body-max-length': [0],
    'footer-max-length': [0],
  },

  // Ignore specific commit patterns
  ignores: [
    // Ignore merge commits
    commit => commit.includes('Merge'),
    // Ignore Renovate commits
    commit => commit.includes('renovate'),
    // Ignore Dependabot commits
    commit => commit.includes('dependabot'),
  ],

  // Interactive prompt hints (used by git-cz)
  prompt: {
    questions: {
      type: {
        description: 'Choose the change type:',
      },
      scope: {
        description: 'Specify the scope (optional):',
      },
      subject: {
        description: 'Provide a short description:',
      },
      body: {
        description: 'Detailed description (optional):',
      },
      isBreaking: {
        description: 'Does it contain breaking changes?',
      },
      breaking: {
        description: 'Describe the breaking change:',
      },
      isIssueAffected: {
        description: 'Does this affect any open issues?',
      },
      issues: {
        description: 'Add issue references (e.g., "fix #123", "re #123"):',
      },
    },
  },
};
