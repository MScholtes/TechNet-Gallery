// Markus Scholtes, 2017
// WPF "all in one file" Demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Program to execute button functions
// Since inheritance in the XAML string does not work with XamlReader, the event have to be added afterwards
// and defined as "static" funktions of the program


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "03 Button.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "03 Button.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.Xml;
using System.Windows;
using System.Windows.Input;
using System.Windows.Markup;

public class Programm
{
	// helper function, that seeks the parent object tree "upwards" starting by any control until the root Window object is found
	private static FrameworkElement FindParentWindow(object sender)
	{
		FrameworkElement GUIControl = (FrameworkElement)sender;
		while ((GUIControl.Parent != null) && (GUIControl.GetType() != typeof(System.Windows.Window)))
		{
			GUIControl = (FrameworkElement)GUIControl.Parent;
		}

		if (GUIControl.GetType() == typeof(System.Windows.Window))
		  return GUIControl;
		else
			return null;
	}

	// since inheritance of Window does not work, the eventhandler have to be static methods and added after genreation of the Window object

	// linker Mausklick
	private static void Button_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
	{
		// event is handled now
		e.Handled = true;
		// retrieve Window parent object
		Window objWindow = (Window)FindParentWindow(sender);
		// if found then close window
		if (objWindow != null) { objWindow.Close(); }
	}

	// right mouseclick
	private static void Button_MouseRightButtonUp(object sender, MouseButtonEventArgs e)
	{
		// set background color to green
		((System.Windows.Controls.Button)sender).Background = System.Windows.Media.Brushes.Green;
	}

	// does mouse move into button area?
	private static void Button_MouseEnter(object sender, MouseEventArgs e)
	{
		// retrieve Window parent object
		Window objWindow = (Window)FindParentWindow(sender);
		// if found then change mouse cursor
		if (objWindow != null) { objWindow.Cursor = System.Windows.Input.Cursors.Hand; }
	}

	// does mouse move out of button area?
	private static void Button_MouseLeave(object sender, MouseEventArgs e)
	{
		// retrieve Window parent object
		Window objWindow = (Window)FindParentWindow(sender);
		// if found then change mouse cursor
		if (objWindow != null) { objWindow.Cursor = System.Windows.Input.Cursors.Arrow; }
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
	Width = ""800"" Height = ""400"" ShowInTaskbar = ""True"">
	<Grid>
		<Grid.RowDefinitions>
			<RowDefinition Height=""auto""></RowDefinition>
			<RowDefinition Height=""150""></RowDefinition>
		</Grid.RowDefinitions>
		<TextBlock TextAlignment=""Center"" Foreground=""Black"" FontSize=""40"" HorizontalAlignment=""Center"" Grid.Row=""0"" Grid.Column=""0"" >
	  	<TextBlock.Effect><DropShadowEffect ShadowDepth=""4"" Color=""DarkGray"" BlurRadius=""4""/></TextBlock.Effect>
			<LineBreak/>Test program for <LineBreak/><LineBreak/>Windows Presentation Framework
		</TextBlock>
		<Button x:Name=""Knopf"" Height=""24"" Width=""72"" Content=""Click me"" ToolTip=""Left click exits program, right click makes button green"" Grid.Row=""1"" Grid.Column=""0"" />
	</Grid>
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

		// search button object in WPF tree
		System.Windows.Controls.Button objButton = (System.Windows.Controls.Button)objWindow.FindName("Knopf");

		// add eventhandler (the last parameter false means, that the handler is not called, when an event is already handled)
		objButton.AddHandler(FrameworkElement.MouseLeftButtonUpEvent, new MouseButtonEventHandler(Button_MouseLeftButtonUp), true);
		objButton.AddHandler(FrameworkElement.MouseRightButtonUpEvent, new MouseButtonEventHandler(Button_MouseRightButtonUp), false);
		objButton.MouseEnter += Button_MouseEnter;
		objButton.MouseLeave += Button_MouseLeave;

		// and show WPF window
		objWindow.ShowDialog();
	}
}
