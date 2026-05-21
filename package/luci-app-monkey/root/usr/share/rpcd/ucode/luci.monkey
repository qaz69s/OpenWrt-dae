#!/usr/bin/ucode

'use strict';

import { access, popen, readfile, writefile } from 'fs';
import { cursor } from 'uci';

const paths = {
	app_log_path:   '/var/log/monkey/app.log',
	core_log_path:  '/var/log/monkey/core.log',
	run_profile_path: '/etc/monkey/run/config.yaml',
	mixin_yaml:     '/etc/monkey/mixin.yaml',
};

const methods = {
	get_paths: {
		call: function() {
			return paths;
		}
	},
	version: {
		call: function() {
			let app = '';
			if (system('command -v apk') == 0) {
				let p = popen(`apk list -I luci-app-monkey | cut -d ' ' -f 1 | cut -d '-' -f 4`);
				if (p) { app = trim(p.read('all')); p.close(); }
			}
			let core = '';
			let p = popen('/usr/bin/monkey version 2>/dev/null | head -1');
			if (p) { core = trim(p.read('all')); p.close(); }
			return { app: app, core: core };
		}
	},
	getFileContent: {
		args: { path: 'path' },
		call: function(req) {
			let p = req.args?.path;
			if (!p || !access(p, 'r')) return { content: '' };
			return { content: readfile(p) || '' };
		}
	},
	writeFileContent: {
		args: { path: 'path', content: 'content' },
		call: function(req) {
			let p = req.args?.path;
			let c = req.args?.content;
			if (!p || c == null) return { success: false };
			writefile(p, c);
			return { success: true };
		}
	},
	getAllLogs: {
		call: function() {
			return {
				app: access(paths.app_log_path, 'r') ? (readfile(paths.app_log_path) || '') : '',
				core: access(paths.core_log_path, 'r') ? (readfile(paths.core_log_path) || '') : '',
			};
		}
	},
	clearAllLogs: {
		call: function() {
			if (access(paths.app_log_path, 'r')) writefile(paths.app_log_path, '');
			if (access(paths.core_log_path, 'r')) writefile(paths.core_log_path, '');
			return { success: true };
		}
	},
	profile: {
		call: function() {
			let result = { external_controller: '', secret: '' };
			let configPath = paths.run_profile_path;
			if (!access(configPath, 'r')) return result;

			let content = readfile(configPath) || '';
			let lines = split(content, '\n');
			let api_block = false;
			for (let line in lines) {
				let l = trim(lines[line]);
				if (l == 'api:') { api_block = true; continue; }
				if (api_block) {
					if (l == '' || match(l, '^[a-z]') != null) { api_block = false; continue; }
					let m = match(l, '^([a-zA-Z0-9_-]+):\\s*(.*)');
					if (m != null) {
						let key = trim(m[1]);
						let val = trim(m[2]);
						if (key == 'external-controller') result.external_controller = val;
						if (key == 'secret') result.secret = val;
					}
				}
			}
			// fallback default
			if (result.external_controller == '') {
				result.external_controller = '[::]:9090';
			}
			return result;
		}
	}
};

return { 'luci.monkey': methods };
