

def main(args):
    pass

from kitty.layout.interface import create_layout_object_for, all_layouts, evict_cached_layouts

def set_layout(tab, name, layout_opts=''):
    tab._last_used_layout = tab._current_layout_name
    new_layout = create_layout_object_for(name, tab.os_window_id, tab.id, layout_opts)
    new_layout.main_bias = tab.current_layout.main_bias[:]
    new_layout.biased_map = tab.current_layout.biased_map.copy()
    tab.current_layout = new_layout
    tab._current_layout_name = name
    tab.mark_tab_bar_dirty()
    tab.relayout()


from kittens.tui.handler import result_handler
@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id)
    if not w:
        return False

    tab = w.tabref()
    if not tab:
        return False

    action = args[1]
    layout = tab.current_layout
    group_id = tab.windows.group_idx_for_window(w)

    if action == 'next_layout':
        mirrored = getattr(layout.layout_opts, 'mirrored', True)
        opts = (
            'tall:mirrored=false' if layout.name != 'tall' and mirrored else
            'tall:mirrored=true' if layout.name == 'tall' and not mirrored else
            'fat:mirrored=false' if layout.name == 'tall' and mirrored else
            'fat:mirrored=true'
        )
        set_layout(tab, opts, opts.split(':')[1])
        return True
    elif action == 'larger' and layout.name in ('fat', 'tall'):
        increment_as_percent = 0.05
    elif action == 'smaller' and layout.name in ('fat', 'tall'):
        increment_as_percent = -0.05
    else:
        return False

    if group_id < layout.num_full_size_windows:
        is_horizontal = layout.main_is_horizontal
    else:
        is_horizontal = not layout.main_is_horizontal
    layout.modify_size_of_window(tab.windows, w.id, increment_as_percent, is_horizontal)
    tab.relayout()
