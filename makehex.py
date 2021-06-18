import sys
import binascii
with open(sys.argv[1], "rb") as f:
  memory = f.read()
  print('\n'.join([binascii.hexlify(memory[i:i+4][::-1]).decode('utf-8') for i in range(0,len(memory),4)]))


