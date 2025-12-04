#!/bin/bash
#
# Post-create script for Terraform Course Codespace
# This runs automatically when the Codespace is created
#

set -e

echo "🚀 Setting up Terraform Course environment..."

# Create Terraform plugin cache directory
# Use sudo if needed (handles permission issues in some container setups)
if ! mkdir -p ~/.terraform.d/plugin-cache 2>/dev/null; then
  echo "⚠️  Creating terraform directory with sudo..."
  sudo mkdir -p ~/.terraform.d/plugin-cache
  sudo chown -R $(whoami):$(whoami) ~/.terraform.d
fi

# Install vim and neovim
echo "📝 Installing vim and neovim..."
sudo apt-get update -qq && sudo apt-get install -y -qq vim neovim

# Install Infracost
echo "📊 Installing Infracost..."
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Install checkov for security scanning
echo "🔒 Installing Checkov..."
pip3 install --quiet checkov

# Install tflint
echo "🔍 Installing TFLint..."
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install conftest for Rego policy testing
echo "📋 Installing Conftest..."
CONFTEST_VERSION="0.46.0"
curl -sL "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/conftest /usr/local/bin/

# Install act for local GitHub Actions testing
echo "🎬 Installing act..."
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Verify installations
echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Installed tools:"
echo "  - Terraform: $(terraform version -json | jq -r '.terraform_version')"
echo "  - Hugo:      $(hugo version | grep -oP 'v[\d.]+')"
echo "  - AWS CLI:   $(aws --version | cut -d' ' -f1)"
echo "  - Infracost: $(infracost --version)"
echo "  - Checkov:   $(checkov --version 2>/dev/null | head -1)"
echo "  - TFLint:    $(tflint --version | head -1)"
echo "  - Conftest:  $(conftest --version)"
echo "  - act:       $(act --version)"
echo "  - gh CLI:    $(gh --version | head -1)"
echo "  - git-lfs:   $(git lfs version | head -1)"
echo "  - vim:       $(vim --version | head -1 | cut -d' ' -f5)"
echo "  - neovim:    $(nvim --version | head -1)"
echo ""
echo "📚 Ready for Terraform labs!"
echo ""
echo "Quick start:"
echo "  1. Configure AWS: aws configure"
echo "  2. Or use GitHub Secrets for CI/CD"
echo ""
echo "Testing locally:"
echo "  - Test Rego policies: conftest test plan.json --policy week-00/lab-00/.validator/policy"
echo "  - Test GitHub Actions: act -l                    # list workflows"
echo "                         act pull_request          # run PR workflow"
echo ""
