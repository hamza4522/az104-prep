# 🔑 Lab 01 — Azure Key Vault: Secrets, Keys & Certificates

**Difficulty:** 🟡 Intermediate  
**Time:** 60 minutes  
**Goal:** Master Azure Key Vault — the AWS KMS + Secrets Manager equivalent

---

## Background

| Feature | Azure Key Vault | AWS KMS | AWS Secrets Manager | GCP Secret Manager |
|---|---|---|---|---|
| Symmetric keys | HSM-backed | ✅ | ❌ | ❌ |
| Asymmetric keys | RSA/EC keys | RSA only | ❌ | ❌ |
| Secrets | ✅ | ❌ | ✅ | ✅ |
| Certificates | ✅ | ❌ | ❌ | ❌ |
| Soft delete | ✅ | ✅ | ✅ | ✅ |
| Auto-rotation | ✅ | ✅ | ✅ | ❌ native |
| Access control | RBAC or Access Policies | Resource-based policies | IAM policies | IAM |
| Hardware security | HSM-backed (Premium) | CloudHSM | ❌ | Cloud HSM |

---

## Part 1 — Create Key Vault

```bash
RG="rg-security-lab"
LOCATION="eastus"
KV_NAME="kv-lab-$(date +%s)"  # Globally unique, 3-24 chars

az group create --name $RG --location $LOCATION

# Create Key Vault
az keyvault create \
  --resource-group $RG \
  --name $KV_NAME \
  --location $LOCATION \
  --sku standard \
  --enable-rbac-authorization true \
  --enable-soft-delete true \
  --soft-delete-retention-days 90 \
  --enable-purge-protection false \
  --tags Environment=Lab

# For production: enable purge protection (cannot be disabled!)
# --enable-purge-protection true

# View vault
az keyvault show \
  --resource-group $RG \
  --name $KV_NAME \
  --output json

echo "Key Vault URI: https://${KV_NAME}.vault.azure.net/"

# Get current user's object ID and grant admin access
CURRENT_USER_ID=$(az ad signed-in-user show --query id --output tsv)

az role assignment create \
  --assignee $CURRENT_USER_ID \
  --role "Key Vault Administrator" \
  --scope $(az keyvault show --resource-group $RG --name $KV_NAME --query id --output tsv)
```

---

## Part 2 — Secrets Management

```bash
# =========================================
# Create Secrets (like AWS Secrets Manager / GCP Secret Manager)
# =========================================

# Simple secret
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "db-password" \
  --value "SuperSecretDBPassword2024!" \
  --description "Production database password" \
  --content-type "text/plain"

# Secret with expiry (auto-rotation prompt)
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "api-key" \
  --value "sk-prod-abc123def456ghi789" \
  --expires "$(date -u -d '+90 days' '+%Y-%m-%dT%H:%MZ')" \
  --not-before "$(date -u '+%Y-%m-%dT%H:%MZ')"

# Store JSON (connection strings, complex config)
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "db-connection-string" \
  --value "Server=tcp:sqlsrv.database.windows.net;Database=mydb;User ID=admin;Password=pass123" \
  --content-type "application/x-connection-string"

# Store multi-line certificate or key content
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "ssh-private-key" \
  --file ~/.ssh/id_rsa

# List secrets (names only, not values)
az keyvault secret list \
  --vault-name $KV_NAME \
  --output table

# Get secret value
az keyvault secret show \
  --vault-name $KV_NAME \
  --name "db-password" \
  --query value \
  --output tsv

# Get secret and use in script
DB_PASSWORD=$(az keyvault secret show \
  --vault-name $KV_NAME \
  --name "db-password" \
  --query value \
  --output tsv)

echo "Retrieved DB Password (length: ${#DB_PASSWORD})"

# List secret versions
az keyvault secret list-versions \
  --vault-name $KV_NAME \
  --name "db-password" \
  --output table

# Get specific version
az keyvault secret show \
  --vault-name $KV_NAME \
  --name "db-password" \
  --version "SPECIFIC_VERSION_ID"

# Disable a secret version (without deleting)
az keyvault secret set-attributes \
  --vault-name $KV_NAME \
  --name "db-password" \
  --enabled false

# Delete secret (soft delete — recoverable for 90 days)
az keyvault secret delete \
  --vault-name $KV_NAME \
  --name "old-api-key"

# List deleted secrets
az keyvault secret list-deleted \
  --vault-name $KV_NAME \
  --output table

# Recover deleted secret
az keyvault secret recover \
  --vault-name $KV_NAME \
  --name "old-api-key"

# Purge (permanently delete — only works if purge protection is disabled)
az keyvault secret purge \
  --vault-name $KV_NAME \
  --name "old-api-key"
```

