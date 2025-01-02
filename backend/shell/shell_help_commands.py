#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

def help_users():
    print("user create <username> <password> <isadmin> # username (string), password (string), is administrator (integer) 0 for default and 1 for administrator")
    print("user delete <username> # username (string)")
    print("user timeout <username> <unixTimestamp>")
    print("user setpassword <username> <new password>")
    print("user whois <username>")
    print("user list <admins/default/slaves>")
    print("user reverse ownerid <ownerid>")

def help_user_create():
     print("    #username field: set the target username you wish to create\nUsername expecting a string value")
     print("    #password field: set the password for the user you wish to create\nPassword expecting a string value")
     print("    #isadmin field: set the admin value for the user you wish to create\nIsadmin expecting an integer value (0 is default user and 1 is admin)")
     print("        Example of administrator user:\nuser create testusername testpassword 1")

def help_user_deletion():
    print("     #username field: set the target username you wish to delete\nUsername expecting a string value")
    print("         Example of account deletion:\nuser delete testusername")

def print_commands():
    print("Help #Displays help for commands")
    print("User #Create/delete/timeout/change password of a user")
