// SPDX-License-Identifier: Apache-2.0

'use strict';
'require form';
'require fs';
'require ui';
'require view';

function injectCSS() {
	if (document.getElementById('dae-config-css')) return;
	var el = document.createElement('style');
	el.id = 'dae-config-css';
	el.textContent = [
		'#dae-config-textarea{',
		'  white-space:pre-wrap;word-wrap:break-word;overflow-wrap:break-word;',
		'  tab-size:2;',
		'}',
	].join('');
	document.head.appendChild(el);
}

return view.extend({
	render() {
		injectCSS();

		let m, s, o;

		m = new form.Map('dae', _('Configuration'),
			_('Here you can edit dae configuration. It will be hot-reloaded automatically after apply.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;

		s = m.section(form.NamedSection, 'config', 'dae');

		o = s.option(form.TextValue, '_configuration');
		o.rows = 30;
		o.monospace = true;
		o.wrap = 'soft';

		// Add id for CSS targeting
		o.cfgvalue = function(section_id) {
			return fs.read_direct('/etc/dae/config.dae', 'text')
				.then(function(content) {
					var ta = document.getElementById('cbi-dae-config-_configuration');
					if (ta) ta.id = 'dae-config-textarea';
					return content ?? '';
				}).catch(function(e) {
					if (e.toString().includes('NotFoundError'))
						return fs.read_direct('/etc/dae/example.dae', 'text')
							.then(function(content) { return content ?? ''; })
							.catch(function() { return ''; });
					ui.addNotification(null, E('p', e.message));
					return '';
				});
		};

		o.load = function(section_id) {
			return fs.read_direct('/etc/dae/config.dae', 'text')
				.then(function(content) {
					return content ?? '';
				}).catch(function(e) {
					if (e.toString().includes('NotFoundError'))
						return fs.read_direct('/etc/dae/example.dae', 'text')
							.then(function(content) {
								return content ?? '';
							}).catch(function(e) {
								return '';
							});

					ui.addNotification(null, E('p', e.message));
					return '';
				});
		};
		o.write = function(section_id, value) {
			return fs.write('/etc/dae/config.dae', value, 384 /* 0600 */)
				.catch(function(e) {
					ui.addNotification(null, E('p', e.message));
				});
		};
		o.remove = function(section_id, value) {
			return fs.write('/etc/dae/config.dae', '')
				.catch(function(e) {
					ui.addNotification(null, E('p', e.message));
				});
		};

		return m.render();
	},

	handleSaveApply(ev, mode) {
		return this.handleSave(ev).then(function() {
			return L.resolveDefault(fs.exec_direct('/etc/init.d/dae', ['hot_reload']), null);
		});
	}
});
