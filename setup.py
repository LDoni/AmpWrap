from setuptools import setup, find_packages

setup(
    name="ampwrap",
    version="0.1",
    packages=find_packages(),
    install_requires=[],
    entry_points={
        "console_scripts": [
            "ampwrap=ampwrap.cli:main",  # Esegue ampwrap/cli.py come CLI
        ],
    },
)
