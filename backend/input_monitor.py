#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

import os
import sys

from shell_help_commands import print_commands, help_user_create,help_users,help_user_deletion
from shell_command_handler import user_whois, user_create, user_deletion

def display_help(args):
    try:
        if len(args) == 1:
            print_commands()
        elif len(args) == 2:
            if args[1].lower() == "user":
                help_users()
        elif len(args) == 3:
            if ((args[1].lower() == "user") and (args[2].lower()=="create")):
                help_user_create()
            elif ((args[1].lower() == "user") and (args[2].lower()=="delete")):
                help_user_deletion()
    except Exception as e:
        print(f"Invalid arguments: {e}")

def cmd_user(args):
    try:
        if len(args)==2:
            if (args[1].lower()=="delete"):
                user_deletion(args[2])
        elif len(args)== 3:
            #list
            if (args[1].lower()=="whois"):
                user_whois(args[2])
        elif len(args) == 5:
            if (args[1].lower()=="create"):
                user_create(args[2],args[3], int(args[4].strip()))
    except Exception as e:
        print(f"Command execution failed: {e}")

def monitor_user_input():
    while True:
        args = input("> ").strip().split(" ")
        if (len(args)> 0):
            if (args[0].lower()=="help"):
                display_help(args)
            elif(args[0].lower()=="user"):
                cmd_user(args) 
