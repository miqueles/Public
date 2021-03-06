#################################################################################################################
# 
#NOTES
# ===========================================================================
# Created on:   1/04/2020 
# Version:      1.0.1
#
##################################################################################################################
# SMTP information
$smtpServer="smtp host"
$expireindays = 7
$from = "IT Ops <email>"
$logging = "Enabled" # Set to Disabled to Disable Logging
$logFile = "C:\Automation\PasswordExpiry\passwordnotification.csv" # ie. c:\mylog.csv
$testing = "Enabled" # Set to Disabled to Email Users
$testRecipient = "email"
$date = Get-Date -format ddMMyyyy
#
###################################################################################################################

# Logging Settings
if (($logging) -eq "Enabled")
{
    # Test Log File Path
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True")
    {
        # Create CSV File and Headers
        New-Item $logfile -ItemType File
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn"
    }
} # End Logging Check

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
Import-Module ActiveDirectory
$users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users)
{
    $Name = (Get-ADUser $user | foreach { $_.Name})
    $emailaddress = $user.emailaddress
    $passwordSetDate = (get-aduser $user -properties * | foreach { $_.PasswordLastSet })
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null)
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
  
    $expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
        
    # Set Greeting based on Number of Days to Expiry.

    # Check Number of Days to Expiry
    $messageDays = $daystoexpire

    if (($messageDays) -ge "1")
    {
        $messageDays = "in " + "$daystoexpire" + " days"
    }
    else
    {
        $messageDays = "today."
    }

    # Email Subject Set Here
    $subject="Your password will expire $messageDays"
  
    # Email Body Set Here, Note You can use HTML, including Images.
    $body ="
    Dear $name,
    <p> Your password will expire on $ExpiresOn.<br>
    <p>To change your password on a windows domain computer, follow the method below: <br>
    <p>a.	If you are not in the office, logon and connect to VPN.(Only when you are not in the office!)  <br/>
    b.	Log onto your computer as usual and make sure you are connected to the internet. <br/>
    c.	Press Ctrl-Alt-Del and click on ""Change Password"". <br/>
    d.	Fill in your old password and set a new password.  See the password requirements below. <br/>
    e.	Press OK to return to your desktop. <br>
    <p>The new password must meet the minimum requirements set forth in our corporate policies including: <br>
    
    1.	It must be at least 8 characters long. <br/>
    2.	It must contain at least one character from 3 of the 4 following groups of characters: <br/>
    a.  Uppercase letters (A-Z) <br/>
    b.  Lowercase letters (a-z) <br/>
    c.  Numbers (0-9) <br/>
    d.  Symbols (!@#$%^&*...) <br/>
    3.	It cannot match any of your past 24 passwords. <br/>
    4.	It cannot contain characters which match 3 or more consecutive characters of your username. <br/>
    5.	You cannot change your password more often than once in a 24 hour period. <br>

    <p>For other users with Mac, Linux or a non people-print domain computer use this method: <br>
    <p>a.	Go to https://sts.printdeal.com/adfs/portal/updatepassword  <br/>
    b.	Use firstname.lastname@people-print.com as your username. <br/>
    c.	The above password requirements also applies to this.  <br>

    <p> If you have any questions please contact our Support team at slack or call us at 0888855488 <br>

    <p><br>Thanks!, Dankjewel!, <br>
    </P>ITops
    </P>systeembeheer@drukwerkdeal.nl"

   
    # If Testing Is Enabled - Email Administrator
    if (($testing) -eq "Enabled")
    {
        $emailaddress = $testRecipient
    } # End Testing

    # If a user has no email address listed
    if (($emailaddress) -eq $null)
    {
        $emailaddress = $testRecipient    
    }# End No Valid Email

    # Send Email Message
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
    {
         # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled")
        {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson" 
        }
        # Send Email Message
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High  

    } # End Send Message
    
} # End User Processing



# End
