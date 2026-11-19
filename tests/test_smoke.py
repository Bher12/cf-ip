# -*- coding: utf-8 -*-
import json, os, re, sys, unittest
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
class TestBaseSmoke(unittest.TestCase):
    def test_config_loads_and_sources_sane(self):
        cfg = json.load(open(os.path.join(ROOT, 'config.json'), encoding='utf-8'))
        srcs = cfg['ADDITIONAL_SOURCES']
        self.assertGreaterEqual(len(srcs), 10)
        for s in srcs:
            self.assertIn('url', s)
        self.assertFalse(any(x in s['url'] for s in srcs for x in ('s5gy','tiancheng','Domain-Asia','vps789')))
    def test_config_no_note_keys(self):
        cfg = json.load(open(os.path.join(ROOT, 'config.json'), encoding='utf-8'))
        self.assertFalse([k for k in cfg if k.startswith('_')])
    def test_ip_txt_format(self):
        lines = [l.strip() for l in open(os.path.join(ROOT, 'ip.txt'), encoding='utf-8') if l.strip()]
        self.assertGreaterEqual(len(lines), 5)
        for l in lines:
            self.assertRegex(l, r'^\d+\.\d+\.\d+\.\d+:\d+#')
    def test_main_compiles(self):
        import py_compile
        py_compile.compile(os.path.join(ROOT, 'main.py'), doraise=True)
    def test_colo_detect_imports(self):
        sys.path.insert(0, ROOT)
        import colo_detect
        self.assertTrue(hasattr(colo_detect, 'detect_colos'))
if __name__ == '__main__':
    unittest.main()
