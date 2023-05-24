
def main(args):
    pass

import codecs
import os
import signal

from kittens.tui.handler import result_handler
@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    signame, keyb = args[1:]
    w = boss.window_id_map.get(target_window_id)
    if w:
        fcmd = w.child.foreground_cmdline
        if 'tmux' in fcmd or 'ssh' in fcmd:
            data = codecs.escape_decode(bytes(keyb, "utf-8"))[0]
            w.write_to_child(data)
            return
        pgrp = os.tcgetpgrp(w.child.child_fd)
        sig = getattr(signal, signame)
        os.killpg(pgrp, sig)
