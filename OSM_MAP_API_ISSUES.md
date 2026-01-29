# OpenStreetMap API Issues - Live Server

## Problem
The map picker works on local server but not on live server. The Flutter code is correct - the issue is with external API access from the live server.

## External APIs Being Called

### 1. Nominatim OpenStreetMap API (Geocoding)
**Used for:**
- Place search: `https://nominatim.openstreetmap.org/search`
- Reverse geocoding: `https://nominatim.openstreetmap.org/reverse`

**Location in code:**
- `lib/widget/osm_map/map_controller.dart` (lines 19, 50)

**Current User-Agent:**
```
FlutterMapApp/1.0 (menil.siddhiinfosoft@gmail.com)
```

**Issues on Live Server:**
- Nominatim requires proper User-Agent identification
- Rate limiting: Max 1 request per second
- May block requests from certain IP ranges
- Requires HTTPS access from server

### 2. OpenStreetMap Tile Server (Map Tiles)
**Used for:**
- Map tiles: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`

**Location in code:**
- `lib/widget/osm_map/map_picker_page.dart` (line 50)
- `lib/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart` (line 35)

**Current User-Agent:**
```
com.jippymart.customer (already fixed)
```

**Issues on Live Server:**
- Tile server may block requests from server IPs
- Requires HTTPS access
- May have rate limiting

## Possible Causes on Live Server

1. **Firewall/Network Restrictions**
   - Live server firewall blocking outbound HTTPS to external APIs
   - Network security policies preventing external API calls

2. **IP Blocking**
   - Nominatim may have blocked the live server's IP address
   - OpenStreetMap tile server may have rate-limited the IP

3. **DNS Issues**
   - DNS resolution problems on live server
   - Cannot resolve `nominatim.openstreetmap.org` or `tile.openstreetmap.org`

4. **SSL/TLS Certificate Issues**
   - Certificate validation failures
   - Outdated SSL/TLS libraries on server

5. **Proxy Issues**
   - Server behind proxy that blocks external APIs
   - Proxy configuration not allowing these domains

## Solutions

### Option 1: Check Server Network Access (Recommended First Step)
Test if the live server can access these APIs:

```bash
# Test Nominatim API
curl -H "User-Agent: JippyMart-Customer/1.0 (com.jippymart.customer)" \
  "https://nominatim.openstreetmap.org/search?q=mumbai&format=json&limit=1"

# Test Tile Server
curl -I "https://tile.openstreetmap.org/13/4096/4096.png"
```

### Option 2: Configure Backend Proxy
If the server blocks direct access, create backend API endpoints that proxy these requests:

**Backend endpoints needed:**
- `GET /api/geocoding/search?q={query}` - Proxy to Nominatim search
- `GET /api/geocoding/reverse?lat={lat}&lon={lon}` - Proxy to Nominatim reverse
- `GET /api/map-tiles/{z}/{x}/{y}.png` - Proxy to tile server (optional)

Then update Flutter code to use:
```dart
'${AppConst.baseUrl}geocoding/search?q=$query'
'${AppConst.baseUrl}geocoding/reverse?lat=$lat&lon=$lon'
```

### Option 3: Use Alternative Geocoding Service
If Nominatim is blocked, consider:
- Google Geocoding API (requires API key)
- Mapbox Geocoding API (requires API key)
- Your own backend geocoding service

### Option 4: Whitelist Domains
If using a firewall/proxy, whitelist these domains:
- `nominatim.openstreetmap.org`
- `tile.openstreetmap.org`
- `*.tile.openstreetmap.org`

### Option 5: Update User-Agent
Nominatim requires a proper User-Agent. Current one may be too generic.

**Recommended User-Agent format:**
```
JippyMart-Customer/1.0 (com.jippymart.customer; contact: support@jippymart.in)
```

## Testing Checklist

- [ ] Test Nominatim API access from live server
- [ ] Test tile server access from live server
- [ ] Check server firewall rules
- [ ] Check server network configuration
- [ ] Verify DNS resolution on server
- [ ] Check SSL/TLS certificate validation
- [ ] Review server logs for blocked requests
- [ ] Check if server IP is blacklisted by Nominatim

## API Rate Limits

**Nominatim:**
- Max 1 request per second
- No more than 1 request per second per IP
- Heavy usage may result in temporary IP ban

**Tile Server:**
- No official rate limit, but excessive requests may be blocked
- Recommended: Use tile caching

## Next Steps

1. **Immediate:** Test API access from live server using curl commands above
2. **If blocked:** Set up backend proxy endpoints
3. **If rate-limited:** Implement request throttling in backend
4. **Long-term:** Consider using your own geocoding service or paid alternatives



