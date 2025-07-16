# Email Template Manager Integration Guide

This guide provides step-by-step instructions for integrating the Email Template Manager functionality into any existing .NET 8 Core application as an **Area**.

## Overview

The Email Template Manager allows users to:
- Upload Word (.docx) documents and convert them to HTML templates
- Create HTML templates using CKEditor 5 (free, no API key required)
- Manage email templates with variable placeholders
- Send emails using templates with data binding
- Track email history

## Integration Options

This guide covers two integration approaches:
1. **As an Area** (Recommended) - Organized as a separate module
2. **Direct Integration** - Directly into the main application

## Prerequisites

- Existing .NET 8 Core application (MVC or API)
- SQL Server database (or compatible EF Core provider)
- Basic understanding of ASP.NET Core MVC patterns and Areas

## Integration Steps

## Option A: Integration as an Area (Recommended)

Areas provide better organization and separation of concerns for modular functionality.

### A1. Create Area Structure

Create the following folder structure in your project:

```
Areas/
  EmailTemplates/
    Controllers/
      TemplateController.cs
      EmailController.cs
    Views/
      _ViewStart.cshtml
      _ViewImports.cshtml
      Template/
        Index.cshtml
        Upload.cshtml
        Details.cshtml
        Edit.cshtml
        Preview.cshtml
      Email/
        Send.cshtml
        History.cshtml
        Details.cshtml
    Models/  (Optional - you can keep models in main Models folder)
```

### A2. Install Required NuGet Packages

Add the following packages to your existing project:

```xml
<PackageReference Include="DocumentFormat.OpenXml" Version="3.3.0" />
<PackageReference Include="MailKit" Version="4.13.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.8" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.8">
  <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
  <PrivateAssets>all</PrivateAssets>
</PackageReference>
<PackageReference Include="OpenXmlPowerTools" Version="4.5.3.2" />
```

### A3. Configure Area Routing

Add area routing configuration in your `Program.cs`:

```csharp
// Configure routing for areas
app.MapControllerRoute(
    name: "EmailTemplatesArea",
    pattern: "{area:exists}/{controller=Template}/{action=Index}/{id?}");

// Keep your existing default route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
```

### A4. Database Models

Create the following model classes in your main `Models` folder:

#### Template.cs
```csharp
using System.ComponentModel.DataAnnotations;

namespace YourApp.Models
{
    public class Template
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        public string HtmlContent { get; set; } = string.Empty;
        
        public string? Subject { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? UpdatedAt { get; set; }
        
        public string? Description { get; set; }
        
        // Navigation property
        public ICollection<EmailLog> EmailLogs { get; set; } = new List<EmailLog>();
    }
}
```

#### EmailLog.cs
```csharp
using System.ComponentModel.DataAnnotations;

namespace YourApp.Models
{
    public class EmailLog
    {
        public int Id { get; set; }
        
        [Required]
        public string ToEmail { get; set; } = string.Empty;
        
        public string? FromEmail { get; set; }
        
        [Required]
        public string Subject { get; set; } = string.Empty;
        
        [Required]
        public string Body { get; set; } = string.Empty;
        
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
        
        public bool IsSuccess { get; set; }
        
        public string? ErrorMessage { get; set; }
        
        // Foreign key
        public int? TemplateId { get; set; }
        public Template? Template { get; set; }
    }
}
```

#### ViewModels.cs
```csharp
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace YourApp.Models
{
    public class UploadTemplateViewModel
    {
        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;
        
        public string? Description { get; set; }
        
        public IFormFile? WordFile { get; set; }
        
        public string? HtmlContent { get; set; }
        
        [Required]
        public string CreationMethod { get; set; } = "file"; // "file" or "html"
    }

    public class SendEmailViewModel
    {
        [Required]
        public int TemplateId { get; set; }
        
        [Required]
        [EmailAddress]
        public string ToEmail { get; set; } = string.Empty;
        
        public string? FromEmail { get; set; }
        
        [Required]
        public string Subject { get; set; } = string.Empty;
        
        public string EmailContent { get; set; } = string.Empty;
        
        public Dictionary<string, string> Variables { get; set; } = new();
        
        public List<SelectListItem> Templates { get; set; } = new();
    }

    public class TemplateDetailsViewModel
    {
        public Template Template { get; set; } = new();
        public List<string> Variables { get; set; } = new();
    }

    public class EmailHistoryViewModel
    {
        public List<EmailLog> EmailLogs { get; set; } = new();
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int TotalCount { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    }
}
```

