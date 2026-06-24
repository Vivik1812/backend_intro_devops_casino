#ETAPA 1: Builder
FROM node:20-alpine AS builder

WORKDIR /app 

COPY package*.json ./

RUN if [ -f package-lock.json ]; then \
    echo ">>> package-lock.json encontrado: usando npm ci (reproducible)"; \
    npm ci --omit=dev; \
    else \
    echo ">>> AVISO: package-lock.json NO encontrado, usando npm install --omit=dev"; \
    echo ">>> Genera el lockfile con 'npm install' en tu host y commitealo."; \
    npm install --omit=dev; \
    fi

COPY . .

# ---------- ETAPA 2: runtime ----------
FROM node:20-alpine AS runtime

LABEL maintainer="Backend Casino"
LABEL descripcion="Backend Node - Casino"

WORKDIR /app

COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package*.json ./
COPY --from=builder --chown=node:node /app/src ./src

RUN mkdir -p /data && chown -R node:node /data

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:3000/ready',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]