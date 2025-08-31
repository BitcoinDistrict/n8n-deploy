#!/bin/bash
set -e

echo "🚀 n8n Deployment Setup Script"
echo "==============================="

# Check if age is installed
if ! command -v age &> /dev/null; then
    echo "❌ age is not installed. Please install it first:"
    echo "   sudo apt-get install age"
    exit 1
fi

# Check if sops is installed
if ! command -v sops &> /dev/null; then
    echo "❌ sops is not installed. Please install it first:"
    echo "   sudo apt-get install sops"
    exit 1
fi

echo "📝 Step 1: Generate age keypair"
if [ -f "key.txt" ]; then
    echo "⚠️  key.txt already exists. Skipping key generation."
    echo "   If you want to regenerate, delete key.txt first."
else
    age-keygen -o key.txt
    echo "✅ Age keypair generated and saved to key.txt"
fi

# Extract public key
PUBLIC_KEY=$(grep -o 'age1[a-z0-9]*' key.txt)
echo "📋 Your public key: $PUBLIC_KEY"

echo ""
echo "📝 Step 2: Update .sops.yaml with your public key"
sed -i "s/age1replace_this_with_your_public_key/$PUBLIC_KEY/" .sops.yaml
echo "✅ Updated .sops.yaml with your public key"

echo ""
echo "📝 Step 3: Configure your environment"
echo "Please edit the following files:"
echo "   - app/Caddyfile (replace n8n.example.org with your domain)"
echo "   - ansible/roles/n8n/templates/.env.sops (update environment variables)"

read -p "Press Enter when you've updated the configuration files..."

echo ""
echo "📝 Step 4: Encrypt secrets with SOPS"
sops --encrypt --in-place ansible/roles/n8n/templates/.env.sops
echo "✅ Environment file encrypted with SOPS"

echo ""
echo "📝 Step 5: GitHub Secrets Configuration"
echo "Add the following secrets to your GitHub repository:"
echo ""
echo "AGE_PRIVATE_KEY:"
echo "=================="
cat key.txt | grep -A 20 "# created:"
echo ""
echo "SSH_HOST: (your server IP or hostname)"
echo "SSH_USER: (your SSH username, e.g., root or deploy)"
echo "SSH_PORT: (optional, defaults to 22)"
echo "SSH_PRIVATE_KEY: (contents of your SSH private key)"
echo ""

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add the GitHub secrets listed above"
echo "2. git add ."
echo "3. git commit -m 'Initial n8n deployment setup'"
echo "4. git push origin main"
echo ""
echo "The GitHub Action will automatically deploy n8n to your server!"

# Remind about key security
echo ""
echo "🔒 SECURITY REMINDER:"
echo "   - Keep key.txt secure and never commit it to git"
echo "   - The .gitignore already excludes key.txt"
echo "   - Consider backing up key.txt securely"
