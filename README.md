# 🖼️ AWS Image Processor Pipeline

Pipeline serverless de procesamiento de imágenes desplegado en AWS usando Terraform con **Docker** y soporte **multi-región**.

## 📋 Descripción

Este proyecto implementa una arquitectura serverless en AWS que:

1. **Recibe imágenes** a través de un API Gateway HTTP endpoint (`POST /upload`)
2. **Almacena** las imágenes originales en S3 (`uploads/`)
3. **Procesa automáticamente** las imágenes mediante una cola SQS y una Lambda
4. **Genera** versiones circulares de 40x40px en formato PNG con fondo transparente (`processed/`)

### 🐳 ¿Por qué Docker?

Las funciones Lambda se empaquetan como **imágenes Docker** (no como zips) porque:
- **Sharp** (librería de procesamiento de imágenes) requiere binarios nativos que deben compilarse para Linux/amd64
- Los Dockerfiles garantizan builds reproducibles en cualquier OS (Windows, macOS, Linux)
- Las imágenes se almacenan en **Amazon ECR** (Elastic Container Registry)

## 🏗️ Arquitectura

```
Cliente → API Gateway → Upload Lambda (Docker) → S3 (uploads/)
                                                    ↓
                                              S3 Event → SQS → Crop Lambda (Docker) → S3 (processed/)
                                                          ↓ (fallos)
                                                      DLQ → CloudWatch Alarm → SNS
```

### Componentes

| Servicio | Recurso | Descripción |
|----------|---------|-------------|
| **API Gateway** | HTTP API v2 | Endpoint HTTPS con CORS, TLS 1.2+, throttling |
| **ECR** | 2 Repositorios | Container registry para cada Lambda |
| **Lambda (Upload)** | Node.js 20.x, Docker, 256MB, 30s | Parsea multipart/form-data o JSON+base64 |
| **Lambda (Crop)** | Node.js 20.x, Docker, 512MB, 60s | Recorta imagen a 40x40 circular PNG con sharp |
| **S3** | Bucket único | Prefijos `uploads/` y `processed/`, SSE AES-256, versionado |
| **SQS** | Standard Queue + DLQ | Visibility timeout 360s, long polling 20s, 3 reintentos |
| **VPC** | CIDR por entorno | 2 AZs, subnets públicas/privadas, NAT Gateways, VPC Endpoints |
| **CloudWatch** | Logs + Alarm | Retención configurable, alarma en DLQ, SNS |
| **IAM** | Least-privilege roles | Permisos mínimos por función Lambda |

## 🌍 Multi-Entorno / Multi-Región

Cada entorno se despliega en una **región AWS diferente** con su propia VPC:

| Entorno | Región | VPC CIDR | Descripción |
|---------|--------|----------|-------------|
| **DEV** | `us-east-1` (N. Virginia) | `10.0.0.0/16` | Desarrollo, retención corta |
| **QA** | `us-west-2` (Oregon) | `10.1.0.0/16` | Testing, retención media |
| **PROD** | `eu-west-1` (Irlanda) | `10.2.0.0/16` | Producción, retención completa |

> Las regiones se configuran en los archivos `terraform/environments/*.tfvars` y se pueden cambiar libremente.

## 📁 Estructura del Proyecto

```
.
├── architecture.mermaid           # Diagrama de arquitectura
├── README.md                      # Este archivo
├── .gitignore
├── terraform/
│   ├── main.tf                    # Provider y configuración
│   ├── variables.tf               # Variables con validaciones
│   ├── outputs.tf                 # Outputs del despliegue
│   ├── vpc.tf                     # VPC, Subnets, IGW, NAT, Routes
│   ├── security_groups.tf         # Security Groups
│   ├── vpc_endpoints.tf           # S3 Gateway + SQS Interface
│   ├── s3.tf                      # Bucket, lifecycle, encryption
│   ├── sqs.tf                     # Queue + DLQ + policies
│   ├── iam.tf                     # Roles y policies
│   ├── ecr.tf                     # ECR Repos + Docker Build/Push
│   ├── lambda.tf                  # Functions (Docker) + Event Source
│   ├── api_gateway.tf             # HTTP API + Stage + Routes
│   ├── cloudwatch.tf              # Log Groups + Alarms + SNS
│   └── environments/
│       ├── dev.tfvars             # DEV — us-east-1
│       ├── qa.tfvars              # QA  — us-west-2
│       └── prod.tfvars            # PROD — eu-west-1
├── lambdas/
│   ├── upload/
│   │   ├── Dockerfile             # Docker image para upload Lambda
│   │   ├── index.mjs              # Handler de upload
│   │   └── package.json
│   └── crop/
│       ├── Dockerfile             # Docker image para crop Lambda
│       ├── index.mjs              # Handler de crop (sharp)
│       └── package.json
└── scripts/
    ├── deploy.sh                  # Script de despliegue
    ├── destroy.sh                 # Script de destrucción
    └── test-upload.sh             # Script de prueba
```

