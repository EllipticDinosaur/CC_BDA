import os
import sys


def restart_program():
    """Restart the current program."""
    try:
        print("Restarting program...")
        python_executable = sys.executable
        # Ensure compatibility with python or python3
        python_command = 'python3' if 'python3' in python_executable else 'python'
        os.execv(python_executable, [python_command] + sys.argv)
    except Exception as e:
        print(f"Failed to restart the program: {e}")


def shutdown_program():
    """Shutdown the current program."""
    print("Shutting down program...")
    sys.exit(0)


def monitor_user_input():
    """Monitor user input for restart and shutdown commands."""
    print("Options: \n1. Type 'restart' to restart the program\n2. Type 'shutdown' to exit the program")
    while True:
        user_input = input("> ").strip().lower()
        if user_input == 'restart':
            restart_program()
        elif user_input == 'shutdown':
            shutdown_program()