### A5. Area Controllers

Create controllers in `Areas/EmailTemplates/Controllers/`:

#### TemplateController.cs
```csharp
using Microsoft.AspNetCore.Mvc;
using YourApp.Models;
using YourApp.Services;

namespace YourApp.Areas.EmailTemplates.Controllers
{
    [Area("EmailTemplates")]
    public class TemplateController : Controller
    {
        private readonly ITemplateService _templateService;

        public TemplateController(ITemplateService templateService)
        {
            _templateService = templateService;
        }

        public async Task<IActionResult> Index()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            return View(templates);
        }

        public IActionResult Upload()
        {
            return View(new UploadTemplateViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(UploadTemplateViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                // Check if template name already exists
                if (await _templateService.TemplateExistsAsync(model.Name))
                {
                    ModelState.AddModelError("Name", "A template with this name already exists.");
                    return View(model);
                }

                Template template;
                
                if (model.CreationMethod == "file" && model.WordFile != null)
                {
                    template = await _templateService.CreateTemplateFromFileAsync(
                        model.Name, model.WordFile, model.Description);
                }
                else if (model.CreationMethod == "html" && !string.IsNullOrEmpty(model.HtmlContent))
                {
                    template = await _templateService.CreateTemplateFromHtmlAsync(
                        model.Name, model.HtmlContent, model.Description);
                }
                else
                {
                    ModelState.AddModelError("", "Please provide either a Word file or HTML content.");
                    return View(model);
                }

                TempData["SuccessMessage"] = "Template created successfully!";
                return RedirectToAction(nameof(Details), new { id = template.Id });
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error creating template: {ex.Message}");
                return View(model);
            }
        }

        public async Task<IActionResult> Details(int id)
        {
            var template = await _templateService.GetTemplateByIdAsync(id);
            if (template == null)
            {
                return NotFound();
            }

            var variables = await _templateService.ExtractVariablesFromTemplateAsync(id);
            var viewModel = new TemplateDetailsViewModel
            {
                Template = template,
                Variables = variables
            };

            return View(viewModel);
        }

        // Add other actions: Edit, Delete, Preview
        // (Copy implementations from the original EmailTemplateManager project)
    }
}
```

#### EmailController.cs
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using YourApp.Models;
using YourApp.Services;

namespace YourApp.Areas.EmailTemplates.Controllers
{
    [Area("EmailTemplates")]
    public class EmailController : Controller
    {
        private readonly IEmailService _emailService;
        private readonly ITemplateService _templateService;

        public EmailController(IEmailService emailService, ITemplateService templateService)
        {
            _emailService = emailService;
            _templateService = templateService;
        }

        public async Task<IActionResult> Send()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            var viewModel = new SendEmailViewModel
            {
                Templates = templates.Select(t => new SelectListItem
                {
                    Value = t.Id.ToString(),
                    Text = t.Name
                }).ToList()
            };

            return View(viewModel);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Send(SendEmailViewModel model)
        {
            // Reload templates for the dropdown
            var templates = await _templateService.GetAllTemplatesAsync();
            model.Templates = templates.Select(t => new SelectListItem
            {
                Value = t.Id.ToString(),
                Text = t.Name
            }).ToList();

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                var success = await _emailService.SendEmailAsync(
                    model.ToEmail,
                    model.Subject,
                    model.EmailContent,
                    model.FromEmail,
                    model.TemplateId);

                if (success)
                {
                    TempData["SuccessMessage"] = "Email sent successfully!";
                    return RedirectToAction(nameof(History));
                }
                else
                {
                    ModelState.AddModelError("", "Failed to send email. Please check your email configuration.");
                }
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error sending email: {ex.Message}");
            }

            return View(model);
        }

