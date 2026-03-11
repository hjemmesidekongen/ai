# Vite Patterns — Process Reference

## vite.config.ts Structure

```ts
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: 'http://localhost:4000',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
      },
    },
    build: {
      outDir: 'dist',
      sourcemap: command === 'serve',
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
            router: ['react-router-dom'],
          },
        },
      },
    },
    define: {
      __APP_VERSION__: JSON.stringify(env.npm_package_version),
    },
  }
})
```

`command` is `'serve'` during dev and `'build'` during production. Use it to gate dev-only config like sourcemaps or verbose logging.

---

## Plugin API

Vite plugins extend Rollup's plugin interface with Vite-specific hooks.

### Core Rollup Hooks (available in both dev and build)

```ts
const myPlugin = (): Plugin => ({
  name: 'my-plugin',

  // Intercept module resolution — return virtual module id or null
  resolveId(id, importer) {
    if (id === 'virtual:my-module') return '\0virtual:my-module'
    return null
  },

  // Load module content — return code string or null
  load(id) {
    if (id === '\0virtual:my-module') {
      return `export const greeting = 'hello from virtual module'`
    }
    return null
  },

  // Transform module source — return transformed code or null
  transform(code, id) {
    if (!id.endsWith('.special')) return null
    return { code: transformSpecial(code), map: null }
  },
})
```

Virtual module convention: prefix with `\0` in resolved id to prevent other plugins from processing it.

### Vite-Specific Hooks

```ts
const devPlugin = (): Plugin => ({
  name: 'dev-only-plugin',
  apply: 'serve',   // 'serve' | 'build' | function

  // Add custom dev server middleware
  configureServer(server) {
    server.middlewares.use('/custom', (req, res) => {
      res.end('custom response')
    })
  },

  // Inject or modify HTML at dev time and build time
  transformIndexHtml(html) {
    return html.replace(
      '<head>',
      `<head><meta name="build-time" content="${Date.now()}">`
    )
  },

  // Intercept HMR updates
  handleHotUpdate({ file, server, modules }) {
    if (file.endsWith('.data')) {
      server.ws.send({ type: 'full-reload' })
      return []  // prevent default HMR for this file
    }
  },
})
```

`enforce: 'pre'` runs before Vite's core transforms. `enforce: 'post'` runs after. Omit for default ordering (between pre and post).

---

## HMR API

### Built-in HMR (framework plugins handle this)

Framework plugins (React, Vue) set up HMR automatically. For custom modules:

```ts
// In a module that wants to accept HMR updates
if (import.meta.hot) {
  import.meta.hot.accept((newModule) => {
    // newModule is the updated module
    // re-run setup logic with new module
  })

  // Accept updates to a specific dependency
  import.meta.hot.accept('./dep.ts', (newDep) => {
    console.log('dep updated', newDep)
  })

  // Clean up side effects before the old module is replaced
  import.meta.hot.dispose((data) => {
    data.cleanup = myInterval  // pass data to next accept
    clearInterval(myInterval)
  })

  // Invalidate — force full reload for this module
  import.meta.hot.invalidate()
}
```

`import.meta.hot` is `undefined` in production — all HMR code is tree-shaken.

### Custom HMR Events (server → client)

```ts
// Plugin: send custom event
handleHotUpdate({ server }) {
  server.ws.send({ type: 'custom', event: 'schema-reload', data: {} })
}

// Client: listen for custom event
if (import.meta.hot) {
  import.meta.hot.on('schema-reload', (data) => {
    refetchSchema()
  })
}
```

---

## Environment Variables

### .env File Priority

Loaded in order (later overrides earlier):
1. `.env`
2. `.env.local`
3. `.env.[mode]` (e.g., `.env.production`)
4. `.env.[mode].local`

`.local` files are gitignored. Use them for secrets and machine-specific overrides.

### Client Exposure (VITE_ prefix)

```ts
// .env.development
VITE_API_URL=http://localhost:4000
VITE_FEATURE_FLAGS=dark-mode,beta-ui
DATABASE_URL=postgres://...   // NOT exposed to client

// In application code
const apiUrl = import.meta.env.VITE_API_URL
const mode = import.meta.env.MODE          // 'development' | 'production' | custom
const isProd = import.meta.env.PROD        // boolean
const isDev = import.meta.env.DEV          // boolean
const ssr = import.meta.env.SSR            // boolean
```

### TypeScript Augmentation

