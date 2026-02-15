# Azure Federated Identity Configuration Guide

This guide explains how to fix the Azure federated identity authentication error:
```
Error: AADSTS700213: No matching federated identity record found for presented assertion subject
```

## 🔍 Understanding the Issue

When using GitHub Actions with Azure, there are two authentication methods:

1. **Service Principal with secrets** (traditional)
   - Uses `AZUREAPPSERVICE_CLIENTID`, `AZUREAPPSERVICE_TENANTID`, `AZUREAPPSERVICE_SUBSCRIPTIONID`
   - No federated identity needed
   - Subject claim: `repo:owner/repo:ref:refs/heads/branch`

2. **Federated Identity Credentials (OIDC)** (modern, more secure)
   - Uses same secrets but with OIDC token exchange
   - Requires federated credential configuration in Azure
   - Subject claim varies based on workflow configuration

## 🎯 The Problem

The error occurs when:
- GitHub Actions sends a subject claim like: `repo:souchan25/virtualHealthAssistant:environment:Production`
- Azure expects a different subject claim (e.g., `repo:souchan25/virtualHealthAssistant:ref:refs/heads/main`)
- The federated credential in Azure doesn't match what GitHub is sending

## ✅ Solution 1: Remove Environment from Workflow (Recommended)

**This solution is already implemented in the current PR.**

By removing the `environment:` section from the workflow, the subject claim becomes:
```
repo:souchan25/virtualHealthAssistant:ref:refs/heads/main
```

### Changes Made:
```yaml
# Before (causes error)
deploy:
  runs-on: ubuntu-latest
  needs: build
  permissions:
    id-token: write
    contents: read
  environment:
    name: 'Production'
    url: ${{ steps.deploy-to-webapp.outputs.webapp-url }}

# After (fixed)
deploy:
  runs-on: ubuntu-latest
  needs: build
  permissions:
    id-token: write
    contents: read
```

### Why This Works:
- No environment = simpler subject claim
- Azure's default federated credential matches this pattern
- No need to reconfigure Azure Portal

---

## ✅ Solution 2: Configure Federated Identity in Azure (Advanced)

If you want to keep the `environment: Production` feature for deployment protection, you need to add a matching federated credential in Azure.

### Step 1: Access Azure Portal

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to **Azure Active Directory** (or **Microsoft Entra ID**)
3. Click **App registrations** in the left sidebar
4. Find your application (search by Client ID from GitHub secrets)
5. Click on it to open

### Step 2: Add Federated Credential

1. In the left sidebar, click **Certificates & secrets**
2. Click the **Federated credentials** tab
3. Click **+ Add credential**
4. Fill in the form:

   **Federated credential scenario:**
   - Select: `GitHub Actions deploying Azure resources`

   **Organization:**
   - Enter: `souchan25` (your GitHub username/org)

   **Repository:**
   - Enter: `virtualHealthAssistant` (your repo name)

   **Entity type:**
   - Select: `Environment`

   **GitHub environment name:**
   - Enter: `Production` (exact match to workflow)

   **Credential details:**
   - Name: `github-production-deployment`
   - Description: `Federated credential for Production environment deployments`

5. Click **Add**

### Step 3: Verify Configuration

After adding, you should see:
- **Subject identifier**: `repo:souchan25/virtualHealthAssistant:environment:Production`
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Audiences**: `api://AzureADTokenExchange`

### Step 4: Re-run Workflow

1. Go to GitHub repository → Actions
2. Find the failed workflow run
3. Click **Re-run all jobs**
4. Authentication should now succeed ✅

---

## 🔒 GitHub Environment Configuration (Optional)

If using Solution 2, you can also configure the `Production` environment in GitHub for additional security:

1. Go to GitHub repository → **Settings** → **Environments**
2. Click **New environment**
3. Name: `Production`
4. Configure protection rules (optional):
   - ✅ Required reviewers (specific team members must approve)
   - ✅ Wait timer (delay before deployment)
   - ✅ Deployment branches (only from `main`)
5. Click **Save protection rules**

---

## 📊 Subject Claim Patterns

Here are the different subject claim patterns GitHub Actions sends:

| Workflow Configuration | Subject Claim Pattern |
|------------------------|----------------------|
| No environment | `repo:owner/repo:ref:refs/heads/main` |
| With environment | `repo:owner/repo:environment:Production` |
| Pull request | `repo:owner/repo:pull_request` |
| With specific branch | `repo:owner/repo:ref:refs/heads/develop` |

Azure federated credential must match **exactly** what GitHub sends.

---

## 🔧 Troubleshooting

### Error: "No matching federated identity record found"

**Cause**: Subject claim mismatch

**Solutions**:
1. ✅ Remove `environment:` from workflow (Solution 1)
2. ✅ Add matching federated credential in Azure (Solution 2)
3. ✅ Check for typos in environment name (case-sensitive!)
4. ✅ Verify subject identifier in Azure matches GitHub

### Error: "Invalid audience"

**Cause**: Audience configuration incorrect

**Solution**:
- Audience must be: `api://AzureADTokenExchange`
- Check federated credential configuration in Azure

### Error: "Invalid issuer"

**Cause**: Issuer URL incorrect

**Solution**:
- Issuer must be: `https://token.actions.githubusercontent.com`
- Verify federated credential settings

---

## 🎯 Recommended Approach

For most projects, **Solution 1 (remove environment)** is recommended because:

✅ **Pros:**
- Simpler configuration (no Azure Portal changes needed)
- Works with default Azure setup
- Less maintenance overhead
- No risk of misconfiguration

❌ **Cons:**
- No deployment protection features
- Can't require manual approval for production
- Can't restrict deployments to specific branches via GitHub UI

**Solution 2 (configure federated identity)** is better if you need:
- Manual approval before production deployment
- Deployment protection rules
- Audit trail via GitHub Environments
- Branch protection for production

---

## 📚 Additional Resources

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Azure Federated Identity Documentation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
- [Azure Web App Deployment Guide](./AZURE_DEPLOYMENT_GUIDE.md)
- [GitHub Secrets Guide](./GITHUB_SECRETS_GUIDE.md)

---

## ✅ Verification

After applying a solution, verify the fix works:

```bash
# Check workflow status
# Go to: https://github.com/souchan25/virtualHealthAssistant/actions

# View recent runs of:
# "Deploy Django Backend to Azure Web App"

# Look for:
# ✅ "Login to Azure" step succeeds (green checkmark)
# ✅ "Deploy to Azure Web App" step succeeds
# ✅ Overall workflow shows "Success"
```

---

**Solution Status**: ✅ **Solution 1 has been applied to this repository**

The `environment: Production` section has been removed from `.github/workflows/azure-django-backend.yml` to fix the federated identity mismatch error.

---

**Last Updated**: February 15, 2026  
**Version**: 1.0