        public async Task<IActionResult> History(int page = 1, int pageSize = 10)
        {
            var emailLogs = await _emailService.GetEmailHistoryAsync(page, pageSize);
            var totalCount = await _emailService.GetEmailCountAsync();

            var viewModel = new EmailHistoryViewModel
            {
                EmailLogs = emailLogs.ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            };

            return View(viewModel);
        }

        // Add other actions as needed
    }
}
```

### A6. Area View Configuration

You have several options for layout configuration:

#### Option 1: Use Main Project Layout (Recommended)

Create `Areas/EmailTemplates/Views/_ViewStart.cshtml`:

```html
@{
    Layout = "~/Views/Shared/_Layout.cshtml";  // Points to main project layout
}
```

#### Option 2: Use Different Layout for Area

Create `Areas/EmailTemplates/Views/_ViewStart.cshtml`:

```html
@{
    Layout = "~/Areas/EmailTemplates/Views/Shared/_EmailTemplateLayout.cshtml";  // Custom area layout
}
```

#### Option 3: Dynamic Layout Selection

Create `Areas/EmailTemplates/Views/_ViewStart.cshtml`:

```html
@{
    // Use main layout for most views, custom for specific ones
    var controller = ViewContext.RouteData.Values["controller"]?.ToString();
    var action = ViewContext.RouteData.Values["action"]?.ToString();
    
    if (controller == "Email" && action == "Send")
    {
        Layout = "~/Areas/EmailTemplates/Views/Shared/_EmailEditorLayout.cshtml";
    }
    else
    {
        Layout = "~/Views/Shared/_Layout.cshtml";  // Main project layout
    }
}
```

#### Option 4: No Area-Specific _ViewStart (Use Controller-Level Layout)

Don't create `Areas/EmailTemplates/Views/_ViewStart.cshtml` and instead specify layout in each controller action:

```csharp
namespace YourApp.Areas.EmailTemplates.Controllers
{
    [Area("EmailTemplates")]
    public class TemplateController : Controller
    {
        public async Task<IActionResult> Index()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            
            // Specify layout directly in the view result
            ViewData["Layout"] = "~/Views/Shared/_Layout.cshtml";
            
            return View(templates);
        }
        
        // Or set layout for all actions in this controller
        public override ViewResult View(string viewName, object model)
        {
            ViewData["Layout"] = "~/Views/Shared/_Layout.cshtml";
            return base.View(viewName, model);
        }
    }
}
```

#### Option 5: Individual View Layout Override

In any specific view file (e.g., `Areas/EmailTemplates/Views/Template/Index.cshtml`):

```html
@{
    Layout = "~/Views/Shared/_Layout.cshtml";  // Override for this specific view
}

@model IEnumerable<Template>

<h2>Email Templates</h2>
<!-- View content -->
```

### Advanced Layout Configuration

#### Making Navigation Context-Aware

Update your main layout (`Views/Shared/_Layout.cshtml`) to highlight the Email Templates section when users are in that area:

```html
<!-- In your main layout navigation -->
@{
    var area = ViewContext.RouteData.Values["area"]?.ToString();
    var controller = ViewContext.RouteData.Values["controller"]?.ToString();
    var isEmailTemplatesArea = area == "EmailTemplates";
}

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <!-- Other nav items -->
        
        <li class="nav-item dropdown @(isEmailTemplatesArea ? "active" : "")">
            <a class="nav-link dropdown-toggle" href="#" id="emailDropdown" role="button" data-bs-toggle="dropdown">
                Email Templates
            </a>
            <ul class="dropdown-menu">
                <li><a class="dropdown-item @(isEmailTemplatesArea && controller == "Template" ? "active" : "")" 
                       asp-area="EmailTemplates" asp-controller="Template" asp-action="Index">Manage Templates</a></li>
                <li><a class="dropdown-item @(isEmailTemplatesArea && controller == "Template" ? "active" : "")" 
                       asp-area="EmailTemplates" asp-controller="Template" asp-action="Upload">Create Template</a></li>
                <li><a class="dropdown-item @(isEmailTemplatesArea && controller == "Email" ? "active" : "")" 
                       asp-area="EmailTemplates" asp-controller="Email" asp-action="Send">Send Email</a></li>
                <li><a class="dropdown-item @(isEmailTemplatesArea && controller == "Email" ? "active" : "")" 
                       asp-area="EmailTemplates" asp-controller="Email" asp-action="History">Email History</a></li>
            </ul>
        </li>
    </div>
