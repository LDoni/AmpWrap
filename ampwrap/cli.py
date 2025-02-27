import os
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

# Mappa i workflow ai loro script
workflows = {
    "short": "AmpWrap_short",
    "long": "AmpWrap_long"
}

workflow = sys.argv[1]  # Primo argomento: workflow
args = sys.argv[2:]  # Argomenti successivi
print("AAAAAAAAAAAAAAAAAA")

# Verifica se il workflow è valido
if workflow not in workflows:
    print(f"❌ Errore: '{workflow}' non è un comando valido. Usa 'short' o 'long'.")
    sys.exit(1)

# Percorso dello script
script_dir = os.path.dirname(os.path.abspath(__file__))
script_path = os.path.join(script_dir, workflows[workflow])

if not os.path.exists(script_path):
    print(f"❌ Errore: Script '{script_path}' non trovato!")
    sys.exit(1)

# Esegue il workflow direttamente nell'ambiente attivo
#command = f"{script_path} " + " ".join(args)
command = [workflows[workflow]] + args

try:
    subprocess.run(command, shell=True, check=True)
except subprocess.CalledProcessError:
    print(f"❌ Errore: Esecuzione di '{workflow}' fallita.")
    sys.exit(1)
