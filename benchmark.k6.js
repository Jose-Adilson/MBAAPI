import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'https://t3k2lm7eam6baloghit5rtn75i0uejob.lambda-url.us-east-2.on.aws/'; // JIT
//const BASE_URL = 'https://577xcjudhfbomovavixzxv4cgu0rcdyb.lambda-url.us-east-2.on.aws/'; // AOT
//const BASE_URL = 'http://mba-load-balancer-171803100.us-east-2.elb.amazonaws.com'; // EC2

// Configuração de Cenários Isolados
export const options = {
    scenarios: {
        // Cenário 1: Estresse de CPU (Isola o poder de processamento bruto)
        compute_heavy: {
            executor: 'ramping-vus',
            exec: 'computeTest',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 15 },
                { duration: '1m', target: 15 },
                { duration: '30s', target: 0 },
            ],
        },
        // Cenário 2: Estresse de Memória e GC (Garbage Collection)
        memory_heavy: {
            executor: 'ramping-vus',
            exec: 'memoryTest',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 15 },
                { duration: '1m', target: 15 },
                { duration: '30s', target: 0 },
            ],
        },
        // Cenário 3: Estresse de I/O e Serialização JSON (Testa o Source Generator vs Reflection)
        payload_heavy: {
            executor: 'ramping-vus',
            exec: 'payloadTest',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 20 },
                { duration: '1m', target: 20 },
                { duration: '30s', target: 0 },
            ],
        },
    },
    thresholds: {
        // Definimos limites aceitáveis globais
        http_req_failed: ['rate<0.05'],
    },
};

// --- Funções de Execução Isoladas ---

export function computeTest() {
    const res = http.get(`${BASE_URL}/api/benchmark/compute`);
    check(res, { 'compute status 200': (r) => r.status === 200 });

    if (res.status !== 200) {
        console.log(`Erro! Status: ${res.status}`);
    }

    sleep(0.1);
}

export function memoryTest() {
    const res = http.get(`${BASE_URL}/api/benchmark/memory`);
    check(res, { 'memory status 200': (r) => r.status === 200 });

    if (res.status !== 200) {
        console.log(`Erro! Status: ${res.status}`);
    }

    sleep(0.1);
}

export function payloadTest() {
    const payload = JSON.stringify({
        message: 'Test message for benchmarking',
        value: 42,
    });
    const params = { headers: { 'Content-Type': 'application/json' } };

    // O teste de Echo força a API a desserializar e reserializar o objeto
    const res = http.post(`${BASE_URL}/api/benchmark/echo`, payload, params);
    check(res, { 'payload status 200': (r) => r.status === 200 });

    if (res.status !== 200) {
        console.log(`Erro! Status: ${res.status}`);
    }

    sleep(0.1);
}