#################################################################################################################
# NOTES
# Run as powershell edit and then run green arrow.
# ===========================================================================
# Created on:   8/10/2020 
# Version:      1.0.1
# Author: MiquelES
##################################################################################################################
# AD Password module
Import-Module ActiveDirectory
$MaxPwdAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
$expiredDate = (Get-Date).addDays(-$MaxPwdAge)
#Set the number of days until you would like to begin notifing the users. -- Do Not Modify --
#Filters for all users who's password is within $date of expiration.
$ExpiredUsers = Get-ADUser -Filter {(PasswordLastSet -gt $expiredDate) -and (PasswordNeverExpires -eq $false) -and (Enabled -eq $true)} -Properties PasswordNeverExpires, PasswordLastSet, Mail | select samaccountname, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = {$_.PasswordLastSet - $ExpiredDate | select -ExpandProperty Days}} | Sort-Object PasswordLastSet
$ExpiredUsers
​
​
#end function results below
