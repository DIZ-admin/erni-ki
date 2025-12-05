/* global __ENV */
import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.SMOKE_BASE_URL;
const authPath = __ENV.SMOKE_AUTH_PATH || '/auth/validate';
const ragPath = __ENV.SMOKE_RAG_PATH || '/health';
const token = __ENV.SMOKE_AUTH_TOKEN || 'invalid-token';

export const options = baseUrl
  ? {
      vus: Number(__ENV.SMOKE_VUS || 5),
      duration: __ENV.SMOKE_DURATION || '30s',
      thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<2000'],
      },
    }
  : {
      vus: 1,
      iterations: 1,
    };

export default function () {
  if (!baseUrl) {
    // Skip when base URL not provided
    sleep(1);
    return;
  }

  const authRes = http.get(`${baseUrl}${authPath}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  check(authRes, {
    'auth responds': r => r.status < 500,
  });

  const ragRes = http.get(`${baseUrl}${ragPath}`);
  check(ragRes, {
    'rag responds': r => r.status < 500,
  });

  sleep(1);
}
