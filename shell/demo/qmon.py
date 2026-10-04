#!/usr/bin/env python3
"""Talk to a QEMU human monitor socket (used by owdemo for the boot recording).

    qmon.py <sock> key <name>                 press a key (QEMU names: down, up, ret, x, ...)
    qmon.py <sock> lum                        print the guest screen's mean brightness, 0..1
    qmon.py <sock> wait <above|below> <level> <seconds>   poll until the brightness crosses level
    qmon.py <sock> cmd <monitor command...>   anything else (quit, screendump <file>, ...)
"""
import os, socket, sys, time


def hmp(sock_path, command):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(10)
    s.connect(sock_path)
    buf = b""
    while not buf.endswith(b"(qemu) "):
        buf += s.recv(4096)
    s.sendall(command.encode() + b"\n")
    buf = b""
    try:
        while not buf.endswith(b"(qemu) "):
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
    except (socket.timeout, ConnectionResetError):
        pass
    s.close()
    return buf.decode(errors="replace")


def lum(sock_path):
    """Mean brightness of the guest display, sampled sparsely from a PPM screendump."""
    shot = sock_path + ".ppm"
    hmp(sock_path, "screendump " + shot)
    try:
        data = open(shot, "rb").read()
    except OSError:
        return 0.0
    finally:
        try:
            os.unlink(shot)
        except OSError:
            pass
    # P6\n<w> <h>\n255\n<rgb...>
    head_end = 0
    for _ in range(3):
        head_end = data.index(b"\n", head_end) + 1
    body = data[head_end::4099]
    return sum(body) / (255.0 * max(1, len(body)))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    sock, verb, rest = sys.argv[1], sys.argv[2], sys.argv[3:]
    if verb == "key":
        hmp(sock, "sendkey " + rest[0])
    elif verb == "lum":
        print(f"{lum(sock):.4f}")
    elif verb == "wait":
        above, level, end = rest[0] == "above", float(rest[1]), time.time() + float(rest[2])
        while time.time() < end:
            v = lum(sock)
            if (v > level) == above:
                return
            time.sleep(0.15)
        sys.exit(1)
    elif verb == "cmd":
        print(hmp(sock, " ".join(rest)), end="")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
