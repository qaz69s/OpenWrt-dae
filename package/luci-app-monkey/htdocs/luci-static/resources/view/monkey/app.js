'use strict';
'require view';
'require form';
'require poll';
'require rpc';
'require fs';
'require uci';
'require tools.monkey as monkey';

var callServiceList = rpc.declare({
    object: 'service', method: 'list',
    params: ['name'], expect: { '': {} }
});

function getServiceStatus() {
    return L.resolveDefault(callServiceList('monkey'), {}).then(function (res) {
        var isRunning = false;
        try {
            var inst = res['monkey']['instances'];
            for (var k in inst) {
                if (inst[k] && inst[k].running) { isRunning = true; break; }
            }
        } catch (e) {}
        return isRunning;
    });
}

function renderStatus(isRunning) {
    var color = isRunning ? 'green' : 'red';
    var text = isRunning ? _('Monkey Running') : _('Monkey Not Running');
    return String.format('<em><span style="color:%s"><strong>%s</strong></span></em>', color, text);
}

return view.extend({
    load: function () {
        return uci.load('monkey');
    },

    render: function (data) {
        var m, s, o;

        m = new form.Map('monkey', _('Status'), 'Monkey');

        /* ── 状态栏 ── */
        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.render = function () {
            poll.add(function () {
                return L.resolveDefault(getServiceStatus()).then(function (res) {
                    var view = document.getElementById('service_status');
                    if (view) view.innerHTML = renderStatus(res);
                });
            });
            return E('div', { 'class': 'cbi-section', id: 'status_bar' }, [
                E('p', { id: 'service_status' }, _('Collecting data…'))
            ]);
        };

        /* ── 基本设置 ── */
        s = m.section(form.NamedSection, 'config', 'config', _('Basic Settings'));
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Flag, 'enabled', _('Enable'));
        o.default = '0';
        o.rmempty = false;

        /* ── 面板按钮 ── */
        o = s.option(form.Button, 'open_dashboard', _('Dashboard'));
        o.inputtitle = _('Open Dashboard');
        o.inputstyle = 'action';
        o.onclick = function () {
            return monkey.openDashboard().catch(function (e) {
                alert(_('Dashboard not configured: ') + String(e));
            });
        };

        o = s.option(form.DummyValue, 'profile', _('Config File'));
        o.rawhtml = true;
        o.cfgvalue = function () {
            return '<div class="cbi-input-text" style="cursor:default;opacity:0.8">/etc/monkey/run/config.yaml</div>';
        };

        o = s.option(form.Value, 'start_delay', _('Start Delay (seconds)'));
        o.datatype = 'uinteger';
        o.placeholder = '0';
        o.rmempty = true;

        return m.render();
    }
});
