// +build e2e

package test

import (
   "fmt"
   http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
   "github.com/gruntwork-io/terratest/modules/logger"
   "github.com/gruntwork-io/terratest/modules/retry"
   "github.com/gruntwork-io/terratest/modules/random"
   "github.com/gruntwork-io/terratest/modules/terraform"
   test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
   "github.com/stretchr/testify/assert"
   "strings"
   "testing"
   "time"
   "os"
   "crypto/tls"
)

func getTerraVars() map[string]interface{} {
   terraVars := make(map[string]interface{})

	for _, element := range os.Environ() {
		//variable := strings.Split(element, "=")
      variable := strings.SplitN(element, "=", 2)

		if strings.HasPrefix(variable[0], "TF_VAR_") == true {
			envName := strings.Split(variable[0], "TF_VAR_")
			terraVars[envName[1]] = variable[1]
		}
	}
   return terraVars
}

func TestDeployment(t *testing.T) {
   t.Parallel()

   gcpCreds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	if gcpCreds == "" {
		t.Fatalf("GOOGLE_APPLICATION_CREDENTIALS environment variable cannot be empty.")
	}

   siteType := os.Getenv("site_type")

   if siteType == "" {
		t.Fatalf("site_type environment variable cannot be empty. single-site or gslb are valid values")
	}
   
   TerraformDir := "../examples/" + siteType

   // Uncomment these when doing local testing if you need to skip any stages.
   //os.Setenv("SKIP_bootstrap", "true")
   //os.Setenv("SKIP_apply", "true")
   os.Setenv("SKIP_perpetual_diff", "true")
   //os.Setenv("SKIP_website_tests", "true")
   os.Setenv("SKIP_teardown", "true")
   os.Setenv("SKIP_destroy", "true")

   test_structure.RunTestStage(t, "bootstrap", func() {
      string_name := "TF_VAR_name_prefix"
      random := strings.ToLower(random.UniqueId())
      randomName := fmt.Sprintf("terraform%s", random)
      os.Setenv(string_name, randomName)
      test_structure.SaveString(t, TerraformDir, string_name, randomName )
   })

   // At the end of the test, run `terraform destroy` to clean up any resources that were created
   defer test_structure.RunTestStage(t, "teardown", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      terraform.Destroy(t, terraformOptions)
   })

   // Apply the infrastructure
   test_structure.RunTestStage(t, "apply", func() {
      terraVars := getTerraVars()
      terratestOptions := &terraform.Options{
         // The path to where your Terraform code is located
         TerraformDir: TerraformDir,
         Vars: terraVars,
      }
      // Save the terraform oprions for future reference
      test_structure.SaveTerraformOptions(t, TerraformDir, terratestOptions)
      output := terraform.InitAndApply(t, terratestOptions)
      assert.Contains(t, output, "Apply complete!")
   })

   // Run perpetual diff
   test_structure.RunTestStage(t, "perpetual_diff", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      planResult := terraform.Plan(t, terraformOptions)

      // Make sure the plan shows zero changes
      assert.Contains(t, planResult, "No changes.")
   })

   // Destroy the infrastructure - used during development - the teardown function will be used normally
   test_structure.RunTestStage(t, "destroy", func() {
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)
      terraform.Destroy(t, terraformOptions)
   })

   // Run HTTP tests
   test_structure.RunTestStage(t, "website_tests", func() {
      var controllerEndpoint interface{}
      terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

      //controllerInfo :=  terraform.OutputRequired(t, terraformOptions, "controllers" )
      controllerInfo :=  terraform.OutputListOfObjects(t, terraformOptions, "controllers" )
      
      publicIP := os.Getenv("TF_VAR_controller_public_address")
      if publicIP == "true" {
         controllerEndpoint = controllerInfo[0]["public_ip_address"]
      } else {
         controllerEndpoint = controllerInfo[0]["private_ip_address"]
      }
      url := fmt.Sprintf("%v", controllerEndpoint)
      testURL(t, url, "", 200, "Avi Vantage Controller")
      testURL(t, url, "notfound", 404, "not found")
   })

}

func testURL(t *testing.T, endpoint string, path string, expectedStatus int, expectedBody string) {
   tlsConfig := tls.Config{InsecureSkipVerify: true}
   url := fmt.Sprintf("%s://%s/%s", "https", endpoint, path)
   actionDescription := fmt.Sprintf("Calling %s", url)
   output := retry.DoWithRetry(t, actionDescription, 10, 10 * time.Second, func() (string, error) {
      statusCode, body := http_helper.HttpGet(t, url, &tlsConfig)
      if statusCode == expectedStatus {
         logger.Logf(t, "Got expected status code %d from URL %s", expectedStatus, url)
         return body, nil
      }
      return "", fmt.Errorf("got status %d instead of the expected %d from %s", statusCode, expectedStatus, url)
   })
   assert.Contains(t, output, expectedBody, "Body should contain expected text")
}