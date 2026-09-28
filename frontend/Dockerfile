# ============ STAGE 1 : BUILD (Node.js) ============
FROM node:22-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances (cache Docker)
COPY package*.json ./
RUN npm install

# Copier tout le code source
COPY . .

# Build de production (Vite génère dans /app/dist)
RUN npm run build

# ============ STAGE 2 : SERVE (Nginx) ============
FROM nginx:alpine

# Copier la config Nginx personnalisée
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier le build depuis le stage builder
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]