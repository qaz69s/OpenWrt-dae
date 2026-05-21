'use strict';
'require baseclass';
'require uci';
'require fs';
'require rpc';

const callRCList = rpc.declare({
    object: 'rc',
    method: 'list',
    params: ['name'],
    expect: { '': {} }
});

const callRCInit = rpc.declare({
    object: 'rc',
    method: 'init',
    params: ['name', 'action'],
    expect: { '': {} }
});

const callMonkeyGetPaths = rpc.declare({
    object: 'luci.monkey',
    method: 'get_paths',
    expect: { '': {} }
});

const callMonkeyVersion = rpc.declare({
    object: 'luci.monkey',
    method: 'version',
    expect: { '': {} }
});

const callMonkeyGetFileContent = rpc.declare({
    object: 'luci.monkey',
    method: 'getFileContent',
    params: ['path'],
    expect: { '': {} }
});

const callMonkeyWriteFileContent = rpc.declare({
    object: 'luci.monkey',
    method: 'writeFileContent',
    params: ['path', 'content'],
    expect: { '': {} }
});

const callMonkeyProfile = rpc.declare({
    object: 'luci.monkey',
    method: 'profile',
    expect: { '': {} }
});

return baseclass.extend({
    getPaths: async function () {
        return callMonkeyGetPaths();
    },

    status: async function () {
        return (await callRCList('monkey'))?.monkey?.running;
    },

    reload: function () {
        return callRCInit('monkey', 'reload');
    },

    restart: function () {
        return callRCInit('monkey', 'restart');
    },

    version: function () {
        return callMonkeyVersion();
    },

    getConfigFile: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(callMonkeyGetFileContent(paths.run_profile_path), { content: '' });
    },

    getMixinFile: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(callMonkeyGetFileContent(paths.mixin_yaml), { content: '' });
    },

    writeConfigFile: async function (content) {
        const paths = await this.getPaths();
        return callMonkeyWriteFileContent(paths.run_profile_path, content);
    },

    getAppLog: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(fs.read_direct(paths.app_log_path));
    },

    getCoreLog: async function () {
        const paths = await this.getPaths();
        return L.resolveDefault(fs.read_direct(paths.core_log_path));
    },

    clearAppLog: async function () {
        const paths = await this.getPaths();
        return fs.write(paths.app_log_path);
    },

    clearCoreLog: async function () {
        const paths = await this.getPaths();
        return fs.write(paths.core_log_path);
    },

    profile: function () {
        return callMonkeyProfile();
    },

    openDashboard: async function () {
        const profile = await this.profile();
        const apiListen = profile?.external_controller;
        const apiSecret = profile?.secret ?? '';
        if (!apiListen) {
            return Promise.reject('Clash API has not been configured');
        }
        // apiListen format: [::]:9090 or 0.0.0.0:9095 or :9090
        let apiPort = apiListen;
        if (apiListen.lastIndexOf(':') >= 0) {
            apiPort = apiListen.substring(apiListen.lastIndexOf(':') + 1);
        }
        const params = {
            host: window.location.hostname,
            hostname: window.location.hostname,
            port: apiPort,
            secret: apiSecret
        };
        const query = new URLSearchParams(params).toString();
        const url = `http://${window.location.hostname}:${apiPort}/ui/?${query}`;
        setTimeout(function () { window.open(url, '_blank') }, 0);
        return Promise.resolve();
    },
})
