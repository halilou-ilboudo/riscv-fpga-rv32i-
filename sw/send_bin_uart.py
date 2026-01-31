import serial, time, os

PORT="/dev/ttyUSB1"      # adapte USB0/USB1
BAUD=115200
BIN ="Téléchargements/neorv32_exe.bin"

data=open(BIN,"rb").read()

# PAD pour que la taille soit multiple de 4
pad = (-len(data)) % 4
if pad:
    data += b"\x00" * pad

# Terminator
data += b"\xFF\xFF\xFF\xFF"

ser=serial.Serial(PORT, BAUD, timeout=1)
time.sleep(0.2)
ser.reset_input_buffer()
ser.reset_output_buffer()
ser.write(data)
ser.flush()
time.sleep(0.1)
ser.close()

print("Sent", len(data), "bytes incl terminator. pad =", pad)

