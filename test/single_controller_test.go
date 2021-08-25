package test

import (
   "fmt"
   http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
   "github.com/gruntwork-io/terratest/modules/logger"
   "github.com/gruntwork-io/terratest/modules/random"
   "github.com/gruntwork-io/terratest/modules/retry"
   "github.com/gruntwork-io/terratest/modules/terraform"
   test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
   "github.com/stretchr/testify/assert"
   "path/filepath"
   "strings"
   "testing"
   "time"
   "os"
)

const WebsiteNameKey = "website_name"
const WebsiteOutput = "s3_bucket_website_endpoint"

func TestDeployment(t *testing.T) {
   t.Parallel()

   gcpCreds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
   region := os.Getenv("region")
   create_networking := os.Getenv("create_networking")
   service_account_email := os.Getenv("service_account_email")
   controller_default_password := os.Getenv("controller_default_password")
   controller_image_gs_path := os.Getenv("controller_image_gs_path")
   controller_image_gs_path := os.Getenv("controller_image_gs_path")

	if gcpCreds == "" {
		t.Fatalf("GOOGLE_APPLICATION_CREDENTIALS environment variable cannot be empty.")
	}
   TerraformDir := "../examples/single-controller"

   // Uncomment these when doing local testing if you need to skip any stages.
   //os.Setenv("SKIP_bootstrap", "true")
   //os.Setenv("SKIP_apply", "true")
   //os.Setenv("SKIP_perpetual_diff", "true")
   //os.Setenv("SKIP_website_tests", "true")
   //os.Setenv("SKIP_destroy", "true")

   test_structure.RunTestStage(t, "bootstrap", func() {
      random := strings.ToLower(random.UniqueId())
      randomName := fmt.Sprintf("terratest-gh-actions-%s", random)
      test_structure.SaveString(t, TerraformDir, WebsiteNameKey, randomName)
   })

   // At the end of the test, run `terraform destroy` to clean up any resources that were created
   defer test_structure.RunTestStage(t, "teardown", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      terraform.Destroy(t, terraformOptions)
   })

   // Apply the infrastructure
   test_structure.RunTestStage(t, "apply", func() {
      websiteName := test_structure.LoadString(t, TerraformDir, WebsiteNameKey)
      terratestOptions := &terraform.Options{
         // The path to where your Terraform code is located
         TerraformDir: TerraformDir,
         Vars: map[string]interface{}{
            "website_name": websiteName,
         },
      }
      // Save the terraform oprions for future reference
      test_structure.SaveTerraformOptions(t, TerraformDir, terratestOptions)
      terraform.InitAndApply(t, terratestOptions)
   })

   // Run perpetual diff
   test_structure.RunTestStage(t, "perpetual_diff", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      planResult := terraform.Plan(t, terraformOptions)

      // Make sure the plan shows zero changes
      assert.Contains(t, planResult, "No changes.")
   })

   // Run HTTP tests
   test_structure.RunTestStage(t, "website_tests", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      websiteEndpoint := terraform.OutputRequired(t, terraformOptions, WebsiteOutput)

      testURL(t, websiteEndpoint, "", 200, "Hello, index!")
      testURL(t, websiteEndpoint, "notfound", 404, "Hello, error!")
   })
}

func testURL(t *testing.T, endpoint string, path string, expectedStatus int, expectedBody string) {
   url := fmt.Sprintf("%s://%s/%s", "http", endpoint, path)
   actionDescription := fmt.Sprintf("Calling %s", url)
   output := retry.DoWithRetry(t, actionDescription, 10, 10 * time.Second, func() (string, error) {
      statusCode, body := http_helper.HttpGet(t, url, nil)
      if statusCode == expectedStatus {
         logger.Logf(t, "Got expected status code %d from URL %s", expectedStatus, url)
         return body, nil
      }
      return "", fmt.Errorf("got status %d instead of the expected %d from %s", statusCode, expectedStatus, url)
   })
   assert.Contains(t, output, expectedBody, "Body should contain expected text")
}