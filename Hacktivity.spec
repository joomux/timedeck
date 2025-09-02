# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['hacktivity_menubar.py'],
    pathex=[],
    binaries=[],
    datas=[('*.applescript', '.')],
    hiddenimports=['rumps', 'Foundation', 'AppKit'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='Hacktivity',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['hacktivity.icns'],
)
app = BUNDLE(
    exe,
    name='Hacktivity.app',
    icon='hacktivity.icns',
    bundle_identifier=None,
)
