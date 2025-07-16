# API Gateway High Availability Configuration

## Scenario: Multiple Gateway Instances Behind Load Balancer

### Gateway Instance 1: Port 5000
### Gateway Instance 2: Port 5100  
### Gateway Instance 3: Port 5200
### Load Balancer: Port 8080 (HAProxy/Nginx)

## HAProxy Configuration Example
```
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend api_gateway_frontend
    bind *:8080
    default_backend api_gateway_backend

backend api_gateway_backend
    balance roundrobin
    option httpchk GET /health
    server gateway1 localhost:5000 check
    server gateway2 localhost:5100 check
    server gateway3 localhost:5200 check
```

## Benefits:
- No single point of failure
- Automatic failover
- Health check integration
- Load distribution
- Rolling updates possible
