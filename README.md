# Object Storage Hybrid Cache Proxy: Huawei Cloud Best Practice

[中文版](./README.cn.md)

![License](https://img.shields.io/badge/license-MIT--0-blue.svg)
![Huawei Cloud](https://img.shields.io/badge/华为云-最佳实践-ff4d00.svg)

> Huawei Cloud Best Practice (Architecture-equivalent adaptation)

---

## Overview

This project is a high-performance object-storage hybrid cache proxy implementation on Huawei Cloud, demonstrating how to leverage Huawei Cloud's object storage and container services to build low-latency, high-throughput data access acceleration solutions. The solution lands the same-shaped reference architecture while fully leveraging Huawei Cloud services such as OBS, SFS, and CCE.

### Core Features

1. **Intelligent Multi-tier Caching** - RAM cache + file storage cache + OBS backend for significantly reduced access latency
2. **Transparent Authentication Reuse** - No need to cache credentials, client request signatures are reused
3. **Shared File Storage** - Multi-cache nodes share cached data through SFS
4. **Stateless Proxy Design** - Horizontal scaling with high availability
5. **Content-Aware Compression** - LZ4 compression reduces storage footprint by 2-10x

### Use Cases

This project is suitable for: hybrid cloud applications requiring lower object storage latency, large-scale data access like medical imaging and genomic data, quantitative trading with low-latency data retrieval, and high-frequency data access in autonomous driving scenarios.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Huawei Cloud Architecture                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐      ┌────────────────────────────────────┐     │
│  │   Client     │─────▶│     Hybrid Cache Proxy             │     │
│  │ (Application)│      │         (CCE Pod)                  │     │
│  └──────────────┘      └──────────────┬───────────────────┘     │
│                                         │                          │
│                                         ▼                          │
│                               ┌──────────────────┐              │
│                               │   RAM  Cache     │              │
│                               └────────┬─────────┘              │
│                                        │                          │
│                                        ▼                          │
│                               ┌──────────────────┐              │
│                               │   SFS  Cache     │              │
│                               │ (File Storage)   │              │
│                               └────────┬─────────┘              │
│                                        │                          │
│                                        ▼                          │
│                               ┌──────────────────┐              │
│                               │   OBS           │              │
│                               │ (Object Storage)│              │
│                               └──────────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Option 1: Terraform Deployment

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### Option 2: Manual Deployment

1. Create CCE cluster
2. Build Docker image
3. Deploy to CCE
4. Configure SFS volume

---

## Services Used

| Service | Purpose |
|---------|---------|
| CCE | Container Platform |
| OBS | Object Storage |
| SFS | Scalable File Storage |
| VPC | Virtual Private Network |
| EIP | Elastic IP |
| IAM | Identity Management |

---

## License

MIT-0 License
