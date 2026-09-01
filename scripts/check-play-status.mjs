/**
 * Omniverse Labs - Node.js Google Play API Status Checker
 * Self-contained JWT bearer authentication with zero external dependencies.
 */

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import https from 'https';

const PACKAGE_NAME = process.argv[2] || process.env.PLAY_CONSOLE_PACKAGE || 'com.omniverselabs.anotadordejuegos';
const KEY_PATH = process.env.PLAY_CONSOLE_JSON_KEY_PATH || path.resolve(process.cwd(), 'service_account.json');

function base64Url(data) {
  return Buffer.from(data).toString('base64url');
}

async function getAccessToken(keyData) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: keyData.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  const encodedHeader = base64Url(JSON.stringify(header));
  const encodedClaim = base64Url(JSON.stringify(claimSet));
  const signatureInput = `${encodedHeader}.${encodedClaim}`;

  const signer = crypto.createSign('RSA-SHA256');
  signer.update(signatureInput);
  const signature = signer.sign(keyData.private_key, 'base64url');

  const jwt = `${signatureInput}.${signature}`;

  const postData = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt
  }).toString();

  return new Promise((resolve, reject) => {
    const req = https.request('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body).access_token);
        } else {
          reject(new Error(`Failed to fetch token: ${body}`));
        }
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function apiRequest(url, token, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const headers = { 'Authorization': `Bearer ${token}` };
    let payload = null;
    if (body) {
      payload = JSON.stringify(body);
      headers['Content-Type'] = 'application/json';
      headers['Content-Length'] = Buffer.byteLength(payload);
    }
    const req = https.request(url, { method, headers }, res => {
      let responseBody = '';
      res.on('data', chunk => responseBody += chunk);
      res.on('end', () => {
        try {
          const json = responseBody ? JSON.parse(responseBody) : {};
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(json);
          } else {
            reject({ status: res.statusCode, data: json });
          }
        } catch (err) {
          reject({ status: res.statusCode, raw: responseBody });
        }
      });
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function main() {
  console.log(`\n============================================================`);
  console.log(`   Omniverse Labs - Google Play API Status (Node.js)       `);
  console.log(`============================================================`);
  console.log(`📦 Package: ${PACKAGE_NAME}\n`);

  if (!fs.existsSync(KEY_PATH)) {
    console.error(`❌ Missing service account file: ${KEY_PATH}`);
    console.error(`   Provide it via PLAY_CONSOLE_JSON_KEY_PATH or save as service_account.json in the workspace root.\n`);
    process.exit(1);
  }

  const keyData = JSON.parse(fs.readFileSync(KEY_PATH, 'utf-8'));
  const token = await getAccessToken(keyData);

  // 1. Create Edit
  const edit = await apiRequest(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/edits`, token, 'POST', {});
  const editId = edit.id;
  console.log(`✅ Connected to Google Play Developer API (Edit ID: ${editId})`);

  // 2. Query Tracks
  const tracksRes = await apiRequest(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/edits/${editId}/tracks`, token);
  const tracks = tracksRes.tracks || [];

  console.log(`\n📊 Release Tracks:`);
  for (const t of tracks) {
    console.log(`\n  🔹 Track: [${t.track.toUpperCase()}]`);
    if (!t.releases || t.releases.length === 0) {
      console.log(`     - No active releases.`);
    } else {
      for (const r of t.releases) {
        console.log(`     • Version: ${r.name || 'N/A'} (Codes: ${(r.versionCodes || []).join(', ')})`);
        console.log(`       - Status: ${(r.status || 'N/A').toUpperCase()}`);
        if (r.status === 'inProgress' && r.userFraction) {
          console.log(`       - Rollout: ${(r.userFraction * 100).toFixed(1)}%`);
        }
      }
    }
  }

  // 3. Clean up
  await apiRequest(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/edits/${editId}`, token, 'DELETE');
}

main().catch(err => {
  console.error('\n❌ Google Play API Error:', err.data?.error?.message || err);
  process.exit(1);
});
