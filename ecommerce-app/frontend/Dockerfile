FROM node:20-alpine AS widget-builder
WORKDIR /src/chat-app/frontend
COPY chat-app/frontend/package*.json ./
RUN npm ci --legacy-peer-deps
COPY chat-app/frontend/ ./
RUN npm run build

FROM node:20-alpine AS app-builder
WORKDIR /src/ecommerce-app/frontend
COPY ecommerce-app/frontend/package*.json ./
RUN npm ci --legacy-peer-deps
COPY ecommerce-app/frontend/ ./
RUN npm run build
COPY --from=widget-builder /src/chat-app/frontend/dist/widget.js ./dist/widget.js

FROM nginx:alpine
COPY --from=app-builder /src/ecommerce-app/frontend/dist /usr/share/nginx/html
COPY ecommerce-app/frontend/nginx.conf /etc/nginx/nginx.conf
COPY ecommerce-app/frontend/startup.sh /docker-entrypoint.d/startup.sh
RUN chmod +x /docker-entrypoint.d/startup.sh
RUN sed -i 's/\r$//' /docker-entrypoint.d/startup.sh
EXPOSE 80
CMD ["/bin/sh", "-c", "/docker-entrypoint.d/startup.sh"]