```ts
// env.d.ts
interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_FEATURE_FLAGS: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

### Loading env in Config

```ts
import { loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  // Third argument '' loads all vars, not just VITE_-prefixed
  const env = loadEnv(mode, process.cwd(), '')

  return {
    define: {
      'process.env.NODE_ENV': JSON.stringify(mode),
    },
  }
})
```

### Modes

Default modes: `development` (serve), `production` (build). Custom modes: `vite build --mode staging`.

Each mode can have its own `.env.staging` file. Check `import.meta.env.MODE` at runtime to branch logic.

---

## Build Optimization

### Code Splitting

Vite splits automatically on dynamic imports:

```ts
// Automatic code split — creates a separate chunk
const AdminPanel = lazy(() => import('./AdminPanel'))
const route = { component: () => import('./views/Home.vue') }
```

### Manual Chunks

Group dependencies into named bundles for cache stability:

```ts
build: {
  rollupOptions: {
    output: {
      manualChunks(id) {
        if (id.includes('node_modules')) {
          if (id.includes('react')) return 'react-vendor'
          if (id.includes('@tanstack')) return 'query-vendor'
          return 'vendor'
        }
      },
      // Or static mapping:
      manualChunks: {
        'react-vendor': ['react', 'react-dom', 'react-router-dom'],
        'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
      },
    },
  },
}
```

Use function form when you need dynamic grouping. Use static mapping when deps are stable and known.

### Rollup Options

```ts
build: {
  rollupOptions: {
    // Multiple entry points (for multi-page or library)
    input: {
      main: 'index.html',
      admin: 'admin/index.html',
    },
    external: ['react', 'react-dom'],  // don't bundle (library mode)
    output: {
      globals: { react: 'React', 'react-dom': 'ReactDOM' },
      entryFileNames: '[name]-[hash].js',
      chunkFileNames: 'chunks/[name]-[hash].js',
      assetFileNames: 'assets/[name]-[hash][extname]',
    },
  },
  chunkSizeWarningLimit: 800,  // kB
  minify: 'esbuild',           // 'esbuild' (default, fast) | 'terser' (better compression)
}
```

### Tree Shaking

Vite/Rollup tree-shakes ES modules. Ensure:
- Dependencies declare `"sideEffects": false` in their `package.json` where accurate.
- Barrel files (`index.ts` that re-export everything) only import what's needed, or use named imports at the point of use instead.
- `import 'some-lib'` (side-effect import) is intentional — it prevents tree shaking of that module.

---

## Library Mode

For publishing a component library or utility package:

```ts
import { resolve } from 'path'

build: {
  lib: {
    entry: resolve(__dirname, 'src/index.ts'),
    name: 'MyLib',
    fileName: (format) => `my-lib.${format}.js`,
    formats: ['es', 'cjs', 'umd'],
  },
  rollupOptions: {
    external: ['react', 'react-dom', 'vue'],  // peer deps
    output: {
      globals: {
        react: 'React',
        'react-dom': 'ReactDOM',
        vue: 'Vue',
      },
    },
  },
}
```

Always externalize framework and peer dependencies in library mode. Bundling React into a React library causes duplicate instances.

---

## SSR

```ts
// vite.config.ts — SSR-specific options
build: {
  ssr: true,
  rollupOptions: {
    input: 'src/entry-server.ts',
  },
}

// Runtime
import { createServer } from 'vite'

const vite = await createServer({ server: { middlewareMode: true }, appType: 'custom' })

app.use(vite.middlewares)
app.use('*', async (req, res) => {
  const { render } = await vite.ssrLoadModule('/src/entry-server.ts')
  const html = await render(req.originalUrl)
  res.send(html)
})
```

In SSR, `import.meta.env.SSR` is `true`. Use it to gate browser-only code. Avoid `window`/`document` at module init level — move to `onMounted` or check `typeof window !== 'undefined'`.

---

## Proxy Configuration

```ts
server: {
  proxy: {
    // Simple path prefix proxy
    '/api': 'http://localhost:4000',

    // Full config
    '/api': {
      target: 'http://localhost:4000',
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, ''),
      secure: false,
    },

    // WebSocket proxy
    '/socket.io': {
      target: 'ws://localhost:4000',
      ws: true,
    },

    // Regex-based proxy
    '^/fallback/.*': {
      target: 'http://jsonplaceholder.typicode.com',
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/fallback/, ''),
    },
  },
}
```

`changeOrigin: true` sets the `Host` header to the target URL. Required for most backend servers that check the host header.

---

## CSS Handling

### CSS Modules

Files ending in `.module.css` (or `.module.scss`, etc.) are automatically treated as CSS Modules:

```ts
import styles from './Button.module.css'

