# Use a Node.js image with the same version you use locally
FROM node:20

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your project
COPY . .



# Expose the default Strapi port
EXPOSE 1337

# Run in development mode
CMD ["npm", "run", "develop"]
