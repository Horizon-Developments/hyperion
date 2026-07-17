import enquirer from 'enquirer';
import chalk from 'chalk';
import localtunnel from '@security-patched/localtunnel';
import * as ngrok from '@ngrok/ngrok';
import { stat, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { createServer } from 'node:http';
import { WebSocketServer } from 'ws';
import Fastify from 'fastify';

const { Select, Input } = enquirer;
const gold = chalk.hex('#FFD700');
const CREDS_PATH = join(process.cwd(), 'credentials.json');
const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

const log = (text) => console.log(`[HYPERION]: ${text}`);

const randStr = (len) => Array.from({ length: len }, () => CHARS[Math.floor(Math.random() * CHARS.length)]).join('');

const isFile = async (path) => {
  try {
    return (await stat(path)).isFile();
  } catch {
    return false;
  }
};

const sessions = new Map();

const fastify = Fastify();
const wss = new WebSocketServer({ noServer: true });

fastify.post('/ws/start', async (req, reply) => {
  const constant = req.headers['constant'];

  if (typeof constant !== 'string' || constant.length !== 256 || !/^[A-Za-z0-9\-_]+$/.test(constant)) {
    return reply.code(400).send({ error: 'Bad Request', message: 'constant header must be a 256-char string (A-Z a-z 0-9 - _)' });
  }
  
  const authorization = constant;
  const baseUrl = fastify.baseUrl;
  const hash = randStr(64);
  
  sessions.set(hash, {
    authorization,
    owners: new Set(),
    clients: new Set(),
  });
  
  log(`Started a session (hash: ${hash})`);
  
  return reply.code(200).send({
    message: authorization
  });
});

const heartbeat = (ws, role, hash) => {
  ws.isAlive = true;

  const interval = setInterval(() => {
    if (!ws.isAlive) {
      clearInterval(interval);
      ws.terminate();
      log(`${role} Disconnected (failed to send heartbeat)`);
      return;
    }

    ws.isAlive = false;
    ws.send('HeartBeat');

    ws.heartbeatTimeout = setTimeout(() => {
      if (!ws.isAlive) {
        clearInterval(interval);
        ws.terminate();
        log(`${role} Disconnected (failed to send heartbeat)`);
      }
    }, 10000);
  }, 30000);
  
  ws.on('pong', () => { ws.isAlive = true; });
  ws.on('message', (msg) => {
    const text = msg.toString();
    if (text === 'HeartBeat') {
      ws.isAlive = true;
      if (ws.heartbeatTimeout) clearTimeout(ws.heartbeatTimeout);
    }

    const session = sessions.get(hash);
    if (role === 'Owner' && session) {
      for (const client of session.clients) {
        if (client.readyState === 1) client.send(text);
      }
    } else if (role === 'Client') {
      ws.send(`CLIENT_MESSAGE\n${text}`);
    }
  });

  ws.on('close', () => {
    clearInterval(interval);
    if (ws.heartbeatTimeout) clearTimeout(ws.heartbeatTimeout);
    const session = sessions.get(hash);
    if (session) {
      session.owners.delete(ws);
      session.clients.delete(ws);
    }
  });
};

wss.on('connection', (ws) => {
  ws.send('Authorisation');

  const authTimeout = setTimeout(() => {
    ws.terminate();
  }, 10000);

  ws.once('message', (msg) => {
    const text = msg.toString();

    if (!text.startsWith('Authorization:')) return;

    clearTimeout(authTimeout);

    const provided = text.slice('Authorization:'.length).trim();

    for (const [hash, session] of sessions.entries()) {
      if (session.authorization === provided) {
        const isOwner = session.owners.size === 0;
        const role = isOwner ? 'Owner' : 'Client';
        if (isOwner) session.owners.add(ws);
        else session.clients.add(ws);
        heartbeat(ws, role, hash);
        return;
      }
    }

    ws.terminate();
  });
});

await fastify.listen({ port: 0, host: '127.0.0.1' });
const port = fastify.server.address().port;

fastify.server.on('upgrade', (req, socket, head) => {
  if (req.url === '/ws/connection') {
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
  } else {
    socket.destroy();
  }
});

const credsExist = await isFile(CREDS_PATH);

let answer;
let creds = null;

if (credsExist) {
  const pick = await new Select({
    name: 'usePrevious',
    message: 'Use previous ngrok credentials?',
    choices: [
      { name: 'yes', message: chalk.green('Yes') },
      { name: 'no', message: chalk.red('No') },
    ],
  }).run();

  if (pick === 'yes') {
    creds = JSON.parse(await readFile(CREDS_PATH, 'utf8'));
    answer = 'ngrok';
  } else {
    answer = await new Select({
      name: 'option',
      message: `${chalk.bold('Recommended:')} ${chalk.green('Use ngrok')}`,
      choices: [
        { name: 'ngrok', message: `${chalk.green('1.')} Use ngrok`, hint: chalk.gray('Set up once, url stays stable') },
        { name: 'localtunnel', message: `${chalk.yellow('2.')} Use localtunnel`, hint: chalk.gray('Url updates every run') },
      ],
    }).run();
  }
} else {
  answer = await new Select({
    name: 'option',
    message: `${chalk.bold('Recommended:')} ${chalk.green('Use ngrok')}`,
    choices: [
      { name: 'ngrok', message: `${chalk.green('1.')} Use ngrok`, hint: chalk.gray('Set up once, Url stays stable') },
      { name: 'localtunnel', message: `${chalk.yellow('2.')} Use localtunnel`, hint: chalk.gray('Url updates every run') },
    ],
  }).run();
}

if (answer === 'ngrok') {
  if (creds === null) {
    const ngrok_auth = await new Input({ name: 'ngrok_auth', message: 'ngrok auth token:' }).run();
    const domain = await new Input({ name: 'domain', message: 'ngrok domain (e.g. abc123.ngrok-free.dev):' }).run();
    creds = { ngrok_auth, domain };
    await writeFile(CREDS_PATH, JSON.stringify(creds, null, 2), 'utf8');
    log(chalk.green('Credentials saved.'));
  }

  log(chalk.green('Starting ngrok...'));
  const listener = await ngrok.forward({ addr: port, authtoken: creds.ngrok_auth, domain: creds.domain });
  fastify.baseUrl = listener.url();
} else {
  log(chalk.yellow('Starting localtunnel...'));
  const lt = await localtunnel({ port });
  fastify.baseUrl = lt.url;
  lt.on('close', () => log('Tunnel closed'));
}

log(`Your hyperion token is: ${Buffer.from(fastify.baseUrl).toString('hex')}`);








