#!/usr/bin/env python3
"""Generate a quiet ambient bed for the DRAM series.

Usage: python make_audio.py out.wav seconds [seed]
"""

import sys
import wave
import numpy as np


def main():
    out = sys.argv[1]
    seconds = float(sys.argv[2])
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    sr = 44100
    n = int(seconds * sr)
    t = np.arange(n) / sr
    rng = np.random.default_rng(seed)

    # slow-moving minor drone (A1, E2, A2, C3, E3)
    freqs = [55.0, 82.41, 110.0, 130.81, 164.81]
    amps = [0.42, 0.26, 0.20, 0.12, 0.08]
    left = np.zeros(n)
    right = np.zeros(n)
    for i, (f, a) in enumerate(zip(freqs, amps)):
        lfo = 0.75 + 0.25 * np.sin(2 * np.pi * (0.021 + 0.007 * i) * t + i * 1.7)
        ph = rng.uniform(0, 2 * np.pi)
        detune = 0.0015 * f
        left += a * lfo * np.sin(2 * np.pi * f * t + ph)
        right += a * lfo * np.sin(2 * np.pi * (f + detune) * t + ph + 0.3)

    # air: heavily smoothed noise
    noise = rng.standard_normal(n)
    kernel = np.ones(2400) / 2400.0
    air = np.convolve(noise, kernel, mode="same")
    air_l = air * 0.55
    air_r = np.roll(air, 900) * 0.55

    # gentle high shimmer, very low level
    shim = 0.010 * np.sin(2 * np.pi * 329.63 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.05 * t))
    left += air_l + shim
    right += air_r + shim * 0.8

    # global envelope: fade in/out
    env = np.ones(n)
    fade = int(2.2 * sr)
    env[:fade] = np.linspace(0, 1, fade) ** 2
    env[-fade:] = np.linspace(1, 0, fade) ** 2
    # slow breathing
    env *= 0.82 + 0.18 * np.sin(2 * np.pi * 0.045 * t - 1.0)

    left *= env
    right *= env

    # normalize to about -27 dBFS RMS, peak below -12 dBFS
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)))
    target_peak = 10 ** (-12 / 20.0)
    left = left / peak * target_peak
    right = right / peak * target_peak

    stereo = np.stack([left, right], axis=1)
    pcm = (np.clip(stereo, -1, 1) * 32767.0).astype("<i2")

    with wave.open(out, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(pcm.tobytes())
    print("wrote", out, f"{seconds}s")


if __name__ == "__main__":
    main()
