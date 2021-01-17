
# Securestring is encrypted by the user account.  The same user account is only able to decrypt it.  Kerberos keys are used under the hood.
# See details of storing a password as a secure string here:
# https://social.technet.microsoft.com/wiki/contents/articles/30245.fim-2010-protect-passwords-in-configuration-files.aspx
#
# How to encrypt password:
$EncryptedPassword=Read-Host -Prompt "Enter password" -AsSecureString | ConvertFrom-SecureString
# - OR -
$secureString = ConvertTo-SecureString -AsPlainText -Force -String $pwd
$EncryptedPassword = ConvertFrom-SecureString $secureString

# How to decrypt and display password in plaintext:
# $EncryptedPassword should look somthing like ="01000000d08c9ddf0115d1118c7a00c04fc297eb010000005e4f96302fcbf940 ... 472f2d7b20f806bc288d773f9ea7c914d0813b47b7445bbed6af651f84"
$SecurePassword = ConvertTo-SecureString $EncryptedPassword
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$PlaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$PlaintextPassword
