FROM node:24.15.0-bookworm-slim@sha256:4e6b70dd6cbfc88c8157ba19aa3d9f9cce6ba4703576d55459e45efcbc9c5f5d
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY index.js backend.js mqtt_bridge.js contact_operations.js event_writer.js mqtt_event_normalizer.js association_resolver.js ./
USER node
EXPOSE 8080
CMD ["node", "index.js"]
