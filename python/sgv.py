#!/usr/bin/env python3
""" SimpleGalleryViewer """
from gi.repository import Gtk
from gi.repository.GdkPixbuf import Pixbuf
from optparse import OptionParser
from pathlib import Path
import os
import subprocess as sp
import json
import gi

gi.require_version("Gtk", "3.0")

HOME = os.getenv('HOME')
CONFIG = os.path.join(HOME, '.config/sgv.json')
CACHE = os.path.join(HOME, '.cache/sgv')
if not os.path.exists(CACHE):
    os.mkdir(CACHE)

try:
    with open(CONFIG, 'r') as fp:
        config = json.load(fp)
except FileNotFoundError:
    config = {'dir': ''}

usage = 'Usage: %prog <DIR>'
parser = OptionParser(usage=usage)
opts, args = parser.parse_args()

WIDTH = 1024
HEIGHT = 600
TREE_VIEW_WIDTH = 200


def is_image(s):
    return s.split('.')[-1].lower() in ['jpeg', 'jpg', 'png', 'webp']


class Window(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_border_width(10)
        self.set_default_size(WIDTH, HEIGHT)

        if not os.path.exists(config['dir']):
            self.set_config_dir()

        Dir = config['dir']
        assert os.path.isdir(Dir)

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        body_box = Gtk.Box(spacing=1)

        self.tree_store = Gtk.TreeStore(str, Pixbuf, str)
        self.tree_view = Gtk.TreeView(model=self.tree_store)
        self.load_tree(Dir)

        self.tree_view.set_activate_on_single_click(True)
        tree_view_col = Gtk.TreeViewColumn("Gallery")
        col_cell_txt = Gtk.CellRendererText()
        col_cell_img = Gtk.CellRendererPixbuf()
        tree_view_col.pack_start(col_cell_img, False)
        tree_view_col.pack_start(col_cell_txt, True)
        tree_view_col.add_attribute(col_cell_txt, "text", 0)
        tree_view_col.add_attribute(col_cell_img, "pixbuf", 1)
        self.tree_view.append_column(tree_view_col)
        self.tree_view.connect("row-expanded", self.on_expand)
        self.tree_view.connect("row-collapsed", self.on_collapse)
        self.tree_view.connect("row-activated", self.on_activated)
        tree_scroll = Gtk.ScrolledWindow()
        tree_scroll.set_min_content_width(TREE_VIEW_WIDTH)
        tree_scroll.add(self.tree_view)

        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_max_children_per_line(8)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.flowbox.connect('child-activated', self.img_clicked)
        self.flowbox.set_homogeneous(True)
        tree = self.tree_view.get_model()
        tree_iter = tree.get_iter_first()

        try:
            path = tree.get_value(tree_iter, 2)
            self.pop_files(path)
            body_box.pack_start(tree_scroll, False, True, 0)
        except Exception:
            self.pop_files(Dir)

        gallery_scroll = Gtk.ScrolledWindow()
        gallery_scroll.add(self.flowbox)
        body_box.pack_start(gallery_scroll, True, True, 0)
        main_box.pack_start(body_box, True, True, 0)
        self.add(main_box)
        self.show_all()

    def set_config_dir(self):
        dialog = Gtk.FileChooserDialog(
            title="Please choose a folder",
            parent=self,
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL,
            Gtk.ResponseType.CANCEL,
            "Select",
            Gtk.ResponseType.OK
        )
        dialog.set_default_size(200, 200)
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            Dir = dialog.get_filename()
        dialog.destroy()

        if os.path.exists(Dir):
            config['dir'] = Dir
            with open(CONFIG, 'w') as fp:
                json.dump(config, fp, indent=2)

    def load_tree(self, path):
        tree = self.tree_view.get_model()
        while True:
            tree_iter = tree.get_iter_first()
            if not tree_iter:
                break
            tree.remove(tree_iter)
        self.pop_tree(self.tree_store, path)

    def pop_tree(self, tree, path, parent=None):
        for item in sorted(os.listdir(path)):
            full_path = os.path.join(path, item)
            if item.startswith('.'):
                continue
            if not os.path.isdir(full_path):
                continue
            icon = Gtk.IconTheme.get_default().load_icon("folder", 22, 0)
            current_iter = tree.append(parent, [item, icon, full_path])
            if any(
                os.path.isdir(os.path.join(full_path, i))
                for i in os.listdir(full_path)
            ):
                tree.append(current_iter, [None, None, None])

    def pop_files(self, full_path):
        for i in self.flowbox.get_children():
            self.flowbox.remove(i)

        images = [
            os.path.join(full_path, i)
            for i in sorted(os.listdir(full_path)) if is_image(i)
        ]
        if images:
            images = [images[0]]
        else:
            for r, d, f in os.walk(full_path, followlinks=True):
                if not d:
                    continue
                for subdir in sorted(d):
                    path = os.path.join(r, subdir)
                    for i in sorted(os.listdir(path)):
                        if is_image(i):
                            image_path = os.path.join(path, i)
                            images.append(image_path)
                            break

        for img in images:
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            image_box = Gtk.Box()
            image_box.set_halign(Gtk.Align.CENTER)
            frame = Gtk.Frame()
            frame.set_shadow_type(Gtk.ShadowType.ETCHED_IN)
            image_box.pack_start(frame, False, False, 0)

            image_cache = os.path.join(CACHE, img[1:])
            if not os.path.exists(image_cache):
                cache_path = Path(image_cache).parent
                cache_path.mkdir(parents=True, exist_ok=True)
                pixbuf = Pixbuf.new_from_file_at_scale(img, 250, 350, True)
                pixbuf.savev(image_cache, type='jpeg')
            image = Gtk.Image.new_from_file(image_cache)
            frame.add(image)
            title_box = Gtk.Box(spacing=1)
            title_box.set_halign(Gtk.Align.CENTER)
            title = Path(img).parent.name
            n = len(os.listdir(str(Path(img).parent)))
            label = Gtk.Label()
            label.set_max_width_chars(30)
            label.set_text(f'({n})\n{title}')
            label.set_line_wrap(True)
            label.set_justify(Gtk.Justification.CENTER)
            title_box.pack_start(label, False, False, 0)

            box.pack_start(image_box, False, False, 0)
            box.pack_start(title_box, False, False, 0)
            self.flowbox.add(box)

        self.show_all()

    def img_clicked(self, flowbox, child):
        try:
            box = child.get_children()[0]
            img_box = box.get_children()[0]
            frame = img_box.get_children()[0]
            img = frame.get_children()[0]
            path = str(Path(img.props.file).parent).replace(CACHE, '')
            sp.Popen(['nsxiv', '-qrs', 'w', path])
        except Exception as err:
            print(err)

    def on_activated(self, tree_view, path, column):
        tree = tree_view.get_model()
        tree_iter = tree.get_iter(path)
        new_path = tree.get_value(tree_iter, 2)
        self.pop_files(new_path)

    def on_expand(self, tree_view, tree_iter, path):
        tree = tree_view.get_model()
        new_path = tree.get_value(tree_iter, 2)
        self.pop_tree(tree, new_path, tree_iter)
        tree.remove(tree.iter_children(tree_iter))
        self.pop_files(new_path)

    def on_collapse(self, tree_view, tree_iter, path):
        tree = tree_view.get_model()
        current_iter = tree.iter_children(tree_iter)
        while current_iter:
            tree.remove(current_iter)
            current_iter = tree.iter_children(tree_iter)
        tree.append(tree_iter, [None, None, None])


if __name__ == '__main__':
    win = Window()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
