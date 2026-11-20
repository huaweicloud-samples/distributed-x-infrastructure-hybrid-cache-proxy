# 部署指南：对象存储混合缓存代理

## 概述

本文档说明如何在华为云上部署 对象存储混合缓存代理应用。

---

## 前置条件

1. 华为云账号（已开通以下服务）：
   - CCE (容器服务)
   - OBS (对象存储)
   - SFS (文件存储)
   - VPC (虚拟私有云)
   - EIP (弹性公网 IP)
   - IAM (身份认证)

2. Docker 和 kubectl 客户端

3. Rust 编译环境（可选）

---

## 部署步骤

### 步骤 1: 创建基础设施

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 步骤 2: 编译 Rust 代码

```bash
# 克隆或下载源码
cargo build --release
```

### 步骤 3: 构建 Docker 镜像

```dockerfile
# Dockerfile
FROM rust:1.75 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y lz4 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/hybrid-cache /usr/local/bin/
EXPOSE 80 3129 8080 8081 9090
ENTRYPOINT ["/usr/local/bin/hybrid-cache"]
```

```bash
# 构建镜像
docker build -t hybrid-cache:latest .

# 推送到 SWR
docker tag hybrid-cache:latest registry.cn-north-4.myhuaweicloud.com/your-namespace/hybrid-cache:latest
docker push registry.cn-north-4.myhuaweicloud.com/your-namespace/hybrid-cache:latest
```

### 步骤 4: 部署到 CCE

创建部署配置文件：

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hybrid-cache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hybrid-cache
  template:
    metadata:
      labels:
        app: hybrid-cache
    spec:
      containers:
      - name: hybrid-cache
        image: registry.cn-north-4.myhuaweicloud.com/your-namespace/hybrid-cache:latest
        ports:
        - containerPort: 80
        - containerPort: 3129
        - containerPort: 8080
        volumeMounts:
        - name: cache-storage
          mountPath: /cache
        env:
        - name: AWS_ENDPOINT_URL_S3
          value: "https://your-bucket.obs.cn-north-4.myhuaweicloud.com"
      volumes:
      - name: cache-storage
        persistentVolumeClaim:
          claimName: cache-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: hybrid-cache
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: hybrid-cache
```

```bash
# 部署
kubectl apply -f deployment.yaml
```

### 步骤 5: 配置存储

创建 PVC：

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cache-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: sfs
```

```bash
kubectl apply -f pvc.yaml
```

---

## 验证

1. 检查 Pod 状态：

```bash
kubectl get pods -l app=hybrid-cache
```

2. 检查服务：

```bash
kubectl get svc hybrid-cache
```

3. 访问监控面板：

```bash
# 获取 ELB 地址
kubectl get svc hybrid-cache -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 配置说明

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| AWS_ENDPOINT_URL_S3 | OBS 端点 | - |
| AWS_REGION | 区域 | cn-north-4 |
| CACHE_DIR | 缓存目录 | /cache |
| MAX_CACHE_SIZE | 最大缓存大小 | 524288000 |

### 配置文件

```yaml
# config.yaml
server:
  mode: "proxy_only"
  proxy_port: 3128
cache:
  cache_dir: "/cache"
  max_cache_size: 524288000
logging:
  access_log_dir: "/logs/access"
  app_log_dir: "/logs/app"
```

---

## 清理资源

```bash
# 删除部署
kubectl delete -f deployment.yaml

# 删除 Terraform 资源
cd infra
terraform destroy
```

---

## 费用说明

| 资源 | 配置 | 结算方式 |
|------|------|----------|
| CCE 节点 | 3 x s6.large.2xlarge | 按小时 |
| OBS | 标准存储 | 按存储量结算 |
| SFS | 100GB | 包月 |
| EIP | 10Mbps | 包月 |
