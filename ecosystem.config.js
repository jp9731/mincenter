module.exports = {
  apps: [
    {
      name: 'mincenter-site',
      script: './frontends/site/build/index.js',
      cwd: './frontends/site',
      instances: 'max', // CPU 코어 수만큼 인스턴스 생성
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 13000,
        API_URL: 'http://localhost:18080',
        PUBLIC_API_URL: 'https://api.mincenter.kr',
        SESSION_SECRET: process.env.SESSION_SECRET || 'your-session-secret'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 13000
      },
      error_file: './logs/site-error.log',
      out_file: './logs/site-out.log',
      log_file: './logs/site-combined.log',
      time: true,
      max_memory_restart: '1G',
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000,
      watch: false,
      ignore_watch: ['node_modules', 'logs'],
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'mincenter-admin',
      script: './frontends/admin/build/index.js',
      cwd: './frontends/admin',
      instances: 1, // 관리자 페이지는 단일 인스턴스
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 13001,
        API_URL: 'http://localhost:18080',
        PUBLIC_API_URL: 'https://api.mincenter.kr',
        SESSION_SECRET: process.env.ADMIN_SESSION_SECRET || 'your-admin-session-secret',
        ADMIN_EMAIL: process.env.ADMIN_EMAIL || 'admin@mincenter.kr'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 13001
      },
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      log_file: './logs/admin-combined.log',
      time: true,
      max_memory_restart: '1G',
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000,
      watch: false,
      ignore_watch: ['node_modules', 'logs'],
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ],

  deploy: {
    production: {
      user: 'your-user',
      host: 'your-server-ip',
      ref: 'origin/main',
      repo: 'git@github.com:your-username/your-repo.git',
      path: '/var/www/mincenter',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
}; 