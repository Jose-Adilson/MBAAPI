# MBAAPI - Benchmarking Performance Comparison

API .NET 10 otimizada para testes rigorosos de desempenho e comparação de Custo Total de Propriedade (TCO) entre arquiteturas Serverless e Contêineres de execução contínua.

Desenvolvido como artefato prático para Trabalho de Conclusão de Curso (Especialização em Engenharia de Software) focado na análise do impacto da compilação Native AOT e JIT na nuvem da AWS.

## 📋 Características

- ✅ Arquitetura Minimal API para supressão máxima de overhead de framework.
- ✅ Otimizado estritamente para benchmarks de CPU, Memória e I/O de Rede.
- ✅ Refatoração de serialização JSON utilizando *Source Generators* para compatibilidade AOT.
- ✅ Scripts de infraestrutura e telemetria para AWS Lambda e ECS Fargate.

## 📁 Estrutura do Projeto

```
MBAAPI/
├── Program.cs                       # Minimal API com endpoints de benchmark
├── MBAAPI.csproj                    # Projeto com suporte AOT/JIT/Fargate
├── Dockerfile.benchmark             # Dockerfile para JIT/Fargate
├── Dockerfile.lambda-aot			 # Dockerfile para Lambda AOT
├── build-benchmark.ps1              # Script build Windows
├── build-benchmark.sh               # Script build Linux/macOS
├── aot-config.json                  # Configuração AOT
├── benchmark.k6.js                   # Script de teste de compute, memory e payload k6
├── cold-start.k6.ps1                # Script powershell de teste de cold start k6
└── README.md                        # Este arquivo
```

## 🎯 Endpoints Disponíveis

### Health & Diagnostic
- `GET /health` - Status de saúde com timestamp.
- `GET /ping` - Resposta mínima "pong" (menor overhead possível).

### Benchmark Endpoints (em `/api/benchmark`)
#### Infraestrutura Mínima
- `GET /api/benchmark/minimal` - Payload mínimo (~50 bytes). Isola a latência bruta do *runtime* e da rede.

#### Processamento e Estresse
- `GET /api/benchmark/compute` - Teste CPU (Cálculos matemáticos iterativos pesados).
- `GET /api/benchmark/memory` - Teste Memória (Alocação dinâmica em *bytes* para estresse do *Garbage Collector*).

#### I/O e Serialização
- `POST /api/benchmark/echo` - Retorna o payload enviado para testar a eficiência dos *Source Generators* no *parsing* JSON.

## ☁️ AWS Deployment e Reprodução

### 1. ECS Fargate (Docker)
Utilizado como linha de base de execução contínua (JIT).

```bash
# 1. Autentique o Docker no Amazon ECR
aws ecr get-login-password --region [REGIAO] | docker login --username AWS --password-stdin [ACCOUNT-ID].dkr.ecr.[REGIAO].amazonaws.com

# 2. Realize o build da imagem sem usar o cache local
docker build --no-cache -f Dockerfile.benchmark -t mbaapi:v2 .

# 3. Marque a imagem para o seu repositório ECR
docker tag mbaapi:v2 [ACCOUNT-ID].dkr.ecr.[REGIAO][.amazonaws.com/](https://.amazonaws.com/)[NOME-REPOSITORIO]:v2

# 4. Envie a imagem para a AWS
docker push [ACCOUNT-ID].dkr.ecr.[REGIAO][.amazonaws.com/](https://.amazonaws.com/)[NOME-REPOSITORIO]:v2
No console da AWS (ECS > Task Definitions), crie uma nova revisão da Task referenciando a tag :v2. Em seguida, atualize o serviço ECS marcando "Force New Deployment".
```
2. Lambda Native AOT
Requer publicação voltada para o Custom Runtime da AWS (Amazon Linux 2023 / linux-x64).
```bash
# 1. Publique como Self-Contained para Linux x64
dotnet publish "MBAAPI.csproj" -c ReleaseAOT -r linux-x64 --self-contained true -o ./publish-aot

# 2. Renomeie o executável gerado para "bootstrap"
mv ./publish-aot/MBAAPI ./publish-aot/bootstrap

# 3. Compacte o pacote
cd publish-aot
zip -j ../function-aot.zip bootstrap

# 4. Atualize o código da função Lambda
aws lambda update-function-code --function-name [NOME-FUNCAO-AOT] --zip-file fileb://../function-aot.zip
```
3. Lambda JIT Tradicional
```bash
# 1. Publique utilizando a configuração JIT padrão
dotnet publish "MBAAPI.csproj" -c Release -o ./publish-jit /p:PublishAot=false

# 2. Compacte o pacote
cd publish-jit
zip -r ../function-jit.zip .

# 3. Atualize o código da função Lambda
aws lambda update-function-code --function-name [NOME-FUNCAO-JIT] --zip-file fileb://../function-jit.zip
```
📊 Metodologia de Benchmarking (k6)
Atenção: Mitigação de AWS Throttling (Erro 429)
Cargas explosivas sem intervalo acionarão o limite de concorrência não reservada da AWS. Para mensurar a latência de regime estável de forma confiável, recomenda-se estabilizar o script em 15 a 20 VUs com 100ms de intervalo por requisição.

Exemplo do script de carga:

```JavaScript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 15 },
    { duration: '2m', target: 15 },
    { duration: '10s', target: 0 },
  ],
};

export default function () {
  const BASE_URL = 'https://[SUA-URL-DO-API-GATEWAY-OU-ALB]';
  let res = http.get(`${BASE_URL}/api/benchmark/memory`);
  check(res, { 'status was 200': (r) => r.status == 200 });
  sleep(0.1); 
}
```
Execução:

```bash
k6 run benchmark.k6.js
```
⚙️ Requisitos
.NET 10.0+

Docker

AWS CLI

k6 (para os testes de benchmark)

📝 Notas Importantes
Source Generators: A compilação AOT exige que reflexões dinâmicas sejam evitadas.

Cold Start: As métricas de inicialização a frio devem considerar o overhead do AWS API Gateway.

Telemetria: Utilize o AWS CloudWatch Logs Insights (filtrando por @type="REPORT") para extrair os dados oficiais de Billed Duration e Max Memory Used.

Desenvolvido para TCC - Eficiência em nuvem: análise comparativa entre Serverless e Containers para Web
