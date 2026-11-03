# Browser Data Extractor

A simple Windows script that helps deploy **HackBrowserData** for authorized security research and digital forensics.

> ⚠️ **Authorized use only.**  
> Use this only on systems and data you own or have explicit permission to access.

---

## About

This repository contains a Windows batch script that automates the use of **HackBrowserData**, a tool created by **moonD4rk**.

**HackBrowserData** is the original tool. All credit for the browser data extraction functionality belongs to its author and contributors.

- Original project: https://github.com/moonD4rk/HackBrowserData
- Original author: **moonD4rk**
- Original license: **MIT License** — Copyright (c) 2020 moonD4rk

This repository is not affiliated with or endorsed by the original author.

---

## What It Does

The script:

1. Prepares the tool for use.
2. Runs the extraction.
3. Saves the results in a `result` folder.
4. Cleans up temporary files afterward.
5. Restores any temporary system changes it made.

It is intended to make deployment easier, not to replace the original tool.

---

## Requirements

- Windows 10 or Windows 11
- Administrator privileges
- Internet access

---

## Usage

1. Download or clone this repository.
2. Right-click `deployer.bat`.
3. Select **Run as administrator**.
4. Follow the on-screen prompts.
5. Results are saved in the `result` folder.

---

## Output

Collected data is saved to:

```text
result/