</nav>
```

#### Adding Breadcrumbs

Add breadcrumb support to your main layout for better navigation:

```html
<!-- In your main layout, after navigation -->
@if (ViewContext.RouteData.Values["area"] != null)
{
    <nav aria-label="breadcrumb" class="container mt-3">
        <ol class="breadcrumb">
            <li class="breadcrumb-item">
                <a asp-controller="Home" asp-action="Index" asp-area="">Home</a>
            </li>
            
            @{
                var area = ViewContext.RouteData.Values["area"]?.ToString();
                var controller = ViewContext.RouteData.Values["controller"]?.ToString();
                var action = ViewContext.RouteData.Values["action"]?.ToString();
            }
            
            @if (area == "EmailTemplates")
            {
                <li class="breadcrumb-item">
                    <a asp-area="EmailTemplates" asp-controller="Template" asp-action="Index">Email Templates</a>
                </li>
                
                @if (controller == "Template")
                {
                    <li class="breadcrumb-item">
                        <a asp-area="EmailTemplates" asp-controller="Template" asp-action="Index">Templates</a>
                    </li>
                    @switch (action)
                    {
                        case "Upload":
                            <li class="breadcrumb-item active">Create Template</li>
                            break;
                        case "Details":
                            <li class="breadcrumb-item active">Template Details</li>
                            break;
                        case "Edit":
                            <li class="breadcrumb-item active">Edit Template</li>
                            break;
                        default:
                            <li class="breadcrumb-item active">@action</li>
                            break;
                    }
                }
                else if (controller == "Email")
                {
                    <li class="breadcrumb-item">
                        <a asp-area="EmailTemplates" asp-controller="Email" asp-action="Send">Email</a>
                    </li>
                    @switch (action)
                    {
                        case "Send":
                            <li class="breadcrumb-item active">Send Email</li>
                            break;
                        case "History":
                            <li class="breadcrumb-item active">Email History</li>
                            break;
                        default:
                            <li class="breadcrumb-item active">@action</li>
                            break;
                    }
                }
            }
        </ol>
    </nav>
}
```

#### Page Title Management

Update your main layout to handle area-specific page titles:

```html
<!-- In your main layout head section -->
<title>
    @{
        var area = ViewContext.RouteData.Values["area"]?.ToString();
        var controller = ViewContext.RouteData.Values["controller"]?.ToString();
        var action = ViewContext.RouteData.Values["action"]?.ToString();
        
        string pageTitle = ViewData["Title"]?.ToString() ?? "";
        
        if (area == "EmailTemplates")
        {
            pageTitle = $"{pageTitle} - Email Templates";
        }
        
        pageTitle = $"{pageTitle} - Your App Name";
    }
    @pageTitle
</title>
```

#### CSS and JavaScript for Email Template Area

You can add area-specific styles and scripts in your main layout:

```html
<!-- In your main layout head section -->
@if (ViewContext.RouteData.Values["area"]?.ToString() == "EmailTemplates")
{
    <link rel="stylesheet" href="~/css/email-templates.css" />
    <script src="https://cdn.ckeditor.com/ckeditor5/39.0.1/classic/ckeditor.js"></script>
}

<!-- Before closing body tag -->
@if (ViewContext.RouteData.Values["area"]?.ToString() == "EmailTemplates")
{
    <script src="~/js/email-templates.js"></script>
}
```

#### Alternative: Section-Based Approach

If you prefer more control, use sections in your area views:

```html
<!-- In your area view (e.g., Template/Upload.cshtml) -->
@{
    Layout = "~/Views/Shared/_Layout.cshtml";
    ViewData["Title"] = "Create Email Template";
}

@section Styles {
    <link rel="stylesheet" href="~/css/email-templates.css" />
    <script src="https://cdn.ckeditor.com/ckeditor5/39.0.1/classic/ckeditor.js"></script>
}

@section Scripts {
    <script src="~/js/email-templates.js"></script>
}

