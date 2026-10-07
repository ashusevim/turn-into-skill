#!/usr/bin/env python3
"""clean-transcript.py <input.vtt> — VTT (incl. rolling-caption auto-subs) to clean text.
Collapses consecutive repeated phrases, strips tags/timestamps. Prints to stdout."""

import re, sys


def main(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    chunks = []
    for block in raw.split("\n\n"):
        words = []
        for line in block.strip().split("\n"):
            s = line.strip()
            if (
                not s
                or s[0].isdigit()
                or "-->" in s
                or s.startswith(("WEBVTT", "Kind:", "Language:"))
            ):
                continue
            words.append(s)
        text = re.sub(r"<[^>]+>", "", " ".join(words)).strip()
        if text:
            chunks.append(text)
    out = []
    for t in chunks:
        if not out or out[-1] != t:
            out.append(t)
    txt = " ".join(out)
    prev = None
    while prev != txt:  # rolling captions repeat each phrase 2-3x
        prev = txt
        txt = re.sub(r"(.{15,}?)\1{1,2}", r"\1", txt)
    print(re.sub(r"\s+", " ", txt).strip())


if __name__ == "__main__":
    main(sys.argv[1])
