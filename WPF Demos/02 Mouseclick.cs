// Markus Scholtes, 2017
// WPF "all in one file" demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Program to execute mouse functions and to query the keyboard
// Since inheritance in the XAML string does not work with XamlReader, the event have to be added afterwards
// and defined as "static" funktions of the program


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "02 Mouseclick.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "02 Mouseclick.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.Xml;
using System.Windows;
using System.Windows.Input;
using System.Windows.Markup;


public class Programm
{
	// since inheritance of Window does not work, the eventhandler have to be static methods and added after generation of the Window object

	// right mouseclick
	private static void Window_MouseRightButtonUp(object sender, MouseButtonEventArgs e)
	{
		// event is handled now
		e.Handled = true;
		// the sender object is the object that generated the event
		((Window)sender).Close();
	}

	// left mouseclick
	private static void Window_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
	{
		// the sender object is the object that generated the event
		// we use this to seek Textblock
		System.Windows.Controls.TextBlock objText = (System.Windows.Controls.TextBlock)((Window)sender).FindName("Text");
		// change text of Textblock
		objText.Text = "Left mouse button was pressed.\n\nRight mouse button (or Alt-X)\n\ncloses the window.";
		// allow "move window" per drag with left mouse button
		((Window)sender).DragMove();
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
	public static void Main()
	{

		// XAML string that defines the WPF controls
		string strXAML = @"
<Window
	xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
	xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
	x:Name=""Window"" Title=""Test program for Windows Presentation Framework"" WindowStartupLocation = ""CenterScreen""
	Width = ""800"" Height = ""600"" ShowInTaskbar = ""True"">
	<TextBlock Name=""Text"" TextAlignment=""Center"" VerticalAlignment=""Center"" Foreground=""Black"" FontSize=""40"" HorizontalAlignment=""Center"">
	  <TextBlock.Effect><DropShadowEffect ShadowDepth=""4"" Color=""DarkGray"" BlurRadius=""4""/></TextBlock.Effect>
		Test program for<LineBreak/><LineBreak/>Windows Presentation Framework
	</TextBlock>
</Window>";

		// prepare XML document
		XmlDocument XAML = new XmlDocument();
		// read XAML string
		XAML.LoadXml(strXAML);
		// and convert to XML
		XmlNodeReader XMLReader = new XmlNodeReader(XAML);
		// generate WPF object tree
		Window objWindow;
		try
		{	// set XAML root object
			objWindow = (Window)XamlReader.Load(XMLReader);
		}
		catch
		{ // XamlReader generates an exception on error in XAML definition
			MessageBox.Show("Error while creating the WPF controls out of the XAML description", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
			return;
		}

		// add eventhandler (the last parameter false means, that the handler is not called, when an event is already handled)
		objWindow.AddHandler(FrameworkElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler(Window_MouseLeftButtonDown), false);
		objWindow.AddHandler(FrameworkElement.MouseRightButtonUpEvent, new MouseButtonEventHandler(Window_MouseRightButtonUp), false);
		objWindow.AddHandler(FrameworkElement.KeyDownEvent, new KeyEventHandler(Window_KeyDown), false);

		// define Tooltip for the window
		objWindow.ToolTip = "Please press mouse button.";

		// and show WPF window
		objWindow.ShowDialog();
	}
}