<!-- View content -->
<h2>Create Email Template</h2>
<!-- ... -->
```

And in your main layout, render these sections:

```html
<!-- In main layout head -->
@await RenderSectionAsync("Styles", required: false)

<!-- Before closing body tag -->
@await RenderSectionAsync("Scripts", required: false)
```

### A7. Navigation for Area

Add navigation links to your main layout that point to the area:

```html
<li class="nav-item dropdown">
    <a class="nav-link dropdown-toggle" href="#" id="emailDropdown" role="button" data-bs-toggle="dropdown">
        Email Templates
    </a>
    <ul class="dropdown-menu">
        <li><a class="dropdown-item" asp-area="EmailTemplates" asp-controller="Template" asp-action="Index">Manage Templates</a></li>
        <li><a class="dropdown-item" asp-area="EmailTemplates" asp-controller="Template" asp-action="Upload">Create Template</a></li>
        <li><a class="dropdown-item" asp-area="EmailTemplates" asp-controller="Email" asp-action="Send">Send Email</a></li>
        <li><a class="dropdown-item" asp-area="EmailTemplates" asp-controller="Email" asp-action="History">Email History</a></li>
    </ul>
</li>
```

### A8. URL Structure

With the area implementation, your URLs will be:
- `/EmailTemplates/Template/Index` - Template management
- `/EmailTemplates/Template/Upload` - Create template
- `/EmailTemplates/Email/Send` - Send email
- `/EmailTemplates/Email/History` - Email history

---

## Option B: Direct Integration (Alternative)

If you prefer to integrate directly into your main application without using areas:

### B1. Install Required NuGet Packages

Add the following packages to your existing project:

```xml
<PackageReference Include="DocumentFormat.OpenXml" Version="3.3.0" />
<PackageReference Include="MailKit" Version="4.13.0" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.8" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.8">
  <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
  <PrivateAssets>all</PrivateAssets>
</PackageReference>
<PackageReference Include="OpenXmlPowerTools" Version="4.5.3.2" />
```

### B2. Controllers (Direct Integration)

Create controllers in your main `Controllers` folder without the `[Area]` attribute:

```csharp
using Microsoft.AspNetCore.Mvc;
using YourApp.Models;
using YourApp.Services;

namespace YourApp.Controllers
{
    public class TemplateController : Controller
    {
        // Same implementation as Area version but without [Area("EmailTemplates")]
        private readonly ITemplateService _templateService;

        public TemplateController(ITemplateService templateService)
        {
            _templateService = templateService;
        }

        public async Task<IActionResult> Index()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            return View(templates);
        }

