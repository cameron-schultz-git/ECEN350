import sys

SIZE = 50000

A = [i for i in range(SIZE)]
B = [50000 - i for i in range(SIZE)]
C = [0] * SIZE

for i in range(SIZE):
    C[i] = sum(B[:A[i] + 1])

checksum = sum(C)

print(checksum)

if checksum != 41667916675000:
    print("Error: Computed checksum does not match 41667916675000.", file=sys.stderr)
    sys.exit(1)
