"""Fetch the pinned CC0 model before opening/building the Godot project."""
from pathlib import Path
import hashlib
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / 'godot/assets/spectral/spectral.glb'
URL = 'https://raw.githubusercontent.com/JaronKBragg7337/spectral-gt-rs/34499c501908818a2b08e589a7aecf963343cee7/spectral_gt_rs_game_ready.glb'
SHA256 = 'e7b7f0d9de0c3bc3897c8134b1ceae5631b1da2690d336df18c3ea82e7238c73'

def main():
    if TARGET.exists() and hashlib.sha256(TARGET.read_bytes()).hexdigest() == SHA256:
        print('Pinned CC0 Spectral model already verified')
        return
    with urllib.request.urlopen(URL, timeout=90) as response:
        data = response.read()
    if data[:4] != b'glTF' or hashlib.sha256(data).hexdigest() != SHA256:
        raise RuntimeError('Model identity check failed; refusing unverified content')
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    temporary = TARGET.with_suffix('.download')
    temporary.write_bytes(data)
    temporary.replace(TARGET)
    print('Downloaded and verified CC0 Spectral GT RS:', len(data), 'bytes')

if __name__ == '__main__':
    main()
