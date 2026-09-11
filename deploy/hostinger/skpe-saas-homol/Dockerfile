FROM node:24-alpine AS build

WORKDIR /app

COPY source/app/apps/web/package*.json ./apps/web/

WORKDIR /app/apps/web
RUN npm ci

COPY source/app /app

ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_PUBLISHABLE_KEY

ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_PUBLISHABLE_KEY=$VITE_SUPABASE_PUBLISHABLE_KEY

WORKDIR /app/apps/web
RUN npm run build

FROM nginx:1.28.0-alpine

COPY runtime/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/apps/web/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
