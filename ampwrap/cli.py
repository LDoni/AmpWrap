#!/usr/bin/env python3
import sys
import subprocess
from pathlib import Path

def main():
    # Help base se non ci sono argomenti
    if len(sys.argv) <= 1 or sys.argv[1] in ('-h', '--help'):
        print("""
Usage: ampwrap <workflow> [args]
    workflow: 'short' or 'long' (required)
    args:     arguments for the selected workflow

To see workflow-specific help:
    ampwrap short --help
    ampwrap long --help
""")
        sys.exit(0 if len(sys.argv) <= 1 else 1)

    # Mappa workflow agli eseguibili
    workflow = sys.argv[1]
    executables = {
        'short': 'AmpWrap_short',
        'long': 'AmpWrap_long'
    }

    # Validazione workflow
    if workflow not in executables:
        print(f"Error: Unknown workflow '{workflow}'. Choose 'short' or 'long'.")
        sys.exit(1)

    # Costruzione comando
    try:
        exe_path = Path(__file__).parent / executables[workflow]
        cmd = [str(exe_path)] + sys.argv[2:]
        
        # Esecuzione passando tutto l'help all'eseguibile originale
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()
