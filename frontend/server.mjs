#!/usr/bin/env node
import { createServer } from 'vite'

async function start() {
    const server = await createServer({
    root: process.cwd(),
    server: {
        host: '0.0.0.0'
    }
})
    await server.listen()
    console.log('★ Vite dev server running at http://0.0.0.0:' + (server.config.server.port || 5173))
}

start().catch(err => {
    console.error(err)
    process.exit(1)
})