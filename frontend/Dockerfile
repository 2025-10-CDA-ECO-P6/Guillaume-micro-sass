FROM node:22-alpine
WORKDIR /app
RUN npm install -g pnpm
ENV CI=true
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --ignore-scripts
RUN pnpm rebuild
COPY . .
EXPOSE 4200
CMD ["node_modules/.bin/ng", "serve", "--host", "0.0.0.0", "--poll", "2000"]
