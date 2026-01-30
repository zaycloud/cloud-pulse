# ☁️ Cloud-Pulse: A Resilient "Ops-in-a-Box" Platform

**Cloud-Pulse** är ett *Infrastructure as Code*-projekt som demonstrerar en självläkande och självövervakande molninfrastruktur. Målet med projektet var att bevisa **Resilience** genom att bygga ett system som inte bara överlever extrem belastning, utan också är "medvetet" om sin egen hälsa och kommunicerar detta visuellt till slutanvändaren.

---

## Projektets Mål
1.  **Ops-in-a-Box:** Fullständig automatisering från tom AWS-miljö till driftklar applikation med ett enda kommando.
2.  **Observability:** Implementera djup övervakning (Metrics) för att se infrastrukturens "puls" i realtid.
3.  **Chaos Engineering:** Simulera verkliga katastrofscenarion (CPU-spikar) och bevisa systemets stabilitet.
4.  **Self-Awareness:** Webbsidan ska reagera dynamiskt på serverns hälsa.

---

## 🏗️ Arkitektur & Tech Stack

![Cloud-Pulse Architecture](assets/cloud_pulse_architecture.png)

Systemet är byggt enligt **Day 2 Operations**-principer (fokus på drift och underhåll).

### 🛠️ Verktyg
| Verktyg | Syfte |
|---------|-------|
| **Terraform** | **Infrastructure as Code (IaC).** Skapar VPC, Säkerhetsgrupper och EC2-instanser i AWS (eu-north-1). |
| **Ansible** | **Configuration Management.** Installerar Docker, Nginx, Prometheus och distribuerar Python-logik. |
| **Docker** | **Containerization.** Kör hela övervakningsstacken isolerat. |
| **Prometheus** | **Metrics Database.** Samlar in data om CPU, RAM och Disk var 15:e sekund. |
| **Grafana** | **Visualisering.** Dashboard för att analysera metrics visuellt. |
| **Python** | **Automation Logic.** Ett custom script (`status_monitor.py`) som kopplar ihop systemets hälsa med UI:t. |
| **Stress-ng** | **Chaos Testing.** Verktyg för att simulera extrem belastning. |

---

## ⚙️ Så fungerar "The Magic Loop"

Det unika med Cloud-Pulse är hur komponenterna pratar med varandra under en incident:

1.  **Incident:** Vi injicerar kaos med `stress-ng` (100% CPU last).
2.  **Detektion:** En bakgrundstjänst (`status_monitor.service`) upptäcker att CPU-lasten överstiger **80%**.
3.  **Reaktion:** Tjänsten byter automatiskt ut Nginx-landningssidan från **GRÖN (Operational)** till **RÖD (CRITICAL ALERT)**.
4.  **Visualisering:** Grafana visar exakt vad som händer under huven (System Load, RAM usage).
5.  **Återhämtning:** När lasten sjunker, återställer systemet sig själv till grönt läge automatiskt.

---

## 📂 Projektstruktur

```bash
cloud-pulse/
├── terraform/              # Skapar Infrastrukturen
│   ├── modules/            # Modulär kod (Compute, Networking, Security)
│   └── main.tf             # Huvudfilen som binder ihop allt
│
├── ansible/                # Konfigurerar Servern
│   ├── roles/
│   │   ├── monitoring/     # Prometheus, Grafana, Node-Exporter (Docker)
│   │   └── web/            # Nginx + Self-Healing Python Script
│   ├── inventory.ini       # Pekar på vår EC2-instans
│   └── setup.yml           # Playbook som kör allt
│
└── README.md               # Du läser denna nu
```

---

## Hur man kör projektet

### Steg 1: Bygg Infrastruktur (Terraform)
```bash
cd terraform
terraform apply -auto-approve
```
*Detta skapar nätverk, brandväggar och servern i AWS.*

### Steg 2: Konfigurera Servern (Ansible)
```bash
cd ..
ansible-playbook -i ansible/inventory.ini ansible/setup.yml
```
*Detta installerar Docker, startar övervakning och deployar hemsidan.*

### Steg 3: The Chaos Demo
Gå till hemsidan (IP-adressen). Den ska vara **Grön**.
Kör sedan detta kommando för att stressa servern:

```bash
ssh -i ~/.ssh/cloud_pulse_key ubuntu@<DIN-IP> "stress-ng --cpu 0 --vm 2 --io 2 --timeout 60s"
```
Uppdatera hemsidan. Den är nu **Röd** .
Titta i Grafana (port 3000) för att se graferna skjuta i höjden!

---

## Lärdomar & Utmaningar

Under projektets gång stötte vi på och löste flera verkliga DevOps-problem:

### 1. Säkerhet & Nätverk (Dual Stack)
*   **Utmaning:** AWS i vissa regioner och ISPs kräver IPv6.
*   **Lösning:** Vi byggde våra Security Groups för att hantera **Dual Stack** (både `0.0.0.0/0` och `::/0`) för att garantera SSH-åtkomst.

### 2. Idempotence i Ansible
*   **Lärdom:** Vi lärde oss att skriva Ansible-tasks som kan köras 100 gånger utan att förstöra något.
*   **Exempel:** Använda `handlers` (notify) för att bara starta om Nginx/Docker när konfigurationsfiler *faktiskt ändras*.

### 3. Terraform State
*   **Lärdom:** Hur Terraform håller koll på vad som redan finns via `terraform.tfstate`.
*   **Övning:** Vi använde `terraform state show` och `grep` för att inspektera våra resurser manuellt och verifiera brandväggsregler.

### 4. Från "Static" till "Self-Aware"
*   **Utmaning:** En statisk HTML-sida visar inte om servern håller på att brinna upp.
*   **Lösning:** Vi skrev ett Python-script med `psutil` som agerar brygga mellan systemkärnan och presentationslagret (HTML).

---

## Framtid (Next Steps)
För att ta detta till produktion skulle vi:
*   Lägga till en **Load Balancer (ALB)** framför servern.
*   Flytta Terraform State till **S3/DynamoDB** för team-samarbete.
*   Sätta upp **Alertmanager** för att skicka Slack-notiser vid kaos.

---
