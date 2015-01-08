# Harmony

Daemon for redwire

Harmony runs a directory full of javascript files as individual redwire instances.

[![NPM version](https://badge.fury.io/js/redwire-harmony.svg)](http://badge.fury.io/js/redwire-harmony)

## Install

```sh
npm install -g redwire-harmony
```

## Usage

In a directory with the javascript files you want to run as redwire instances

```sh
harmony
```

To reload any changes send a SIGHUP to the harmony daemon

## Examples

```js
module.exports = {
    config: { http: { port: 8888 } },
    bind: function(redwire, bindings) {
        // bindings has http, https, tcp, tls and websocket mounts
        // See documentation for redwire
        bindings
            .http('http://localhost:8888/')
            .use(function(mount, url, req, res, next) {
                res.write('OK');
                res.end();
            });
        bindings
            .http('http://localhost:8888/api')
            .use(function(mount, url, req, res, next) {
                console.log('API CALL');
                next();
            })
            .use(redwire.proxy('http://localhost:9999/api');
    },
    end: function() {
        // clean up any services you are using here
    }
};
```