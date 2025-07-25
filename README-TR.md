# OpenShift Tabanlı Mikroservis CI/CD ve Gözlemlenebilirlik Platformu

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-v3.9+-blue.svg)](https://www.python.org/)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red.svg)](https://www.openshift.com/)
[![Tekton](https://img.shields.io/badge/Tekton-CI%2FCD-blue.svg)](https://tekton.dev/)

Bu proje, OpenShift üzerinde çalışan bir mikroservis uygulaması için kapsamlı bir DevOps platformu sunar. Proje, CI/CD pipeline'ları, container orchestration, monitoring, logging ve güvenlik özelliklerini içerir.

## 📋 İçindekiler

- [Proje Özeti](#proje-özeti)
- [Mimari](#mimari)
- [Özellikler](#özellikler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Proje Yapısı](#proje-yapısı)
- [API Dokümantasyonu](#api-dokümantasyonu)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring ve Logging](#monitoring-ve-logging)
- [Güvenlik](#güvenlik)
- [Test](#test)
- [Katkıda Bulunma](#katkıda-bulunma)
- [Lisans](#lisans)

## 🎯 Proje Özeti

Bu proje, aşağıdaki temel bileşenleri içeren tam özellikli bir DevOps platformudur:

- **Weather Data Aggregator Microservice**: Birden fazla kaynaktan hava durumu verilerini toplayan FastAPI tabanlı RESTful API
- **CI/CD Pipeline**: Tekton tabanlı otomatik build, test ve deployment süreçleri
- **Container Orchestration**: OpenShift/Kubernetes üzerinde yüksek erişilebilirlik ve ölçeklenebilirlik
- **Observability Stack**: Prometheus, Grafana, Loki ve Jaeger ile tam gözlemlenebilirlik
- **Security**: RBAC, Network Policies, Security Scanning ve Container Security

## 🏗️ Mimari

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer / Route                     │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     OpenShift Cluster                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Microservice Pod                     │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │ Weather API │  │ Prometheus   │  │   Jaeger   │ │   │
│  │  │  (FastAPI)  │  │   Metrics    │  │  Tracing   │ │   │
│  │  └─────────────┘  └──────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐   │
│  │  Prometheus  │  │   Grafana    │  │   Loki/EFK     │   │
│  │   Server     │  │  Dashboards  │  │  Log Storage   │   │
│  └──────────────┘  └──────────────┘  └────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Tekton CI/CD Pipeline                    │  │
│  │  Build → Test → Security Scan → Deploy → E2E Test    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## ✨ Özellikler

### 🚀 Mikroservis Uygulaması
- FastAPI tabanlı RESTful API
- Çoklu hava durumu API entegrasyonu (OpenWeatherMap, WeatherAPI, vb.)
- Asenkron veri işleme
- Prometheus metrikleri
- OpenTelemetry distributed tracing
- Health check ve readiness probe'ları

### 🔄 CI/CD Pipeline
- **Tekton** tabanlı cloud-native CI/CD
- Otomatik build ve deployment
- Multi-stage Docker build
- Güvenlik taramaları (Trivy, Bandit)
- Otomatik test execution
- GitOps entegrasyonu

### 📊 Monitoring & Observability
- **Prometheus**: Metrik toplama ve alerting
- **Grafana**: Görselleştirme ve dashboard'lar
- **Loki/EFK Stack**: Log aggregation ve analiz
- **Jaeger**: Distributed tracing
- **AlertManager**: Alert yönetimi

### 🔒 Güvenlik
- Container güvenlik taramaları
- RBAC (Role-Based Access Control)
- Network Policies
- Secret yönetimi
- Non-root container execution
- Security scanning in CI/CD

### 🧪 Test Otomasyonu
- Unit testler (pytest)
- Integration testler
- E2E testler
- Performance testler
- Security testler

## 🚀 Kurulum

### Gereksinimler

- OpenShift 4.x cluster veya OpenShift Local (CRC)
- `oc` CLI tool
- Docker veya Podman
- Python 3.9+
- Git

### Hızlı Başlangıç

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/yourusername/stajdevopsproje.git
cd stajdevopsproje
```

2. **OpenShift'e login olun:**
```bash
oc login -u developer -p developer https://api.crc.testing:6443
```

3. **Namespace oluşturun:**
```bash
oc new-project microservice-demo
```

4. **Platform'u deploy edin:**
```bash
./deploy-all-environments.sh
```

### Detaylı Kurulum

Detaylı kurulum adımları için [DEPLOYMENT_EXPLANATION.md](DEPLOYMENT_EXPLANATION.md) dosyasına bakın.

## 📖 Kullanım

### API Endpoints

Weather Data Aggregator API'si aşağıdaki endpoint'leri sunar:

- `GET /` - API bilgileri ve endpoint listesi
- `GET /healthz` - Liveness probe
- `GET /ready` - Readiness probe
- `GET /metrics` - Prometheus metrikleri
- `GET /api/v1/weather/current?lat={lat}&lon={lon}` - Belirli konum için güncel hava durumu
- `GET /api/v1/weather/aggregated?lat={lat}&lon={lon}` - Tüm kaynaklardan toplu veri
- `GET /api/v1/weather/trends?lat={lat}&lon={lon}&hours={hours}` - Hava durumu trendleri
- `GET /api/v1/weather/locations` - Aktif olarak izlenen lokasyonlar
- `GET /api/v1/status/apis` - API durumları
- `GET /api/v1/status/quality` - Veri kalite metrikleri
- `POST /api/v1/weather/refresh` - Manuel veri yenileme

### Örnek Kullanım

```bash
# Güncel hava durumu verisi al
curl "http://microservice-demo.apps.openshift.local/api/v1/weather/current?lat=41.0082&lon=28.9784"

# Prometheus metrikleri görüntüle
curl "http://microservice-demo.apps.openshift.local/metrics"

# Health check
curl "http://microservice-demo.apps.openshift.local/healthz"
```

## 📁 Proje Yapısı

```
stajdevopsproje/
├── app/                      # Mikroservis uygulama kodu
│   ├── main.py              # FastAPI ana uygulama
│   ├── weather_service.py   # Hava durumu servisi
│   ├── models.py            # Pydantic modelleri
│   ├── config.py            # Konfigürasyon
│   └── tests/               # Test dosyaları
├── cicd/                    # CI/CD pipeline tanımları
│   ├── pipelines/          # Tekton pipeline YAML'ları
│   ├── tasks/              # Tekton task tanımları
│   └── scripts/            # Yardımcı scriptler
├── openshift/              # OpenShift manifest dosyaları
│   ├── base/               # Temel Kubernetes/OpenShift kaynakları
│   └── overlays/           # Ortam-spesifik konfigürasyonlar
├── observability/          # Monitoring ve logging konfigürasyonları
│   ├── prometheus/         # Prometheus konfigürasyonu
│   ├── grafana/           # Grafana dashboard'ları
│   └── loki/              # Loki log aggregation
├── governance/            # RBAC ve güvenlik politikaları
├── testing/               # Test senaryoları ve scriptler
└── docs/                  # Dokümantasyon
```

## 🔄 CI/CD Pipeline

Tekton tabanlı CI/CD pipeline aşağıdaki aşamaları içerir:

1. **Git Clone**: Kaynak kodun çekilmesi
2. **Unit Test**: Birim testlerin çalıştırılması
3. **Build Image**: Container image oluşturulması
4. **Security Scan**: Güvenlik taramalarının yapılması
5. **Deploy Dev**: Development ortamına deployment
6. **E2E Test**: Uçtan uca testlerin çalıştırılması
7. **Deploy Prod**: Production ortamına deployment (manuel onay ile)

Pipeline'ı tetiklemek için:

```bash
./run-cicd-pipeline.sh
```

## 📊 Monitoring ve Logging

### Prometheus & Grafana

Grafana dashboard'larına erişim:
```bash
oc get route grafana -n observability
```

### Log Görüntüleme

```bash
# Pod loglarını görüntüle
oc logs -f deployment/microservice-demo

# Loki üzerinden log sorgulama
./cicd/scripts/collect-weather-logs.sh
```

## 🔒 Güvenlik

Proje aşağıdaki güvenlik özelliklerini içerir:

- **Container Security**: Non-root user, read-only root filesystem
- **Network Policies**: Pod-to-pod iletişim kontrolü
- **RBAC**: Role-based access control
- **Security Scanning**: Build aşamasında güvenlik taramaları
- **Secret Management**: OpenShift secrets ile hassas veri yönetimi

## 🧪 Test

### Unit Testleri Çalıştırma

```bash
cd app
python -m pytest tests/ -v
```

### Integration Testleri

```bash
./testing/scripts/run-all-tests.sh
```

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını okuyun.

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📚 Ek Kaynaklar

- [OpenShift Console Guide](OPENSHIFT_CONSOLE_GUIDE.md)
- [Architecture Guide](ARCHITECTURE_GUIDE.md)
- [Hands-on Tutorial](HANDS_ON_TUTORIAL.md)
- [API Documentation](docs/api/README.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 👥 İletişim

Sorularınız veya önerileriniz için:
- GitHub Issues: [Project Issues](https://github.com/yourusername/stajdevopsproje/issues)
- Email: your.email@example.com

---

**Not**: Bu proje eğitim amaçlı geliştirilmiştir ve production ortamında kullanım için ek güvenlik ve performans optimizasyonları gerekebilir.