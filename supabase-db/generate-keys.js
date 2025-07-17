// generate-keys.js
const jwt = require('jsonwebtoken');

// Your JWT secret from .env
const JWT_SECRET = '9+dE3NnISqHPVtkZzJmTJP0Sw8z3Sl47GCDmbuuO/r4=';

// Generate anon key
const anonToken = jwt.sign(
  {
    iss: 'supabase-demo',
    role: 'anon',
    exp: Math.floor(Date.now() / 1000) + (20 * 365 * 24 * 60 * 60) // 20 years
  },
  JWT_SECRET
);

// Generate service role key
const serviceToken = jwt.sign(
  {
    iss: 'supabase-demo',
    role: 'service_role',
    exp: Math.floor(Date.now() / 1000) + (20 * 365 * 24 * 60 * 60) // 20 years
  },
  JWT_SECRET
);

console.log('ANON_KEY=' + anonToken);
console.log('SERVICE_ROLE_KEY=' + serviceToken);