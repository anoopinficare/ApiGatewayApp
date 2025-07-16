using Microsoft.AspNetCore.Mvc;
using UsersApi.Models;

namespace UsersApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private static readonly List<User> _users = new()
        {
            new User { Id = 1, FirstName = "John", LastName = "Doe", Email = "john.doe@example.com", CreatedDate = DateTime.Now.AddDays(-10), IsActive = true },
            new User { Id = 2, FirstName = "Jane", LastName = "Smith", Email = "jane.smith@example.com", CreatedDate = DateTime.Now.AddDays(-5), IsActive = true },
            new User { Id = 3, FirstName = "Bob", LastName = "Johnson", Email = "bob.johnson@example.com", CreatedDate = DateTime.Now.AddDays(-2), IsActive = false }
        };

        private static int _nextId = 4;

        [HttpGet]
        public ActionResult<IEnumerable<User>> GetUsers()
        {
            return Ok(_users);
        }

        [HttpGet("{id}")]
        public ActionResult<User> GetUser(int id)
        {
            var user = _users.FirstOrDefault(u => u.Id == id);
            if (user == null)
            {
                return NotFound($"User with ID {id} not found");
            }
            return Ok(user);
        }

        [HttpGet("active")]
        public ActionResult<IEnumerable<User>> GetActiveUsers()
        {
            var activeUsers = _users.Where(u => u.IsActive).ToList();
            return Ok(activeUsers);
        }

        [HttpPost]
        public ActionResult<User> CreateUser(CreateUserRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FirstName) || 
                string.IsNullOrWhiteSpace(request.LastName) || 
                string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest("FirstName, LastName, and Email are required");
            }

            var user = new User
            {
                Id = _nextId++,
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                CreatedDate = DateTime.Now,
                IsActive = true
            };

            _users.Add(user);
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }

        [HttpPut("{id}")]
        public ActionResult<User> UpdateUser(int id, UpdateUserRequest request)
        {
            var user = _users.FirstOrDefault(u => u.Id == id);
            if (user == null)
            {
                return NotFound($"User with ID {id} not found");
            }

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.IsActive = request.IsActive;

            return Ok(user);
        }

        [HttpDelete("{id}")]
        public ActionResult DeleteUser(int id)
        {
            var user = _users.FirstOrDefault(u => u.Id == id);
            if (user == null)
            {
                return NotFound($"User with ID {id} not found");
            }

            _users.Remove(user);
            return NoContent();
        }

        [HttpGet("search")]
        public ActionResult<IEnumerable<User>> SearchUsers([FromQuery] string? firstName, [FromQuery] string? lastName, [FromQuery] string? email)
        {
            var query = _users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(firstName))
            {
                query = query.Where(u => u.FirstName.Contains(firstName, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(lastName))
            {
                query = query.Where(u => u.LastName.Contains(lastName, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(email))
            {
                query = query.Where(u => u.Email.Contains(email, StringComparison.OrdinalIgnoreCase));
            }

            return Ok(query.ToList());
        }
    }
}