### Access Secrets from Application Code

```python
# pip install azure-keyvault-secrets azure-identity

from azure.keyvault.secrets import SecretClient
from azure.identity import (
    DefaultAzureCredential,
    ManagedIdentityCredential,
    EnvironmentCredential,
    ChainedTokenCredential,
)

KEY_VAULT_URL = "https://kv-lab-123456.vault.azure.net/"

# DefaultAzureCredential tries multiple auth methods in order:
# 1. Environment variables (ARM_CLIENT_ID etc.)
# 2. Workload Identity (AKS pods)
# 3. Managed Identity (VMs, Functions, App Service)
# 4. Azure CLI (local development: az login)
# 5. Visual Studio Code Azure login
credential = DefaultAzureCredential()

client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)

# Get secret
db_password = client.get_secret("db-password").value
print(f"Got secret: {'*' * len(db_password)}")  # Never log actual secret!

# Set secret
client.set_secret("new-secret", "my-secret-value")

# Delete secret
client.begin_delete_secret("old-secret").result()

# List all secrets
for secret in client.list_properties_of_secrets():
    print(f"  {secret.name}: enabled={secret.enabled}, expires={secret.expires_on}")

# =========================================
# Pattern: Load all secrets at startup
# =========================================
class Config:
    def __init__(self, vault_url: str):
        credential = DefaultAzureCredential()
        self.client = SecretClient(vault_url=vault_url, credential=credential)
        self._cache = {}
    
    def get(self, name: str) -> str:
        """Get secret with caching"""
        if name not in self._cache:
            self._cache[name] = self.client.get_secret(name).value
        return self._cache[name]
    
    def load_all(self):
        """Load all secrets at startup"""
        for secret_prop in self.client.list_properties_of_secrets():
            if secret_prop.enabled:
                self._cache[secret_prop.name] = self.client.get_secret(secret_prop.name).value
        return self

config = Config(KEY_VAULT_URL).load_all()
DB_PASSWORD = config.get("db-password")
API_KEY = config.get("api-key")
```

---

## Part 3 — Cryptographic Keys

```bash
# =========================================
# Create Keys (like AWS KMS keys)
# Used for encryption/decryption operations
# =========================================

# RSA key (asymmetric) — for encryption, digital signatures
az keyvault key create \
  --vault-name $KV_NAME \
  --name "rsa-key-2048" \
  --kty RSA \
  --size 2048 \
  --ops encrypt decrypt sign verify \
  --protection software  # or 'hsm' for hardware-backed

# RSA-4096 key
az keyvault key create \
  --vault-name $KV_NAME \
  --name "rsa-key-4096" \
  --kty RSA \
  --size 4096 \
  --ops sign verify

# EC key (Elliptic Curve) — for signatures, JWT
az keyvault key create \
  --vault-name $KV_NAME \
  --name "ec-key-p256" \
  --kty EC \
  --curve P-256 \
  --ops sign verify

# List keys
az keyvault key list \
  --vault-name $KV_NAME \
  --output table

# Get key (public part only — private never leaves Key Vault)
az keyvault key show \
  --vault-name $KV_NAME \
  --name "rsa-key-2048" \
  --output json

# Download public key
az keyvault key download \
  --vault-name $KV_NAME \
  --name "rsa-key-2048" \
  --file public-key.pem \
  --encoding PEM

# Rotate key (create new version)
az keyvault key rotate \
  --vault-name $KV_NAME \
  --name "rsa-key-2048"

# Configure auto-rotation policy
az keyvault key rotation-policy update \
  --vault-name $KV_NAME \
  --name "rsa-key-2048" \
  --value '{
    "lifetimeActions": [
      {
        "action": {"type": "Rotate"},
        "trigger": {"timeBeforeExpiry": "P30D"}
      },
      {
        "action": {"type": "Notify"},
        "trigger": {"timeBeforeExpiry": "P7D"}
      }
    ],
    "attributes": {
      "expiryTime": "P1Y"
    }
  }'
```

