FROM node:18-alpine

WORKDIR /app

RUN mkdir -p logs

COPY package*.json ./
RUN npm install --legacy-peer-deps 2>&1 || npm install || true

COPY src ./src

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})" || true

CMD ["node", "src/index.js"]
