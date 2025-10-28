#!/bin/bash

# GitHub Actions Workflow Test Script
# This script tests the validation logic from the GitHub Actions workflow locally

echo "🧪 Testing GitHub Actions Workflow Validation Logic"
echo "=================================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    # Run the test command
    if eval "$test_command" > /dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi
    
    if [ "$actual_result" = "$expected_result" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} (expected: $expected_result, got: $actual_result)"
        ((TESTS_FAILED++))
    fi
}

echo "1. Testing SSH Key Validation Logic"
echo "-----------------------------------"

# Test valid SSH keys
run_test "Valid RSA SSH key" 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... user@host" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "pass"

run_test "Valid ED25519 SSH key" 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@host" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "pass"

run_test "Valid ECDSA SSH key" 'echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTI... user@host" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "pass"

# Test invalid SSH keys
run_test "Invalid SSH key (wrong prefix)" 'echo "rsa-ssh AAAAB3NzaC1yc2EAAAADAQABAAABAQ... user@host" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "fail"

run_test "Invalid SSH key (no prefix)" 'echo "AAAAB3NzaC1yc2EAAAADAQABAAABAQ... user@host" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "fail"

run_test "Empty SSH key" 'echo "" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "fail"

echo
echo "2. Testing Terraform Validation (without actual secrets)"
echo "--------------------------------------------------------"

# Create temporary test variables
export TF_VAR_linode_api_token="test_token_123"
export TF_VAR_ssh_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ test@host"
export TF_VAR_root_password="TestPass123!"

cd terraform

# Test Terraform validation
run_test "Terraform init (dry run)" 'terraform init -backend=false' "pass"
run_test "Terraform validate" 'terraform validate' "pass"
run_test "Terraform fmt check" 'terraform fmt -check' "pass"

# Test with invalid variables
export TF_VAR_ssh_public_key=""
run_test "Empty SSH key validation" 'terraform validate' "fail"

export TF_VAR_ssh_public_key="invalid-key-format"
run_test "Invalid SSH key format validation" 'terraform validate' "fail"

export TF_VAR_root_password="short"
run_test "Short password validation" 'terraform validate' "fail"

# Clean up
unset TF_VAR_linode_api_token
unset TF_VAR_ssh_public_key
unset TF_VAR_root_password

cd ..

echo
echo "3. Testing Workflow File Syntax"
echo "-------------------------------"

# Check if workflow file is valid YAML
run_test "GitHub Actions workflow YAML syntax" 'python3 -c "import yaml; yaml.safe_load(open(\".github/workflows/terraform.yml\"))"' "pass"

# Check if all required steps are present
run_test "Workflow has SSH validation step" 'grep -q "Validate SSH Public Key" .github/workflows/terraform.yml' "pass"
run_test "Workflow has secrets validation step" 'grep -q "Validate Required Secrets" .github/workflows/terraform.yml' "pass"
run_test "Workflow uses LINODE_PAT" 'grep -q "LINODE_PAT" .github/workflows/terraform.yml' "pass"

echo
echo "4. Testing Local SSH Key Detection"
echo "----------------------------------"

# Test if we can find local SSH keys
if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    run_test "Local RSA key detection" 'test -f "$HOME/.ssh/id_rsa.pub"' "pass"
    
    # Validate the local key format
    local_key=$(cat "$HOME/.ssh/id_rsa.pub")
    run_test "Local RSA key format validation" 'echo "$local_key" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "pass"
else
    echo "No local RSA key found - this is okay"
fi

if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    run_test "Local ED25519 key detection" 'test -f "$HOME/.ssh/id_ed25519.pub"' "pass"
    
    # Validate the local key format
    local_key=$(cat "$HOME/.ssh/id_ed25519.pub")
    run_test "Local ED25519 key format validation" 'echo "$local_key" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"' "pass"
else
    echo "No local ED25519 key found - this is okay"
fi

echo
echo "📊 Test Results Summary"
echo "======================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo
    echo -e "${GREEN}🎉 All tests passed! The workflow validation logic is working correctly.${NC}"
    echo
    echo "Next steps to test with real GitHub Actions:"
    echo "1. Set the required GitHub secrets (LINODE_PAT, SSH_PUBLIC_KEY, ROOT_PASSWORD)"
    echo "2. Commit and push changes to trigger the workflow"
    echo "3. Check the Actions tab for validation results"
else
    echo
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi