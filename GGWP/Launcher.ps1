<#
.SYNOPSIS
The script will be utilized to automate test use case provided by GGWP

.DESCRIPTION
The Script will ask for the user details in terminal pane
The Script will not check the syntax of $email, $password
    -The script will make sure the user details are not empty
For execution, You can use VSCode studio with PowerShell extension installed (from market)
    - or you can use powershell_ise directly

.NOTES
You will require Selenium WebDriver.dll to use Selenium with PowerShell
You will require Chrome WebDriver 

#>
#Directory
$dir = $pwd.Path
$workingDirectory = "$dir"
$selDriverPath = Join-Path -Path "$workingDirectory" "\WebDriver.dll"
$chrmDriverPath = Join-Path "$workingDirectory" "114\"
$logFile = Join-Path "$workingDirectory" "Log\Assignment-log.txt"

$firstName = Read-Host "Enter First Name"
$lastName = Read-Host "Enter Last Name"
$email = Read-Host "Enter Email ID"
$credential = Get-Credential -Message "Enter your password" -UserName $email
$confirmCredential = Get-Credential -Message "Enter your password Again" -UserName $email
$password = $credential.GetNetworkCredential().Password
$confirmPassword = $confirmCredential.GetNetworkCredential().Password
$item = Read-Host "Enter item you are seraching for -Only Blue Jeans will work" #will work only for Blue Jeans

#region Create-LogFile
if (-not(Test-Path $logFile)) {
    new-item -Path "$PSScriptRoot\Log" -ItemType Directory -Force
    new-item -Path "$PSScriptRoot\Log\Assignment-log.txt" -ItemType File -Force
}
#endregion Create-LogFile

Write-Output "`n" | Out-File $logFile -Append

#region Import Selenium-WebDriver .dll
try {
    $ErrorActionPreference = 'Stop'
    Add-Type -Path "$selDriverPath"
    Write-Output "Selenium .dll Imported Successfully -  $(Get-Date)" | Out-File $logFile -Append
    # $chrmDriver = [OpenQA.Selenium.Chrome.ChromeDriver]
}
catch {
    Write-Output "Selenium .dll Import error - $error - $(Get-Date)" | Out-File $logFile -Append
}
#endregion Import Selenium-WebDriver .dll

Function Register-User {
    <#
    .DESCRIPTION
    Register-User function will fetch the details provided and register the user in the demo site
    -Will also check if user has login
    If user email already exists, it will stop the registration process
    #>
    try {
        $ErrorActionPreference = 'Stop'
        $chrmDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($chrmDriverPath)
        #Waiting for page to load WebElements
        $chrmDriver.Manage().Timeouts().ImplicitWait = [timespan]::FromSeconds(5)

        $chrmDriver.Manage().Window.Maximize()
        $chrmDriver.Navigate().GoToUrl("https://demowebshop.tricentis.com/")

        $register = $chrmDriver.FindElementByClassName("ico-register")
        $register.Click()

        $maleRadioElement = $chrmDriver.FindElementById("gender-male")
        $maleRadioElement.Click()
    
        $fNameElement = $chrmDriver.FindElementById("FirstName")
        $fNameElement.SendKeys("$firstName")

        $lNameElement = $chrmDriver.FindElementById("LastName")
        $lNameElement.SendKeys("$lastName")

        $emailElement = $chrmDriver.FindElementById("Email")
        $emailElement.SendKeys("$email")

        $passwordElement = $chrmDriver.FindElementById("Password")
        $passwordElement.SendKeys("$password")

        $cPasswordElement = $chrmDriver.FindElementById("ConfirmPassword")
        $cPasswordElement.SendKeys("$confirmPassword") 

        $submitElement = $chrmDriver.FindElementById("register-button")
        $submitElement.Submit()

        #Take The ScreenShot
        $screenShot = $chrmDriver.GetScreenshot()
        $screenShot.SaveAsFile("$workingDirectory\Register.png")

        #$exptectedUrl - URL when user logins after successful registration
        $expectedUrl = "https://demowebshop.tricentis.com/registerresult/1"

        $currentUrl = $chrmDriver.Url

        Start-Sleep -s 3

        #compare the Url's - to make user was registered
        if ($expectedUrl -eq $currentUrl) {
            $continue = $chrmDriver.FindElementByCssSelector(".button-1.register-continue-button")
            $continue.Click()

            Start-Sleep -s 3

            Write-Output "User: $firstName is Registered - $(Get-Date)" | Out-File $logFile -Append
            $userCheck = $chrmDriver.FindElementByClassName("account")
            $testUserCheck = $userCheck.Text
            
            #confirm user has logged in
            if ($email -eq $testUserCheck) {
                Write-Output "User: $firstName , EmailId $email Successfully logged in - $(Get-Date)" | Out-File $logFile -Append
            }
        }
        else {
            # throw
            Write-Output "User $firstName with Email Id: $email Already Registered  - $(Get-Date)" | Out-File $logFile -Append
            $chrmDriver.Quit()
        }
    }
    catch {
        Write-Output "Something went wrong  - $(Get-Date)" | Out-File $logFile -Append
        Write-Output "`t    $error - $(Get-Date)" | Out-File $logFile -Append
    }
    $chrmDriver.Quit()
}

function Search-Item {
    <#
    .DESCRIPTION
    It will login the user first
    If user already has an email address, it will search for the item
    The script will search for the item: Jeans only
    #>
    try {
        Write-Output "$firstName Loggin in - $(Get-Date)" | Out-File $logFile -Append

        $ErrorActionPreference = 'Continue'
        $chrmDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($chrmDriverPath)
        $chrmDriver.Manage().Window.Maximize()

        $chrmDriver.Manage().Timeouts() = [timespan]::FromSeconds

        $chrmDriver.Navigate().GoToUrl("https://demowebshop.tricentis.com/")

        $loginElement = $chrmDriver.FindElementByClassName("ico-login")
        $loginElement.Click()

        $emailElement1 = $chrmDriver.FindElementById("Email")
        $emailElement1.SendKeys("$email")

        $passwordElement1 = $chrmDriver.FindElementById("Password")
        $passwordElement1.SendKeys("$password")

        $logInButton = $chrmDriver.FindElementByCssSelector("input.button-1.login-button")
        $logInButton.Click()

        Start-Sleep -Seconds 3

        $userEmail = $chrmDriver.FindElementByClassName("account")
        $testUserEmail = $userEmail.Text
        $testUserEmail
        if ($null -ne $testUserEmail) {
            Write-Output "User with EmailId: $testUserEmail successfully logged in - $(Get-Date)" | Out-File $logFile -Append
        
            Write-Output "Searching for Item: Blue Jeans" | Out-File $logFile -Append
            Start-Sleep -s 5
        
            $searchFieldElement = $chrmDriver.FindElementById("small-searchterms")
            $searchFieldElement.SendKeys("Jeans")
            $searchFieldElement.Submit()
    
            Start-Sleep -Seconds 5

            $element = $chrmDriver.FindElementByCssSelector(".product-title>a:first-of-type")
            $check = $element.Text
            Write-Host "Check item: $check"

            if ($check -match "Blue Jeans") {
                Write-Output "$item Found - $(Get-Date)" | Out-File $logFile -Append
            }
            else {
                throw
            }
        }
    }
    catch {
        Write-Output "Blue Jeans Not Found - $error $(Get-Date)" | Out-File $logFile -Append
    }   
    $chrmDriver.Quit()
}
#Making sure the details are entered, not hardcoded the details structure.
if (($password -ne $confirmPassword) -or ($null -match $email) -or ($null -match $firstName) -or ($null -match $lastName) -or ($null -match $item)) {
    Write-Host "Please Enter details correctly" -ForegroundColor 'Red'
    Write-Output "Please Enter details correctly -$(Get-Date)" | Out-File $logFile -Append
    $ErrorActionPreference = 'Stop'
    throw
}
else {
    Register-User #Use Case 1
    Start-Sleep -s 5
    Search-Item #Use Case 2
}

