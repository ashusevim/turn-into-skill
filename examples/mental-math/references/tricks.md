# The three tricks

## Trick A — multiply by 11

Two digits `ab` × 11 → `a | a+b | b`.
- 43 × 11 → 4 | 7 | 3 → **473**
- 54 × 11 → 5 | 9 | 4 → **594**
- Sum ≥10: write units, carry 1 left. 68 × 11 → 6 | 14 | 8 → carry → **748**

Three digits `abc` × 11 → `a | a+b | b+c | c`, carrying left as needed.
- 352 × 11 → 3 | 8 | 7 | 2 → **3872**
- 574 × 11 → 5 | 12 | 11 | 4 → carry chain → **6314**

## Trick B — both numbers end in 5 (e.g. squares)

`a5 × a5` → `a×(a+1)` then append `25`.
- 75 × 75 → 7×8=56 → **5625**
- Practice: 95 × 95 → 9×10=90 → **9025**

## Trick C — same first digit, last digits sum to 10

`ab × ac` with b+c=10 → `a×(a+1)` then append `b×c` (always two digits, pad with 0).
- 44 × 46 → 4×5=20, 4×6=24 → **2024**
- Practice: 89 × 81 → 8×9=72, 9×1=09 → **7209**

Note: Trick B is Trick C with b=c=5 (5×5=25). Learn C, get B free.

## Drill set (answers in tricks, verify after)

43×11, 68×11, 574×11, 75², 95², 44×46, 89×81
