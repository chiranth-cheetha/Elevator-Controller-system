
import socket
import time
import os

# =====================================================
# SETTINGS
# =====================================================

GODOT_IP = "127.0.0.1"
GODOT_PORT = 5000

REQUEST_FILE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "request.txt"
)

REQUEST_DELAY = 1.0


# =====================================================
# UDP SETUP
# =====================================================

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


# =====================================================
# CHECK REQUEST FILE
# =====================================================

if not os.path.exists(REQUEST_FILE):
    print("ERROR: request.txt not found")
    print("LOOKED FOR:", REQUEST_FILE)
    sock.close()
    exit()

print("REQUEST FILE FOUND:", REQUEST_FILE)
print("")


# =====================================================
# SEND REQUESTS
# =====================================================

with open(REQUEST_FILE, "r") as file:

    for line in file:

        message = line.strip()

        if not message:
            continue

        if message.startswith("#"):
            continue

        parts = message.split()

        # Must be:
        # TYPE FLOOR DIRECTION

        if len(parts) != 3:
            print("INVALID REQUEST:", message)
            continue

        try:
            request_type = int(parts[0])
            floor = int(parts[1])
            direction = int(parts[2])
        except ValueError:
            print("INVALID REQUEST:", message)
            continue

        # TYPE
        if request_type not in (1, 2):
            print("INVALID REQUEST TYPE:", message)
            continue

        # FLOOR
        if floor < 0 or floor > 4:
            print("INVALID FLOOR:", message)
            continue

        # DIRECTION
        if direction not in (0, 1):
            print("INVALID DIRECTION:", message)
            continue

        print("PYTHON REQUEST:", message)

        sock.sendto(
            message.encode("utf-8"),
            (GODOT_IP, GODOT_PORT)
        )

        print("SENT TO GODOT:", message)
        print("")

        time.sleep(REQUEST_DELAY)


# =====================================================
# FINISHED
# =====================================================

print("ALL REQUESTS SENT")

sock.close()