        public IActionResult Upload()
        {
            return View(new UploadTemplateViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(UploadTemplateViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                // Check if template name already exists
                if (await _templateService.TemplateExistsAsync(model.Name))
                {
                    ModelState.AddModelError("Name", "A template with this name already exists.");
                    return View(model);
                }

                Template template;
                
                if (model.CreationMethod == "file" && model.WordFile != null)
                {
                    template = await _templateService.CreateTemplateFromFileAsync(
                        model.Name, model.WordFile, model.Description);
                }
                else if (model.CreationMethod == "html" && !string.IsNullOrEmpty(model.HtmlContent))
                {
                    template = await _templateService.CreateTemplateFromHtmlAsync(
                        model.Name, model.HtmlContent, model.Description);
                }
                else
                {
                    ModelState.AddModelError("", "Please provide either a Word file or HTML content.");
                    return View(model);
                }

                TempData["SuccessMessage"] = "Template created successfully!";
                return RedirectToAction(nameof(Details), new { id = template.Id });
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error creating template: {ex.Message}");
                return View(model);
            }
        }

        public async Task<IActionResult> Details(int id)
        {
            var template = await _templateService.GetTemplateByIdAsync(id);
            if (template == null)
            {
                return NotFound();
            }

            var variables = await _templateService.ExtractVariablesFromTemplateAsync(id);
            var viewModel = new TemplateDetailsViewModel
            {
                Template = template,
                Variables = variables
            };

            return View(viewModel);
        }

        // Add other actions: Edit, Delete, Preview
        // (Copy implementations from the original EmailTemplateManager project)
    }
}
```

#### EmailController.cs
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using YourApp.Models;
using YourApp.Services;

namespace YourApp.Controllers
{
    public class EmailController : Controller
    {
        private readonly IEmailService _emailService;
        private readonly ITemplateService _templateService;

        public EmailController(IEmailService emailService, ITemplateService templateService)
        {
            _emailService = emailService;
            _templateService = templateService;
        }

        public async Task<IActionResult> Send()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            var viewModel = new SendEmailViewModel
            {
                Templates = templates.Select(t => new SelectListItem
                {
                    Value = t.Id.ToString(),
                    Text = t.Name
                }).ToList()
            };

            return View(viewModel);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Send(SendEmailViewModel model)
        {
            // Reload templates for the dropdown
            var templates = await _templateService.GetAllTemplatesAsync();
            model.Templates = templates.Select(t => new SelectListItem
            {
                Value = t.Id.ToString(),
                Text = t.Name
            }).ToList();

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                var success = await _emailService.SendEmailAsync(
                    model.ToEmail,
                    model.Subject,
                    model.EmailContent,
                    model.FromEmail,
                    model.TemplateId);

                if (success)
                {
                    TempData["SuccessMessage"] = "Email sent successfully!";
                    return RedirectToAction(nameof(History));
                }
                else
                {
                    ModelState.AddModelError("", "Failed to send email. Please check your email configuration.");
                }
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error sending email: {ex.Message}");
            }

            return View(model);
        }

        public async Task<IActionResult> History(int page = 1, int pageSize = 10)
        {
            var emailLogs = await _emailService.GetEmailHistoryAsync(page, pageSize);
            var totalCount = await _emailService.GetEmailCountAsync();

            var viewModel = new EmailHistoryViewModel
            {
                EmailLogs = emailLogs.ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            };

            return View(viewModel);
        }

        // Add other actions as needed
    }
}
```

### B3. Views (Direct Integration)

Place views in the standard `Views` folder structure:
- `Views/Template/Index.cshtml`
- `Views/Template/Upload.cshtml`
- `Views/Email/Send.cshtml`
- etc.

### B4. Navigation (Direct Integration)

```html
<li class="nav-item dropdown">
    <a class="nav-link dropdown-toggle" href="#" id="emailDropdown" role="button" data-bs-toggle="dropdown">
        Email Templates
    </a>
    <ul class="dropdown-menu">
        <li><a class="dropdown-item" asp-controller="Template" asp-action="Index">Manage Templates</a></li>
        <li><a class="dropdown-item" asp-controller="Template" asp-action="Upload">Create Template</a></li>
        <li><a class="dropdown-item" asp-controller="Email" asp-action="Send">Send Email</a></li>
        <li><a class="dropdown-item" asp-controller="Email" asp-action="History">Email History</a></li>
    </ul>
</li>
```

---

## Common Steps for Both Options

The following steps apply to both Area and Direct integration approaches:

### 3. Database Context

Add the email template entities to your existing DbContext or create a new one:

```csharp
using Microsoft.EntityFrameworkCore;
using YourApp.Models;

namespace YourApp.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }
        
        // Add these DbSets to your existing context
        public DbSet<Template> Templates { get; set; }
        public DbSet<EmailLog> EmailLogs { get; set; }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Configure Template entity
            modelBuilder.Entity<Template>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
                entity.Property(e => e.HtmlContent).IsRequired();
                entity.Property(e => e.CreatedAt).IsRequired();
                entity.HasIndex(e => e.Name).IsUnique();
            });
            
            // Configure EmailLog entity
            modelBuilder.Entity<EmailLog>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.ToEmail).IsRequired().HasMaxLength(255);
                entity.Property(e => e.Subject).IsRequired().HasMaxLength(500);
                entity.Property(e => e.Body).IsRequired();
                entity.Property(e => e.SentAt).IsRequired();
                
                // Configure relationship
                entity.HasOne(e => e.Template)
                      .WithMany(t => t.EmailLogs)
                      .HasForeignKey(e => e.TemplateId)
                      .OnDelete(DeleteBehavior.SetNull);
            });
        }
    }
}
```

### 4. Service Interfaces

Create service interfaces in a `Services` folder:

