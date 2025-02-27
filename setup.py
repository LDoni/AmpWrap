from setuptools import setup, find_packages

setup(
    name="ampwrap",
    version="0.1",
    packages=find_packages(),
    entry_points={
        "console_scripts": [
            "ampwrap=ampwrap.cli:main",
            "AmpWrap_short=ampwrap.AmpWrap_short",
            "AmpWrap_long=ampwrap.AmpWrap_long",
        ],
    },
    package_data={
        "ampwrap": ["scripts/*", "snakefile.short", "snakefile.long", "AmpWraP-all.yml"],
    },
    include_package_data=True,
    zip_safe=False,
)
