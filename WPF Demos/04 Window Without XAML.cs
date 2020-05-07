// Markus Scholtes, 2017
// WPF "all in one file" Demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Minimal WPF program without XAML: a window with text


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "04 Window Without XAML.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "04 Window Without XAML.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

// Program derived from Application
class Program : Application
{
	// the WPF objects that have to be generated in code
	Window objWindow;
	TextBlock objTextBlock;
	System.Windows.Media.Effects.DropShadowEffect objEffect;

	// on start of the Application windows is generated and shown
	protected override void OnStartup(StartupEventArgs args)
	{
		// call original OnStartup routine
		base.OnStartup(args);

		// generate WPF class Window
		objWindow = new Window();
		// and set properties
		objWindow.Title = "Test program for Windows Presentation Framework";
		objWindow.WindowStartupLocation = WindowStartupLocation.CenterScreen;
		objWindow.Width = 800;
		objWindow.Height = 600;
		objWindow.ShowInTaskbar = true;
		objWindow.AddHandler(FrameworkElement.KeyDownEvent, new KeyEventHandler(Window_KeyDown), false);

		// generate Textblock class
		objTextBlock = new TextBlock();
		// and set properties
		objTextBlock.TextAlignment = TextAlignment.Center;
		objTextBlock.HorizontalAlignment = HorizontalAlignment.Center;
		objTextBlock.VerticalAlignment = VerticalAlignment.Center;
		objTextBlock.Foreground = Brushes.Black;
		objTextBlock.FontSize = 40;
		objTextBlock.Text = "Test program for \n\nWindows Presentation Framework";

		// generate effect object for the Textblock class
		objEffect = new System.Windows.Media.Effects.DropShadowEffect();
		// and set properties
		objEffect.ShadowDepth = 4;
		objEffect.Color = (Color)ColorConverter.ConvertFromString("DarkGray");
		objEffect.BlurRadius = 4;

		// assign Effect to Textblock
		objTextBlock.Effect = objEffect;

		// assign Textblock to Window
		objWindow.Content = objTextBlock;

		// show windows (in opposite to ShowDialog() Show() does not wait for closing of the window)
		objWindow.Show();
	}

	// keyboard is pressed
	private static void Window_KeyDown(object sender, KeyEventArgs e)
	{
		if (System.Windows.Input.Keyboard.IsKeyDown(System.Windows.Input.Key.LeftAlt) && System.Windows.Input.Keyboard.IsKeyDown(System.Windows.Input.Key.X))
		{
			// event is handled now
			e.Handled = true;
			// the sender object is the object that generated the event
			((Window)sender).Close();
		}
	}

	// WPF requires STA model. Since C# uses MTA as default, the following compiler directive is required
	[STAThread]
	static void Main()
	{
		// generate new Program (= modified Application object)
		new Program().Run();
	}
}