## 🔧 Prerequisitos

1. **AWS CLI** configurado:
   ```bash
   aws configure
   # AWS Access Key ID: <tu-key>
   # AWS Secret Access Key: <tu-secret>
   # Default region name: us-east-1
   ```

2. **Terraform** >= 1.5.0:
   ```bash
   terraform --version
   ```

3. **Docker Desktop** (necesario para construir las imágenes Lambda):
   ```bash
   docker --version
   ```

4. **Node.js** >= 20.x (opcional, solo para desarrollo local):
   ```bash
   node --version
   ```

## 🚀 Despliegue

### Paso 1: Inicializar Terraform

```powershell
cd "c:\Users\ANDERSON\IdeaProjects\AWS + Lambda Integration\terraform"
terraform init
```

### Paso 2: Desplegar un entorno

```powershell
# ── DEV (us-east-1) ──
terraform workspace new dev
terraform plan -var-file="environments\dev.tfvars"
terraform apply -var-file="environments\dev.tfvars"

# ── QA (us-west-2) ──
terraform workspace new qa
terraform plan -var-file="environments\qa.tfvars"
terraform apply -var-file="environments\qa.tfvars"

# ── PROD (eu-west-1) ──
terraform workspace new prod
terraform plan -var-file="environments\prod.tfvars"
terraform apply -var-file="environments\prod.tfvars"
```

> ⚡ Terraform automáticamente construye las imágenes Docker y las sube a ECR.

### Paso 3: Ver outputs

```powershell
terraform output
```

### Cambiar entre entornos

```powershell
terraform workspace select dev
terraform workspace select qa
terraform workspace select prod
```

## 🧪 Pruebas

### Subir imagen con curl (multipart)

```bash
API_URL=$(terraform output -raw upload_url)
curl -X POST "$API_URL" -F "image=@/path/to/image.jpg"
```

### Subir imagen con PowerShell

```powershell
$API_URL = terraform output -raw upload_url
curl.exe -X POST $API_URL -F "image=@C:\path\to\image.jpg"
```

### Subir imagen JSON + base64

```bash
BASE64=$(base64 -i /path/to/image.png)
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"image\":\"$BASE64\",\"filename\":\"test.png\",\"contentType\":\"image/png\"}"
```

### Verificar resultados

```bash
# Listar uploads
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/uploads/

# Listar processed
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/processed/

# Ver logs
aws logs tail /aws/lambda/$(terraform output -raw upload_lambda_name) --follow
```

## 🗑️ Destruir Recursos

```powershell
# Destruir DEV
terraform workspace select dev
terraform destroy -var-file="environments\dev.tfvars"

# Destruir QA
terraform workspace select qa
terraform destroy -var-file="environments\qa.tfvars"

# Destruir PROD
terraform workspace select prod
terraform destroy -var-file="environments\prod.tfvars"
```

> ⚠️ **IMPORTANTE**: Toma capturas del output de `terraform destroy` para tu PDF.

## 📸 Capturas Necesarias para el PDF

| # | Captura | Dónde |
|---|---------|-------|
| 1 | **Account ID** | Esquina superior derecha de AWS Console |
| 2 | **API Gateway** | Services → API Gateway → tu API |
| 3 | **Lambda Functions** | Services → Lambda → Functions |
| 4 | **ECR Repositories** | Services → ECR → Repositories |
| 5 | **S3 Bucket** | Services → S3 → tu bucket |
| 6 | **SQS Queues** | Services → SQS → Queues |
| 7 | **VPC** | Services → VPC → Your VPCs |
| 8 | **CloudWatch Logs** | Services → CloudWatch → Log Groups |
| 9 | **CloudWatch Alarm** | Services → CloudWatch → Alarms |
| 10 | **Prueba funcional** | Output de curl con upload exitoso |
| 11 | **terraform destroy** | Terminal mostrando "Destroy complete!" |

## 🐳 Dockerfiles

### Upload Lambda (`lambdas/upload/Dockerfile`)
```dockerfile
FROM public.ecr.aws/lambda/nodejs:20
COPY package.json ${LAMBDA_TASK_ROOT}/
RUN npm ci --production
COPY index.mjs ${LAMBDA_TASK_ROOT}/
CMD ["index.handler"]
```

### Crop Lambda (`lambdas/crop/Dockerfile`)
```dockerfile
FROM public.ecr.aws/lambda/nodejs:20
RUN dnf install -y gcc-c++ make && dnf clean all
COPY package.json ${LAMBDA_TASK_ROOT}/
RUN npm ci --production
COPY index.mjs ${LAMBDA_TASK_ROOT}/
CMD ["index.handler"]
```

> La crop Lambda necesita `gcc-c++` y `make` para compilar las dependencias nativas de `sharp`.

## 📄 Licencia

Proyecto académico — Uso educativo.