### Encrypt/Decrypt with Key Vault Keys

```python
# pip install azure-keyvault-keys

from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, EncryptionAlgorithm, SignatureAlgorithm
from azure.identity import DefaultAzureCredential
import hashlib

KV_URL = "https://kv-lab-123456.vault.azure.net/"
credential = DefaultAzureCredential()

key_client = KeyClient(vault_url=KV_URL, credential=credential)
key = key_client.get_key("rsa-key-2048")

# Create crypto client for operations with a specific key
crypto_client = CryptographyClient(key, credential=credential)

# Encrypt data
plaintext = b"Sensitive data to encrypt"
encrypt_result = crypto_client.encrypt(EncryptionAlgorithm.rsa_oaep, plaintext)
ciphertext = encrypt_result.ciphertext
print(f"Encrypted: {ciphertext[:20]}...")

# Decrypt data
decrypt_result = crypto_client.decrypt(EncryptionAlgorithm.rsa_oaep, ciphertext)
decrypted = decrypt_result.plaintext
print(f"Decrypted: {decrypted.decode()}")

# Sign data (create digital signature)
data_to_sign = b"Data to sign"
digest = hashlib.sha256(data_to_sign).digest()
sign_result = crypto_client.sign(SignatureAlgorithm.rs256, digest)
signature = sign_result.signature

# Verify signature
verify_result = crypto_client.verify(SignatureAlgorithm.rs256, digest, signature)
print(f"Signature valid: {verify_result.is_valid}")
```

---

## Part 4 — Certificate Management

```bash
# =========================================
# Certificates (Key Vault as CA or CSR manager)
# =========================================

# Create self-signed certificate (for testing)
az keyvault certificate create \
  --vault-name $KV_NAME \
  --name "self-signed-cert" \
  --policy '{
    "keyProperties": {
      "exportable": true,
      "keyType": "RSA",
      "keySize": 2048,
      "reuseKey": false
    },
    "secretProperties": {
      "contentType": "application/x-pkcs12"
    },
    "x509CertificateProperties": {
      "subject": "CN=myapp.contoso.com",
      "subjectAlternativeNames": {
        "dnsNames": ["myapp.contoso.com", "*.myapp.contoso.com"]
      },
      "validityInMonths": 12
    },
    "issuerParameters": {
      "name": "Self"
    },
    "lifetimeActions": [
      {
        "action": {"actionType": "AutoRenew"},
        "trigger": {"daysBeforeExpiry": 30}
      }
    ]
  }'

# Check certificate creation status
az keyvault certificate pending show \
  --vault-name $KV_NAME \
  --name "self-signed-cert"

# Wait for certificate to be ready
az keyvault certificate show \
  --vault-name $KV_NAME \
  --name "self-signed-cert" \
  --output json

# Download certificate (PEM format)
az keyvault certificate download \
  --vault-name $KV_NAME \
  --name "self-signed-cert" \
  --file cert.pem \
  --encoding PEM

# Download as PFX (PKCS12 — includes private key)
az keyvault secret download \
  --vault-name $KV_NAME \
  --name "self-signed-cert" \
  --file cert.pfx \
  --encoding base64

# List certificates
az keyvault certificate list \
  --vault-name $KV_NAME \
  --output table

# Import an existing certificate
az keyvault certificate import \
  --vault-name $KV_NAME \
  --name "imported-cert" \
  --file certificate.pfx \
  --password "pfx-password"

# Configure Let's Encrypt with DigiCert integration
az keyvault certificate issuer create \
  --vault-name $KV_NAME \
  --issuer-name "DigiCert" \
  --provider-name DigiCert \
  --account-id "DIGICERT_ACCOUNT_ID" \
  --password "DIGICERT_API_KEY" \
  --organization-id "DIGICERT_ORG_ID"
```

---

## Part 5 — Key Vault Access Control & Networking

