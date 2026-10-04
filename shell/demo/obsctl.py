#!/usr/bin/env python3
"""Minimal obs-websocket v5 client (standard library only).

    obsctl.py <RequestType> ['{"json": "request data"}']    one request, prints the reply
    obsctl.py wait                                          block until OBS answers

Also importable: `from obsctl import Obs`. The password is read from OBS's own
obs-websocket config, so nothing has to be typed or stored a second time.
"""
import base64, hashlib, json, os, socket, struct, sys, time

CONF = os.path.expanduser("~/.config/obs-studio/plugin_config/obs-websocket/config.json")


class ObsError(RuntimeError):
    pass


class Obs:
    def __init__(self, host="127.0.0.1", port=None, password=None, timeout=10):
        conf = json.load(open(CONF)) if os.path.exists(CONF) else {}
        port = port or conf.get("server_port", 4455)
        password = password if password is not None else conf.get("server_password", "")
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.buf = b""
        self.n = 0
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.sendall((
            f"GET / HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        while b"\r\n\r\n" not in self.buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ObsError("OBS closed the connection during the handshake")
            self.buf += chunk
        head, self.buf = self.buf.split(b"\r\n\r\n", 1)
        if b" 101 " not in head.split(b"\r\n", 1)[0]:
            raise ObsError("not a websocket server: " + head.decode(errors="replace"))
        hello = self._recv()
        ident = {"rpcVersion": 1, "eventSubscriptions": 0}
        auth = hello["d"].get("authentication")
        if auth:
            secret = base64.b64encode(hashlib.sha256((password + auth["salt"]).encode()).digest()).decode()
            ident["authentication"] = base64.b64encode(
                hashlib.sha256((secret + auth["challenge"]).encode()).digest()).decode()
        self._send({"op": 1, "d": ident})
        if self._recv()["op"] != 2:
            raise ObsError("OBS rejected the identification")

    def _send(self, obj):
        data = json.dumps(obj).encode()
        n = len(data)
        head = b"\x81" + (bytes([0x80 | n]) if n < 126 else
                          bytes([0x80 | 126]) + struct.pack(">H", n) if n < 65536 else
                          bytes([0x80 | 127]) + struct.pack(">Q", n))
        mask = os.urandom(4)
        self.sock.sendall(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def _read(self, n):
        while len(self.buf) < n:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ObsError("OBS closed the connection")
            self.buf += chunk
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def _recv(self):
        text = b""
        while True:
            b0, b1 = self._read(2)
            n = b1 & 0x7F
            if n == 126:
                n = struct.unpack(">H", self._read(2))[0]
            elif n == 127:
                n = struct.unpack(">Q", self._read(8))[0]
            payload = self._read(n)
            op = b0 & 0x0F
            if op == 8:
                code = struct.unpack(">H", payload[:2])[0] if len(payload) >= 2 else 0
                raise ObsError(f"OBS closed the connection ({code} {payload[2:].decode(errors='replace')})")
            if op == 9:      # ping: OBS does not require the pong for a short-lived client
                continue
            text += payload
            if b0 & 0x80:
                return json.loads(text)

    def call(self, request, data=None, check=True):
        self.n += 1
        rid = str(self.n)
        self._send({"op": 6, "d": {"requestType": request, "requestId": rid, "requestData": data or {}}})
        while True:
            msg = self._recv()
            if msg["op"] == 7 and msg["d"]["requestId"] == rid:
                status = msg["d"]["requestStatus"]
                if check and not status["result"]:
                    raise ObsError(f"{request}: {status.get('code')} {status.get('comment', '')}")
                return msg["d"].get("responseData") or {}

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass


def wait(seconds=40):
    """Connect once OBS is up and its frontend has finished loading."""
    end = time.time() + seconds
    while True:
        try:
            obs = Obs()
            obs.call("GetVersion")
            return obs
        except (OSError, ObsError):
            if time.time() > end:
                raise
            time.sleep(0.5)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    if sys.argv[1] == "wait":
        wait().close()
        sys.exit(0)
    try:
        reply = Obs().call(sys.argv[1], json.loads(sys.argv[2]) if len(sys.argv) > 2 else None)
    except (OSError, ObsError) as e:
        sys.exit(f"obsctl: {e}")
    print(json.dumps(reply, indent=2))
