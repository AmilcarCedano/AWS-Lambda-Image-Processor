FROM public.ecr.aws/lambda/nodejs:20

# Copy package files
COPY package.json ${LAMBDA_TASK_ROOT}/

# Install production dependencies
RUN npm ci --production

# Copy function code
COPY index.mjs ${LAMBDA_TASK_ROOT}/

# Set the handler
CMD ["index.handler"]