```bash
# =========================================
# RBAC Roles for Key Vault
# =========================================

KV_ID=$(az keyvault show --resource-group $RG --name $KV_NAME --query id --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Grant application read-only secrets access
APP_SP_ID=$(az ad sp list --display-name "sp-myapp" --query "[0].id" --output tsv)
az role assignment create \
  --assignee $APP_SP_ID \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID/secrets/db-password"  # Specific secret only!

# Grant VM managed identity certificate access
VM_IDENTITY_ID=$(az vm identity show \
  --resource-group $RG \
  --name vm-monitored \
  --query principalId \
  --output tsv 2>/dev/null)

if [ -n "$VM_IDENTITY_ID" ]; then
  az role assignment create \
    --assignee $VM_IDENTITY_ID \
    --role "Key Vault Certificate User" \
    --scope $KV_ID
fi

# Security team: read all secrets (for audit)
SECURITY_GROUP_ID=$(az ad group show --group "grp-security-admins" --query id --output tsv 2>/dev/null)
if [ -n "$SECURITY_GROUP_ID" ]; then
  az role assignment create \
    --assignee $SECURITY_GROUP_ID \
    --role "Key Vault Secrets User" \
    --scope $KV_ID
fi

# =========================================
# Network Restrictions (firewall)
# =========================================
az keyvault update \
  --resource-group $RG \
  --name $KV_NAME \
  --default-action Deny \
  --bypass AzureServices

# Allow specific VNet/subnet
az keyvault network-rule add \
  --resource-group $RG \
  --name $KV_NAME \
  --vnet-name vnet-lab \
  --subnet subnet-private

# Allow specific IP
MY_IP=$(curl -s https://api.ipify.org)
az keyvault network-rule add \
  --resource-group $RG \
  --name $KV_NAME \
  --ip-address $MY_IP

# View network rules
az keyvault network-rule list \
  --resource-group $RG \
  --name $KV_NAME \
  --output json

# =========================================
# Private Endpoint (most secure — no public access)
# =========================================
az network private-endpoint create \
  --name "pe-${KV_NAME}" \
  --resource-group $RG \
  --vnet-name vnet-lab \
  --subnet subnet-private \
  --private-connection-resource-id $KV_ID \
  --group-id vault \
  --connection-name "pe-kv-connection"

# Private DNS for Key Vault
az network private-dns zone create \
  --resource-group $RG \
  --name "privatelink.vaultcore.azure.net"

az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name "privatelink.vaultcore.azure.net" \
  --name "dns-link-vnet-lab" \
  --virtual-network vnet-lab \
  --registration-enabled false

# Auto-register DNS for private endpoint
az network private-endpoint dns-zone-group create \
  --resource-group $RG \
  --endpoint-name "pe-${KV_NAME}" \
  --name "privatelink-dns" \
  --private-dns-zone "privatelink.vaultcore.azure.net" \
  --zone-name vault

echo "✅ Key Vault secured with private endpoint"
```

---

## Cleanup

```bash
az group delete --name rg-security-lab --yes --no-wait
rm -f public-key.pem cert.pem cert.pfx
```

---

## ✅ Lab Checklist

- [ ] Created Key Vault with RBAC authorization
- [ ] Created secrets with expiry dates
- [ ] Retrieved secrets from CLI and Python SDK
- [ ] Created RSA and EC cryptographic keys
- [ ] Encrypted and decrypted data using Key Vault
- [ ] Created digital signature and verified it
- [ ] Created self-signed certificate
- [ ] Imported an existing certificate
- [ ] Configured auto-rotation policy
- [ ] Applied RBAC roles (Secrets User, Secrets Officer, Administrator)
- [ ] Configured network firewall rules
- [ ] Created private endpoint
- [ ] Set up Private DNS for Key Vault

---

## 📚 Key Security Best Practices

1. **Use Managed Identities** — no credentials stored in code
2. **Enable RBAC authorization** — more granular than Access Policies
3. **Enable Soft Delete** — recoverable for 90 days
4. **Enable Purge Protection** in production — prevents permanent deletion
5. **Use Private Endpoints** — no public exposure
6. **Monitor access** — enable diagnostic logs to Log Analytics
7. **Set secret expiry** — never create secrets that never expire
8. **Least privilege** — use `Key Vault Secrets User` (read-only) not Administrator
