#!/usr/bin/env python3
"""Stand-in for the greetd socket, so the real login screen can run in a window.

Speaks just enough of the greetd IPC protocol for noctalia-greeter to go through
its normal flow: ask for a password, accept whatever is typed, "start" the session.
Nothing is authenticated and nothing is started; this only exists for owdemo.

    fake-greetd.py <socket path>
"""
import json, os, socket, struct, sys


def read(conn):
    head = conn.recv(4, socket.MSG_WAITALL)
    if len(head) < 4:
        return None
    return json.loads(conn.recv(struct.unpack("=I", head)[0], socket.MSG_WAITALL))


def send(conn, obj):
    data = json.dumps(obj).encode()
    conn.sendall(struct.pack("=I", len(data)) + data)


def main():
    path = sys.argv[1]
    if os.path.exists(path):
        os.unlink(path)
    srv = socket.socket(socket.AF_UNIX)
    srv.bind(path)
    os.chmod(path, 0o600)
    srv.listen(4)
    while True:
        conn, _ = srv.accept()
        asked = False
        while True:
            try:
                msg = read(conn)
            except (OSError, ValueError):
                break
            if msg is None:
                break
            kind = msg.get("type")
            if kind == "create_session":
                asked = True
                send(conn, {"type": "auth_message", "auth_message_type": "secret", "auth_message": "Password:"})
            elif kind == "post_auth_message_response" and asked:
                asked = False
                send(conn, {"type": "success"})
            else:      # start_session, cancel_session
                send(conn, {"type": "success"})
        conn.close()


if __name__ == "__main__":
    main()
