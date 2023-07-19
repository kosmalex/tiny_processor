"""
  Factorial kernel
"""

N = 5

fact = 1
while N > 0:
  fact *= N
  N -= 1

print(fact)