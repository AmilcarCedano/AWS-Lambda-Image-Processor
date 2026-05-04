FROM public.ecr.aws/lambda/nodejs:20

# Install build tools needed for sharp native compilation
RUN dnf install -y gcc-c++ make && dnf clean all

# Copy package files
COPY package.json ${LAMBDA_TASK_ROOT}/

# Install production dependencies (sharp requires native build)
RUN npm ci --production

# Copy function code
COPY index.mjs ${LAMBDA_TASK_ROOT}/

# Set the handler
CMD ["index.handler"]
