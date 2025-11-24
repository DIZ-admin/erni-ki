# API Documentation

This directory contains API specifications for ERNI-KI services.

## Services

### Auth Service

- **OpenAPI Spec**: [auth-service-openapi.yaml](./auth-service-openapi.yaml)
- **Service**: JWT token validation service
- **Port**: 9090
- **Endpoints**:
  - `GET /` - Service information
  - `GET /health` - Health check
  - `GET /validate` - JWT token validation (cookie-based)

## Viewing Specifications

### Using Swagger UI (Docker)

```bash
docker run -p 8080:8080 -e SWAGGER_JSON=/docs/auth-service-openapi.yaml \
  -v $(pwd)/docs/api:/docs swaggerapi/swagger-ui
```

Then open: http://localhost:8080

### Using Redoc (Docker)

```bash
docker run -p 8080:80 -e SPEC_URL=/docs/auth-service-openapi.yaml \
  -v $(pwd)/docs/api:/docs redocly/redoc
```

Then open: http://localhost:8080

### Using VS Code

Install the "OpenAPI (Swagger) Editor" extension and open the YAML files.

## Validating Specifications

```bash
# Using Redocly CLI
npx @redocly/cli lint docs/api/auth-service-openapi.yaml

# Using Swagger CLI
npx @apidevtools/swagger-cli validate docs/api/auth-service-openapi.yaml
```

## Related Documentation

- [Auth Service Source Code](../../auth/main.go)
- [Security Documentation](../security/)