#### ITemplateService.cs
```csharp
using YourApp.Models;

namespace YourApp.Services
{
    public interface ITemplateService
    {
        Task<IEnumerable<Template>> GetAllTemplatesAsync();
        Task<Template?> GetTemplateByIdAsync(int id);
        Task<Template> CreateTemplateAsync(string name, string htmlContent, string? description = null);
        Task<Template> CreateTemplateFromFileAsync(string name, IFormFile file, string? description = null);
        Task<Template> CreateTemplateFromHtmlAsync(string name, string htmlContent, string? description = null);
        Task<Template> UpdateTemplateAsync(int id, string name, string htmlContent, string? description = null);
        Task<bool> DeleteTemplateAsync(int id);
        Task<bool> TemplateExistsAsync(string name, int? excludeId = null);
        Task<List<string>> ExtractVariablesFromTemplateAsync(int templateId);
        Task<string> PopulateTemplateAsync(int templateId, Dictionary<string, string> variables);
    }
}
```

#### IEmailService.cs
```csharp
using YourApp.Models;

namespace YourApp.Services
{
    public interface IEmailService
    {
        Task<bool> SendEmailAsync(string toEmail, string subject, string body, string? fromEmail = null, int? templateId = null);
        Task<IEnumerable<EmailLog>> GetEmailHistoryAsync(int page = 1, int pageSize = 10);
        Task<EmailLog?> GetEmailLogByIdAsync(int id);
        Task<int> GetEmailCountAsync();
    }
}
```

#### IWordToHtmlService.cs
```csharp
namespace YourApp.Services
{
    public interface IWordToHtmlService
    {
        Task<string> ConvertWordToHtmlAsync(IFormFile wordFile);
        Task<string> ConvertWordToHtmlAsync(Stream wordStream);
        bool IsValidWordFile(IFormFile file);
    }
}
```

### 5. Service Implementations

Create the service implementations (refer to the existing service files in the EmailTemplateManager project for complete implementations).

### 6. Configure Services in Program.cs

Add the following to your `Program.cs`:

```csharp
// Add Entity Framework
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add Email Template Services
builder.Services.AddScoped<ITemplateService, TemplateService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IWordToHtmlService, WordToHtmlService>();

// Configure file upload limits
builder.Services.Configure<IISServerOptions>(options =>
{
    options.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 10 * 1024 * 1024; // 10MB
});
```

### 7. Configuration Settings

Add email configuration to your `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=YourAppDb;Trusted_Connection=true;MultipleActiveResultSets=true"
  },
  "EmailSettings": {
    "SmtpHost": "smtp.gmail.com",
    "SmtpPort": 587,
    "FromEmail": "your-email@gmail.com",
    "FromName": "Your App Name",
    "Username": "your-email@gmail.com",
    "Password": "your-app-password",
    "EnableSsl": true
  }
}
```

### 8. Controllers

Create the controllers (refer to `TemplateController.cs` and `EmailController.cs` in the EmailTemplateManager project).

### 9. Views

Copy the following view files from the EmailTemplateManager project to your application:

- `Views/Template/Index.cshtml`
- `Views/Template/Upload.cshtml`
- `Views/Template/Details.cshtml`
- `Views/Template/Edit.cshtml`
- `Views/Template/Preview.cshtml`
- `Views/Email/Send.cshtml`
- `Views/Email/History.cshtml`
- `Views/Email/Details.cshtml`

### 10. Navigation

Add navigation links to your layout or menu:

```html
<li class="nav-item dropdown">
    <a class="nav-link dropdown-toggle" href="#" id="emailDropdown" role="button" data-bs-toggle="dropdown">
        Email Templates
    </a>
    <ul class="dropdown-menu">
        <li><a class="dropdown-item" asp-controller="Template" asp-action="Index">Manage Templates</a></li>
        <li><a class="dropdown-item" asp-controller="Template" asp-action="Upload">Create Template</a></li>
        <li><a class="dropdown-item" asp-controller="Email" asp-action="Send">Send Email</a></li>
        <li><a class="dropdown-item" asp-controller="Email" asp-action="History">Email History</a></li>
    </ul>
</li>
```

### 11. Database Migration

