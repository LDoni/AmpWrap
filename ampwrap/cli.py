#!/usr/bin/env python3

import subprocess
import sys

usage = """Usage: ampwrap [workflow] [arguments]
    command: either 'short' or 'long'
    arguments: to check argument list, use -h
    e.g., ampwrap short -h"""

# Controlla che ci siano argomenti
if len(sys.argv) <= 1:
    print(usage)
    sys.exit(1)

# Mappa i workflow agli ambienti Conda
workflow_envs = {
    "short": "AmpWraP-short",
    "long": "AmpWraP-long"
}

workflows = {
     "short": "AmpWrap_short",
     "long": "AmpWrap_long"}

workflow = sys.argv[1]  # Primo argomento: workflow
args = sys.argv[2:]  # Argomenti successivi

# Verifica se il workflow è valido
if workflow not in workflows:
    print(f"Error: Invalid command '{workflow}'. Choose 'short' or 'long'.")
    sys.exit(1)

env_name = workflow_envs[workflow]  # Ambiente Conda corrispondente

# Costruisce il comando per eseguire il workflow nel suo ambiente Conda
command = f"conda run -n {env_name} ./{workflows[workflow]} " + " ".join(args)

# Esegue il comando
try:
    subprocess.run(command, shell=True, check=True)
except subprocess.CalledProcessError:
    print(f"Error: Execution of '{workflow}' in Conda environment '{env_name}' failed.")
    sys.exit(1)
