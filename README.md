# Landing App — Docker + Terraform + GitHub Actions on GCP

A minimal contact form running on **Google Cloud Run**, built with **Docker**,
infrastructure provisioned by **Terraform**, and deployed automatically via **GitHub Actions**.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  GitHub (push to main)                              │
│    └─> GitHub Actions                               │
│          ├─> docker build + push → Artifact Registry│
│          └─> gcloud run deploy   → Cloud Run        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Terraform (run once to set up infra)               │
│    ├─> Enables GCP APIs                             │
│    ├─> Creates Artifact Registry repo               │
│    ├─> Creates GitHub Actions service account + IAM │
│    └─> Creates Cloud Run service                    │
└─────────────────────────────────────────────────────┘
```

---

## Project Structure

```
landing-app/
├── .github/
│   └── workflows/
│       └── deploy.yml       # CI/CD: build → push → deploy on every push to main
├── app/
│   ├── main.py              # Flask app (serves form + handles POST /submit)
│   ├── requirements.txt     # flask + gunicorn
│   ├── Dockerfile           # Container definition
│   ├── .dockerignore
│   └── static/
│       └── index.html       # Contact form UI
└── terraform/
    ├── main.tf              # All GCP resources
    ├── variables.tf
    └── outputs.tf
```

---

## One-Time Setup

### Step 1 — Provision infrastructure with Terraform

```bash
cd terraform

terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

This creates everything in GCP. Note the outputs:
- `service_url` — your live app URL
- `github_actions_sa_email` — the service account for GitHub Actions

### Step 2 — Create a key for the GitHub Actions service account

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=$(terraform output -raw github_actions_sa_email)
```

### Step 3 — Add GitHub Secrets

In your GitHub repo → **Settings → Secrets and variables → Actions**, add:

| Secret name     | Value                              |
|-----------------|------------------------------------|
| `GCP_PROJECT_ID`| Your GCP project ID                |
| `GCP_SA_KEY`    | Contents of the `key.json` file    |

> ⚠️ Delete `key.json` from your machine after copying it.

### Step 4 — Push to main

```bash
git add .
git commit -m "initial deploy"
git push origin main
```

GitHub Actions will build the Docker image, push it to Artifact Registry, and deploy it to Cloud Run automatically. The live URL is printed at the end of the workflow run.

---

## How the Pipeline Works (deploy.yml)

```
push to main
    │
    ├─ 1. Checkout code
    ├─ 2. Auth to GCP (using GCP_SA_KEY secret)
    ├─ 3. Configure Docker for Artifact Registry
    ├─ 4. docker build  (tagged with git SHA + latest)
    ├─ 5. docker push
    ├─ 6. gcloud run deploy  (uses the SHA tag — always exact)
    └─ 7. Print live URL
```

Each deploy uses the **git commit SHA** as the image tag so every deployment is
traceable to an exact commit. The `latest` tag is also pushed for convenience.

---

## Local Development

```bash
cd app
pip install -r requirements.txt
python main.py
# Visit http://localhost:8080
```

---

## Tear Down

```bash
cd terraform
terraform destroy -var="project_id=YOUR_PROJECT_ID"
```

---

## Interview Talking Points

| Topic | What to say |
|---|---|
| **Dockerfile** | "I copy `requirements.txt` before the app code so Docker caches the pip install layer. If only `main.py` changes, the rebuild skips reinstalling packages entirely." |
| **Gunicorn** | "Flask's dev server is single-threaded and not safe for production. Gunicorn is a proper WSGI server that handles concurrent requests." |
| **Cloud Run** | "Serverless containers — I hand it a Docker image and GCP handles load balancing, TLS, and autoscaling. `min_instance_count = 0` means it scales to zero and costs nothing when idle." |
| **Terraform** | "Infrastructure as code. All GCP resources are declared in `.tf` files, versioned in git. `terraform apply` creates them in dependency order. `lifecycle.ignore_changes` on the image means Terraform sets up the service but doesn't fight with GitHub Actions over which image is running." |
| **GitHub Actions** | "On every push to main the pipeline builds, tags with the git SHA, pushes to Artifact Registry, and deploys. Using the SHA tag means every Cloud Run revision maps to an exact commit — easy to roll back." |
| **Service account + IAM** | "Terraform creates a least-privilege service account for GitHub Actions — only `artifactregistry.writer` and `run.developer`. The key is stored as a GitHub Secret, never in the repo." |
