# Entregable — AWS Lambda Image Processor Pipeline

**Alumno:** Anderson  
**Curso:** [Tu curso]  
**Fecha:** Mayo 2026  

---

## 1. Descripción del Proyecto

Pipeline serverless de procesamiento de imágenes en AWS que:
- Recibe imágenes via API Gateway (POST /upload)
- Almacena originales en S3 (uploads/)
- Procesa automáticamente via SQS + Lambda
- Genera versiones circulares 40x40px PNG (processed/)

**Tecnologías:** Terraform, AWS Lambda (Node.js 20.x), Docker, API Gateway, S3, SQS, VPC, CloudWatch

**Repositorio GitHub:** [PEGAR URL DEL REPOSITORIO AQUÍ]

---

## 2. Entornos Desplegados

| Entorno | Región | Naming Convention |
|---------|--------|-------------------|
| DEV | us-east-1 | image-processor-dev-* |
| QA | us-east-1 | image-processor-qa-* |
| PROD | us-east-1 | image-processor-prod-* |

---

## 3. Evidencia de Despliegue — Capturas Requeridas

### 3.1 Datos de la Cuenta AWS
> Captura de la esquina superior derecha de la consola AWS mostrando:
> - Account ID
> - Nombre de usuario (IAM Identity Center)
> - Región

**[PEGAR CAPTURA AQUÍ]**

---

### 3.2 API Gateway
> Services → API Gateway → APIs
> Mostrar los 3 APIs creados (dev, qa, prod) con sus endpoints

**[PEGAR CAPTURA AQUÍ — DEV]**
**[PEGAR CAPTURA AQUÍ — QA]**
**[PEGAR CAPTURA AQUÍ — PROD]**

---

### 3.3 Lambda Functions
> Services → Lambda → Functions
> Mostrar las 6 funciones (2 por entorno: upload + crop)

**[PEGAR CAPTURA AQUÍ]**

---

### 3.4 ECR Repositories
> Services → ECR → Repositories
> Mostrar los repositorios con las imágenes Docker

**[PEGAR CAPTURA AQUÍ]**

---

### 3.5 S3 Bucket
> Services → S3 → Buckets
> Mostrar los 3 buckets (uno por entorno) con los prefijos uploads/ y processed/

**[PEGAR CAPTURA AQUÍ]**

---

### 3.6 SQS Queues
> Services → SQS → Queues
> Mostrar las 6 colas (main + DLQ por entorno)

**[PEGAR CAPTURA AQUÍ]**

---

### 3.7 VPC
> Services → VPC → Your VPCs
> Mostrar las 3 VPCs creadas con sus CIDRs

**[PEGAR CAPTURA AQUÍ]**

---

### 3.8 CloudWatch Log Groups
> Services → CloudWatch → Log Groups
> Mostrar los log groups creados

**[PEGAR CAPTURA AQUÍ]**

---

### 3.9 CloudWatch Alarms
> Services → CloudWatch → Alarms
> Mostrar las alarmas de DLQ

**[PEGAR CAPTURA AQUÍ]**

---

## 4. URL del Proyecto y Prueba Funcional

### 4.1 URLs de los APIs

| Entorno | URL |
|---------|-----|
| DEV | [PEGAR URL de terraform output upload_url] |
| QA | [PEGAR URL] |
| PROD | [PEGAR URL] |

### 4.2 Prueba de Upload
> Captura del terminal mostrando el curl exitoso:
> ```
> curl -X POST <API_URL>/upload -F "image=@imagen.jpg"
> ```

**[PEGAR CAPTURA AQUÍ]**

### 4.3 Verificación en S3
> Captura mostrando la imagen original en uploads/ y la procesada en processed/

**[PEGAR CAPTURA AQUÍ]**

---

## 5. Terraform Outputs
> Captura del terminal mostrando `terraform output` para cada entorno

**[PEGAR CAPTURA DEV]**
**[PEGAR CAPTURA QA]**
**[PEGAR CAPTURA PROD]**

---

## 6. Evidencia de Destrucción de Recursos (terraform destroy)

### 6.1 Destroy DEV
> Captura del terminal mostrando:
> `terraform destroy -var-file="environments\dev.tfvars"`
> Con el mensaje final: "Destroy complete! Resources: X destroyed."

**[PEGAR CAPTURA AQUÍ]**

### 6.2 Destroy QA

**[PEGAR CAPTURA AQUÍ]**

### 6.3 Destroy PROD

**[PEGAR CAPTURA AQUÍ]**

### 6.4 Verificación Post-Destroy
> Captura de la consola AWS mostrando que ya no existen los recursos

**[PEGAR CAPTURA AQUÍ]**

---

## 7. README.md

El archivo README.md del repositorio incluye:
- Descripción de la arquitectura
- Prerequisitos (AWS CLI, Terraform, Docker)
- Instrucciones de despliegue para los 3 entornos
- Instrucciones de prueba (curl)
- Instrucciones de destrucción
- Estructura del proyecto

**Ver:** [URL_REPOSITORIO]/blob/main/README.md

---

## 8. Diagrama de Arquitectura

El diagrama se encuentra en el archivo `architecture.mermaid` del repositorio.

**[PEGAR IMAGEN RENDERIZADA DEL DIAGRAMA MERMAID AQUÍ]**
