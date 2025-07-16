using Microsoft.AspNetCore.Mvc;
using LocationsApi.Models;

namespace LocationsApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LocationsController : ControllerBase
    {
        private static readonly List<Location> _locations = new()
        {
            new Location { Id = 1, Name = "Central Park", Address = "Central Park", City = "New York", State = "NY", Country = "USA", PostalCode = "10024", Latitude = 40.7829, Longitude = -73.9654, CreatedDate = DateTime.Now.AddDays(-20), IsActive = true },
            new Location { Id = 2, Name = "Golden Gate Bridge", Address = "Golden Gate Bridge", City = "San Francisco", State = "CA", Country = "USA", PostalCode = "94129", Latitude = 37.8199, Longitude = -122.4783, CreatedDate = DateTime.Now.AddDays(-15), IsActive = true },
            new Location { Id = 3, Name = "Times Square", Address = "Times Square", City = "New York", State = "NY", Country = "USA", PostalCode = "10036", Latitude = 40.7580, Longitude = -73.9855, CreatedDate = DateTime.Now.AddDays(-10), IsActive = true },
            new Location { Id = 4, Name = "Hollywood Sign", Address = "Mount Lee", City = "Los Angeles", State = "CA", Country = "USA", PostalCode = "90068", Latitude = 34.1341, Longitude = -118.3215, CreatedDate = DateTime.Now.AddDays(-5), IsActive = false }
        };

        private static int _nextId = 5;

        [HttpGet]
        public ActionResult<IEnumerable<Location>> GetLocations()
        {
            return Ok(_locations);
        }

        [HttpGet("{id}")]
        public ActionResult<Location> GetLocation(int id)
        {
            var location = _locations.FirstOrDefault(l => l.Id == id);
            if (location == null)
            {
                return NotFound($"Location with ID {id} not found");
            }
            return Ok(location);
        }

        [HttpGet("active")]
        public ActionResult<IEnumerable<Location>> GetActiveLocations()
        {
            var activeLocations = _locations.Where(l => l.IsActive).ToList();
            return Ok(activeLocations);
        }

        [HttpGet("by-city/{city}")]
        public ActionResult<IEnumerable<Location>> GetLocationsByCity(string city)
        {
            var cityLocations = _locations.Where(l => l.City.Equals(city, StringComparison.OrdinalIgnoreCase)).ToList();
            return Ok(cityLocations);
        }

        [HttpGet("by-state/{state}")]
        public ActionResult<IEnumerable<Location>> GetLocationsByState(string state)
        {
            var stateLocations = _locations.Where(l => l.State.Equals(state, StringComparison.OrdinalIgnoreCase)).ToList();
            return Ok(stateLocations);
        }

        [HttpPost]
        public ActionResult<Location> CreateLocation(CreateLocationRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Name) || 
                string.IsNullOrWhiteSpace(request.City) || 
                string.IsNullOrWhiteSpace(request.Country))
            {
                return BadRequest("Name, City, and Country are required");
            }

            var location = new Location
            {
                Id = _nextId++,
                Name = request.Name,
                Address = request.Address,
                City = request.City,
                State = request.State,
                Country = request.Country,
                PostalCode = request.PostalCode,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                CreatedDate = DateTime.Now,
                IsActive = true
            };

            _locations.Add(location);
            return CreatedAtAction(nameof(GetLocation), new { id = location.Id }, location);
        }

        [HttpPut("{id}")]
        public ActionResult<Location> UpdateLocation(int id, UpdateLocationRequest request)
        {
            var location = _locations.FirstOrDefault(l => l.Id == id);
            if (location == null)
            {
                return NotFound($"Location with ID {id} not found");
            }

            location.Name = request.Name;
            location.Address = request.Address;
            location.City = request.City;
            location.State = request.State;
            location.Country = request.Country;
            location.PostalCode = request.PostalCode;
            location.Latitude = request.Latitude;
            location.Longitude = request.Longitude;
            location.IsActive = request.IsActive;

            return Ok(location);
        }

        [HttpDelete("{id}")]
        public ActionResult DeleteLocation(int id)
        {
            var location = _locations.FirstOrDefault(l => l.Id == id);
            if (location == null)
            {
                return NotFound($"Location with ID {id} not found");
            }

            _locations.Remove(location);
            return NoContent();
        }

        [HttpGet("search")]
        public ActionResult<IEnumerable<Location>> SearchLocations(
            [FromQuery] string? name, 
            [FromQuery] string? city, 
            [FromQuery] string? state,
            [FromQuery] string? country)
        {
            var query = _locations.AsQueryable();

            if (!string.IsNullOrWhiteSpace(name))
            {
                query = query.Where(l => l.Name.Contains(name, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(city))
            {
                query = query.Where(l => l.City.Contains(city, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(state))
            {
                query = query.Where(l => l.State.Contains(state, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(country))
            {
                query = query.Where(l => l.Country.Contains(country, StringComparison.OrdinalIgnoreCase));
            }

            return Ok(query.ToList());
        }

        [HttpGet("nearby")]
        public ActionResult<IEnumerable<Location>> GetNearbyLocations(
            [FromQuery] double latitude, 
            [FromQuery] double longitude, 
            [FromQuery] double radiusKm = 10.0)
        {
            var nearbyLocations = _locations.Where(l =>
            {
                var distance = CalculateDistance(latitude, longitude, l.Latitude, l.Longitude);
                return distance <= radiusKm;
            }).ToList();

            return Ok(nearbyLocations);
        }

        private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            // Haversine formula for calculating distance between two points on Earth
            const double R = 6371; // Earth's radius in kilometers

            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private static double ToRadians(double degrees)
        {
            return degrees * Math.PI / 180;
        }
    }
}
