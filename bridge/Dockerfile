FROM node:20-slim
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY index.js event_writer.js ./
CMD ["node", "index.js"]
