#!/usr/bin/env python3
"""
Setup script for Hacktivity
"""

from setuptools import setup, find_packages
import os

# Read the README file
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

# Read version
version = "1.0.0"
if os.path.exists("VERSION"):
    with open("VERSION", "r") as f:
        version = f.read().strip()

setup(
    name="hacktivity",
    version=version,
    author="Jeremy Roberts",
    author_email="jeremy@example.com",  # Update with your email
    description="Activity tracking menu bar app for macOS",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/joomux/timedeck",  # Update with your repo
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Operating System :: MacOS",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Office/Business :: Scheduling",
        "Topic :: Utilities",
    ],
    python_requires=">=3.8",
    install_requires=[
        "rumps>=0.4.0",
    ],
    include_package_data=True,
    package_data={
        "hacktivity": ["*.applescript"],
    },
    entry_points={
        "console_scripts": [
            "hacktivity=hacktivity.menubar:main",
        ],
    },
    data_files=[
        ("share/hacktivity", [
            "NewActivity.applescript",
            "EndActivity.applescript", 
            "EndDay.applescript",
            "GenerateReport.applescript",
            "StartFresh.applescript",
        ])
    ],
)