// styles.button is a scoped class name like 'Button_button__abc123'
<div className={styles.button}>
```

Config options:

```ts
css: {
  modules: {
    localsConvention: 'camelCase',   // 'camelCase' | 'camelCaseOnly' | 'dashes' | 'dashesOnly'
    generateScopedName: '[name]__[local]__[hash:5]',
  },
}
```

### CSS Preprocessors

Install the preprocessor, no plugin needed:

```bash
npm install -D sass         # .scss / .sass
npm install -D less         # .less
npm install -D stylus       # .styl
```

Global variables/mixins via `additionalData`:

```ts
css: {
  preprocessorOptions: {
    scss: {
      additionalData: `@use "@/styles/variables" as *;`,
    },
  },
}
```

### PostCSS

Vite auto-detects `postcss.config.js` or reads from `css.postcss` in vite.config:

```ts
css: {
  postcss: {
    plugins: [
      require('tailwindcss'),
      require('autoprefixer'),
    ],
  },
}
```

For Tailwind v4+, use the Vite plugin instead: `@tailwindcss/vite`.

---

## Dependency Pre-Bundling (optimizeDeps)

Vite pre-bundles CommonJS dependencies to ESM at startup. This is usually automatic. Manual control:

```ts
optimizeDeps: {
  // Force include — deps that are not auto-detected (e.g., dynamically imported)
  include: ['lodash-es', 'some-package/deep/import'],

  // Force exclude — deps that should not be pre-bundled (e.g., already ESM, or linked packages)
  exclude: ['@my-org/local-lib'],

  // Pass esbuild options for the pre-bundler
  esbuildOptions: {
    plugins: [myEsbuildPlugin()],
  },
}
```

If you see `The requested module does not provide an export named 'X'` at dev time, the dependency likely needs to be added to `include`.

---

## Multi-Page Apps

```ts
build: {
  rollupOptions: {
    input: {
      main: path.resolve(__dirname, 'index.html'),
      dashboard: path.resolve(__dirname, 'dashboard/index.html'),
      admin: path.resolve(__dirname, 'admin/index.html'),
    },
  },
}
```

Each entry gets its own HTML file and shared chunks are extracted automatically. Dev server serves each at its directory path.

---

## Web Workers

```ts
// Inline worker — appended with ?worker
import MyWorker from './my-worker?worker'
const worker = new MyWorker()

// Inline worker as data URL (no separate file)
import MyWorker from './my-worker?worker&inline'

// URL import (for manual Worker construction)
import workerUrl from './my-worker?url'
const worker = new Worker(workerUrl, { type: 'module' })
```

Workers are bundled separately. They have access to `import.meta.env` but not the main thread's Vite module graph.

---

## Common Anti-Patterns

**Using `require()` in vite.config.ts.** The config file runs in a native ESM context. Use `import` and `createRequire` if you need to interop with a CJS-only package.

**Importing from `node_modules` deeply without `optimizeDeps.include`.** If a package has subpath exports that aren't auto-detected, dev mode will fail or be slow. Add to `include` explicitly.

**Putting secrets in VITE_-prefixed vars.** Any `VITE_` variable is bundled into the client. Use server-only env vars for API keys, DB credentials, etc.

**Relying on `process.env` in client code.** Vite uses `import.meta.env`. `process.env` is only available in Node.js context (config file, SSR server). Use `define` to polyfill if a library requires it.

**Skipping manualChunks on large apps.** Without it, all vendor code lands in one chunk. Any dep update invalidates the entire vendor bundle cache.

**Using `?raw` or `?url` imports in SSR paths.** These are transformed at build time for the client. In SSR entry points, file reads should use `fs.readFileSync` directly.

**Barrel re-exports for large modules.**
```ts
// WRONG — forces bundling of entire module even if you only need one export
import { Button } from '@/components'

// CORRECT — direct import lets tree shaking work
import { Button } from '@/components/Button'
```

**Forgetting `base` for non-root deployments.** If the app deploys to `/my-app/`, set `base: '/my-app/'` in config. Without it, asset URLs break.

```ts
base: process.env.DEPLOY_PATH ?? '/',
```
