import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { FindVetsDto } from './dto/find-vets.dto';

interface CacheEntry {
  timestamp: number;
  data: any;
}

@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);
  private readonly cache = new Map<string, CacheEntry>();
  private readonly CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

  // Haversine distance in KM
  private distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(lat1 * (Math.PI / 180)) *
        Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLon / 2) ** 2;
    return parseFloat((R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).toFixed(1));
  }

  async findNearbyVets(dto: FindVetsDto) {
    const { lat, lng } = dto;
    const radius = dto.radius || 30000; // 30km default

    if (!lat || !lng) {
      throw new BadRequestException('Real GPS coordinates (lat, lng) are required');
    }

    const cacheKey = `${parseFloat(lat.toString()).toFixed(2)},${parseFloat(lng.toString()).toFixed(2)}_${radius}`;
    const cached = this.cache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL_MS) {
      this.logger.log(`Serving OSM data from cache for ${cacheKey}`);
      return cached.data;
    }

    // ── Overpass API: real veterinary + animal health places from OpenStreetMap ──
    const overpassQuery = `[out:json][timeout:15];(node["amenity"="veterinary"](around:${radius},${lat},${lng});way["amenity"="veterinary"](around:${radius},${lat},${lng});node["healthcare"="veterinary"](around:${radius},${lat},${lng});node["office"="government"]["government"="livestock"](around:${radius},${lat},${lng});node["shop"="pet"](around:${radius},${lat},${lng});node["amenity"="animal_shelter"](around:${radius},${lat},${lng}););out body center 50;`;

    let results: any[] = [];

    try {
      const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(overpassQuery)}`;
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FarmAI/1.0',
        },
      });

      if (!response.ok) {
        this.logger.warn(`Overpass API returned ${response.status}: ${await response.text()}`);
      } else {
        const data: any = await response.json();
        if (data.elements && data.elements.length > 0) {
          results = data.elements
            .map((el: any) => {
              const elLat = el.lat || el.center?.lat;
              const elLng = el.lon || el.center?.lon;
              if (!elLat || !elLng) return null;

              const tags = el.tags || {};
              const name =
                tags['name:bn'] || tags.name || tags['name:en'] || null;
              if (!name) return null; // Skip unnamed places

              const address =
                tags['addr:full'] ||
                [tags['addr:street'], tags['addr:city'], tags['addr:district']]
                  .filter(Boolean)
                  .join(', ') ||
                null;
              const phone =
                tags.phone || tags['contact:phone'] || tags['contact:mobile'] || null;
              const website = tags.website || tags['contact:website'] || null;
              const openingHours = tags.opening_hours || null;

              // Determine place type
              let type = 'veterinary';
              if (tags.amenity === 'hospital') type = 'hospital';
              if (tags.amenity === 'animal_shelter') type = 'animal_shelter';
              if (tags.shop === 'pet') type = 'pet_shop';
              if (tags.office === 'government') type = 'government_livestock_office';
              if (tags.amenity === 'veterinary' || tags.healthcare === 'veterinary') type = 'veterinary';

              return {
                id: `osm-${el.id}`,
                name,
                type,
                latitude: elLat,
                longitude: elLng,
                address,
                phone,
                website,
                openingHours,
                distanceKm: this.distanceKm(lat, lng, elLat, elLng),
              };
            })
            .filter(Boolean);
        }
      }
    } catch (err) {
      this.logger.error(`Overpass API failed: ${err.message}`);
    }

    // Sort by distance
    results.sort((a, b) => a.distanceKm - b.distanceKm);

    const finalResult = {
      source: 'openstreetmap',
      query: { lat, lng, radiusMeters: radius },
      count: results.length,
      vets: results,
    };

    this.cache.set(cacheKey, { timestamp: Date.now(), data: finalResult });

    return finalResult;
  }
}
