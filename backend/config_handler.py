import os
import json
import requests


def load_config(file_path="config.cfg", github_url=None):
    """
    Loads a configuration file. If the file does not exist, downloads it from GitHub.

    Args:
        file_path (str): Path to the configuration file.
        github_url (str): URL to download the configuration file if it doesn't exist.

    Returns:
        dict: The loaded configuration.
    """
    if not os.path.exists(file_path):
        if not github_url:
            raise FileNotFoundError(f"{file_path} does not exist, and no GitHub URL is provided.")
        print("Config file not found. Downloading from GitHub...")
        try:
            response = requests.get(github_url)
            response.raise_for_status()
            with open(file_path, "w") as file:
                file.write(response.text)
            print("Config file downloaded successfully.")
        except Exception as e:
            raise RuntimeError(f"Error downloading config file: {e}")

    print("Config file found. Loading...")
    with open(file_path, "r") as file:
        content = file.read()

    # Remove comments starting with #
    content = "\n".join(line.split("#")[0].strip() for line in content.splitlines() if line.split("#")[0].strip())

    try:
        config = json.loads(content)
        print("Config loaded successfully.")
        return config
    except json.JSONDecodeError as e:
        raise ValueError(f"Error parsing JSON: {e}")
