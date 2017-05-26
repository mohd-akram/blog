---
title: Rendering a View to a String in ASP.NET Core
---

First, add `ICompositeViewEngine` to your controller:

``` csharp
// You'll need these
using System.IO;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Mvc.ViewEngines;
using Microsoft.AspNetCore.Mvc.ViewFeatures;

public class MyController : Controller
{
    private readonly ICompositeViewEngine _viewEngine;

    public MyController(ICompositeViewEngine viewEngine)
    {
        _viewEngine = viewEngine;
    }
}
```

Then, add the following method:

```csharp
public async Task<string> RenderView([CallerMemberName] string viewName = null)
{
    var view = _viewEngine.FindView(ControllerContext, viewName, true).View;

    var writer = new StringWriter();

    var viewContext = new ViewContext(
        ControllerContext, view, ViewData,
        TempData, writer, new HtmlHelperOptions()
    );

    await view.RenderAsync(viewContext);

    return writer.ToString();
}
```

You can now call `await RenderView()` and it will return your rendered view as
a string.
