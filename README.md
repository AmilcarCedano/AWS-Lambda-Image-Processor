# 🖼️ AWS Image Processor Pipeline

Pipeline serverless de procesamiento de imágenes desplegado en AWS usando Terraform con **ZIP-based deployment** (empaquetado local con Sharp optimizado).

## 📋 Descripción

Este proyecto implementa una arquitectura serverless en AWS que:

1. **Recibe imágenes** a través de un API Gateway HTTP endpoint (`POST /upload`)
2. **Almacena** las imágenes originales en S3 (`uploads/`)
3. **Procesa automáticamente** las imágenes mediante una cola SQS y una Lambda
4. **Genera** versiones circulares de 40x40px en formato PNG con fondo transparente (`processed/`)

### ⚡ ¿Por qué ZIP con Sharp nativo?

Para optimizar el costo y la velocidad de despliegue, hemos migrado de Docker a ZIP. Sin embargo, **Sharp** requiere binarios nativos de Linux. El proyecto ahora automatiza esto:
- Usa `null_resource` en Terraform para inyectar binarios de `linux-x64` durante el empaquetado.
- Evita el uso de Amazon ECR, reduciendo costos de almacenamiento y transferencia.
- Despliegue más rápido directamente desde el código fuente.

## 🏗️ Arquitectura

```
Cliente → API Gateway → Upload Lambda (ZIP) → S3 (uploads/)
                                               ↓
                                         S3 Event → SQS → Crop Lambda (ZIP) → S3 (processed/)
                                                     ↓ (fallos)
                                                 DLQ → CloudWatch Alarm
```

### Componentes

| Servicio | Recurso | Descripción |
|----------|---------|-------------|
| **API Gateway** | HTTP API v2 | Endpoint HTTPS con CORS y TLS 1.2+ |
| **S3** | Bucket único | Almacenamiento de originales y procesados |
| **Lambda (Upload)** | Node.js 20.x, ZIP | Gestión de subida de archivos |
| **Lambda (Crop)** | Node.js 20.x, ZIP | Procesamiento con Sharp (Linux x64) |
| **SQS** | Standard Queue + DLQ | Desacoplamiento del procesamiento |
| **VPC** | CIDR por entorno | Aislamiento de red con VPC Endpoints |
| **CloudWatch** | Logs + Alarm | Monitoreo y alertas de fallos en cola |

## 🌍 Multi-Entorno

Cada entorno se despliega en su propia VPC y configuración:

| Entorno | Región | VPC CIDR |
|---------|--------|----------|
| **DEV** | `us-east-1` | `10.0.0.0/16` |
| **QA** | `us-east-1` | `10.1.0.0/16` |
| **PROD** | `us-east-1` | `10.2.0.0/16` |

## 🔧 Prerequisitos

1. **AWS CLI** configurado (`aws configure`)
2. **Terraform** >= 1.5.0
3. **Node.js** >= 20.x (local para empaquetado)

## 🚀 Despliegue

```powershell
# 1. Inicializar
terraform init
COPY package.json ${LAMBDA_TASK_ROOT}/
RUN npm ci --production
COPY index.mjs ${LAMBDA_TASK_ROOT}/
CMD ["index.handler"]
```

> La crop Lambda necesita `gcc-c++` y `make` para compilar las dependencias nativas de `sharp`.

## 📄 Licencia

Proyecto académico — Uso educativo.