You have multiple options for setting up the database:

#### Option 1: Using Entity Framework Migrations (Recommended for EF projects)
```bash
# Add migration
dotnet ef migrations add AddEmailTemplates

# Update database
dotnet ef database update
```

#### Option 2: Using SQL Scripts (Recommended for non-EF projects or manual setup)

I've created comprehensive SQL scripts for database setup:

**For New Database:**
```bash
# Execute scripts in order:
1. Database/01_CreateDatabase.sql
2. Database/02_CreateTables.sql  
3. Database/03_SampleData.sql (optional)
```

**For Existing Database:**
```bash
# Execute this single script:
Database/04_EFMigrationEquivalent.sql
```

**Automated Setup:**
```powershell
# PowerShell (recommended)
.\Database\Setup-EmailTemplateDatabase.ps1

# Or Batch file
.\Database\Setup-EmailTemplateDatabase.bat
```

The database scripts include:
- ✅ Complete table creation with proper indexes
- ✅ Foreign key constraints and relationships  
- ✅ Performance-optimized indexes
- ✅ Views for common queries
- ✅ Stored procedures for maintenance
- ✅ Sample templates (Welcome, Password Reset, Order Confirmation, Newsletter)
- ✅ Maintenance and cleanup scripts
- ✅ Backup and monitoring utilities

#### Database Features:
- **Templates Table**: Stores HTML email templates with metadata
- **EmailLogs Table**: Tracks all sent emails with success/failure status
- **Optimized Indexes**: For high-performance queries
- **Sample Data**: 4 production-ready email templates
- **Maintenance Tools**: Automated cleanup and monitoring

### 12. Benefits of Using Areas

When using the Area approach (Option A), you get:

1. **Better Organization**: Email template functionality is clearly separated from your main application
2. **Modular Structure**: Easy to maintain, update, or remove the email template module
3. **Clean URLs**: Clear URL structure like `/EmailTemplates/Template/Index`
4. **Namespace Separation**: Controllers are in their own namespace
5. **Scalability**: Easy to add more areas for other features
6. **Team Development**: Different teams can work on different areas independently

### 13. File Structure Comparison

**With Areas:**
```
Areas/
  EmailTemplates/
    Controllers/
      TemplateController.cs
      EmailController.cs
    Views/
      Template/
        Index.cshtml
        Upload.cshtml
      Email/
        Send.cshtml
```

**Without Areas:**
```
Controllers/
  TemplateController.cs
  EmailController.cs
Views/
  Template/
    Index.cshtml
    Upload.cshtml
  Email/
    Send.cshtml
```

### 14. Static Files and Assets

The views use CKEditor 5 via CDN, so no additional static files are required. However, you may want to add custom CSS for styling.

## Security Considerations

1. **File Upload Validation**: The system validates file types and sizes
2. **Email Configuration**: Store sensitive email credentials securely (consider Azure Key Vault)
3. **Input Sanitization**: Template content is HTML-encoded where appropriate
4. **Authorization**: Add [Authorize] attributes to controllers as needed

## Customization Options

1. **Styling**: Customize the CSS to match your application's theme
2. **Template Variables**: Extend the variable system for more complex scenarios
3. **Email Providers**: Replace MailKit with other email services if needed
4. **File Storage**: Implement file storage for uploaded Word documents if needed
5. **Rich Editor**: CKEditor 5 is used, but you can replace it with other editors

## Testing

1. Test Word document upload and conversion
2. Test HTML template creation with CKEditor 5
3. Test email sending with variable substitution
4. Test template management (CRUD operations)
5. Verify email history tracking

## Troubleshooting

1. **File Upload Issues**: Check file size limits and temporary folder permissions
2. **Email Sending Issues**: Verify SMTP configuration and credentials
3. **Database Issues**: Ensure connection string is correct and database is accessible
4. **Word Conversion Issues**: Verify DocumentFormat.OpenXml package is properly installed

## Next Steps

After integration:
1. Configure your email SMTP settings
2. Create your first template
3. Test email sending functionality
4. Customize the UI to match your application's design
5. Add any additional business logic or validation rules

This integration provides a complete email template management system that can be easily incorporated into any .NET 8 Core application.
