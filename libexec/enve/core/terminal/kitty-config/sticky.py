import weakref
import subprocess

# result = subprocess.check_output(['ps','-eaf']).decode('utf-8')
from kitty.fast_data_types import cell_size_for_window
from kitty.child import (cmdline_of_process, cwd_of_process, _environ_of_process,
                         process_group_map)


def main(args):
    if len(args) > 1 and args[1] == 'save-or-rename':
        new_name = input('new session name:\n')
        return new_name
    return True


class ViewRecord:
    def __init__(self, focusd, layout,
                 host, tmux,
                 menucmd, shellcmd, cmd):
        self.focusd = focusd
        self.layout = layout
        self.host = host
        self.tmux = tmux
        self.menucmd = menucmd
        self.shellcmd = shellcmd
        self.cmd = cmd

def record_from_view(window, host=None, tmux=None, menucmd=None, shellcmd=None, cmd=None):
    tab = window.tabref()
    if not tab:
        return None

    layout_name = tab.current_layout.name
    if layout_name not in ('Tall', 'Fat'):
        return None

    mirrored = tab.current_layout.layout_opts.mirrored
    main_bias = tab.current_layout.main_bias[:]
    biased_map = tab.current_layout.biased_map.copy()

    focused = w.screen.has_focus()
    if any(x is None for x in (host, tmux, menucmd, shellcmd, cmd)):
        result = subprocess.check_output(['ps','-eaf']).decode('utf-8')

    rec = ViewRecord(focused,
                     (layout_name, mirrored, main_bias, biased_map),
                     host or '',
                     tmux or '',
                     menucmd or [],
                     shellcmd or [],
                     cmd or [])
    return rec


class ViewSession:
    def __init__(self, tab_manager, name):
        self.tab_manager_ref = weakref.ref(tab_manager)
        self.name = name
        self.winsize = None
        self._views = {}

    def replace_record(self, viewid, record):
        self._views[viewid] = record

    def ser(self):
        tm = self.tab_manager_ref.get()
        for tab_idx, t in enumerate(tm):
            for view_idx, wg in enumerate(t.groups):
                for w in wg:
                    if w.id in self._views:
                        yield tab_idx, view_idx, self._views[w.id]
                        break
                else:
                    record = record_from_view(wg.windows[0])
                    if record:
                        yield tab_idx, view_idx, record



from kittens.tui.handler import result_handler
@result_handler()
def handle_result(args, answer, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id)
    if not w:
        return False

    tab = w.tabref()
    if not tab:
        return False

    tm = tab.tab_manager_ref()
    if not tm:
        return False

    view_sessions = boss.view_sessions = getattr(boss, 'view_sessions', {})

    action = args[1]
    if action == 'record':
        session_name = getattr(tm, 'session_name', None)
        if not session_name:
            return False

        view_session = view_sessions.get(session_name, None)
        if not view_session:
            return False

        host, tmux = args[2:4]
        _curcmd = menucmd = []
        shellcmd = []
        cmd = []
        for a in args[4:]:
            if a == '---' and _curcmd is menucmd:
                _curcmd = shellcmd
            elif a == '---' and _curcmd is shellcmd:
                _curcmd = cmd
            else:
                _curcmd.append(a)

        win_width, win_height = cell_size_for_window(w.os_window_id)
        view_session.winsize = (win_width, win_height)

        rec = record_from_view(w, host, tmux, menucmd, shellcmd, cmd)
        if rec:
            view_session.replace_record(w.id, rec)

    elif action == 'save-or-rename':
        old_session_name = getattr(tm, 'session_name', None)
        new_session_name = answer
        old_session = None
        if old_session_name:
            old_session = view_sessions.get(old_session_name, None)
            if old_session:
                del view_sessions[old_session_name]
                old_session.name = new_session_name
        tm.session_name = new_session_name
        view_sessions[new_session_name] = old_session or ViewSession(tm, session_name)
        win_width, win_height = cell_size_for_window(w.os_window_id)
        view_sessions[new_session_name].winsize = (win_width, win_height)

    elif action == 'replace-os-window':
        pass
