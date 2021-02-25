/* Compile: valac main.vala tflite.vapi --pkg gtk+-3.0 -X -ltensorflowlite_c */

class CanvasWidget : Gtk.DrawingArea
{
	private Array<Array<Gdk.Point?>> paths = new Array<Array<Gdk.Point?>>();
	private bool is_drawing;

	public signal void changed();

	construct {
		this.set_size_request(400, 400);
		this.expand = true;

		this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK);

		this.button_press_event.connect ((event) => {
			this.is_drawing = true;
			this.paths.append_val(new Array<Gdk.Point?>());
			return true;
		});

		this.button_release_event.connect(() => {
			this.is_drawing = false;
			// this.changed();
			return true;
		});

		this.motion_notify_event.connect((event) => {
			if (this.is_drawing)
			{
				this.paths.data[this.paths.length - 1].append_val(Gdk.Point() { x = (int) event.x, y = (int) event.y});
				this.queue_draw();
				this.changed();
			}
		});
	}

	public override bool draw(Cairo.Context cr)
	{
		cr.set_source_rgb(0xff, 0xff, 0xff);
		cr.rectangle(0, 0, 400, 400);
		cr.fill();

		cr.set_line_cap(Cairo.LineCap.ROUND);
		cr.set_line_join(Cairo.LineJoin.ROUND);
		cr.set_line_width(40);
		cr.set_source_rgb(0, 0, 0);

		for (int p = 0; p < this.paths.length; p++)
		{
			var path = this.paths.data[p];

			for (int q = 0; q < path.length; q++)
			{
				var point = path.data[q];

				if (q == 0)
					cr.move_to(point.x, point.y);
				else
					cr.line_to(point.x, point.y);
			}

			cr.stroke();
		}

		return true;
	}

	public Gdk.Pixbuf get_image()
	{
		var surface = new Cairo.ImageSurface(Cairo.Format.RGB24, 400, 400);
		var context = new Cairo.Context(surface);

		this.draw(context);

		return Gdk.pixbuf_get_from_surface(surface, 0, 0, 400, 400);
	}

	public void clear()
	{
		this.paths.remove_range(0, this.paths.length);
		this.queue_draw();
		this.changed();
	}
}

class DemoWindow : Gtk.Window
{
	Gtk.Button[] number_buttons = new Gtk.Button[10];
	CanvasWidget canvas;

	TFLite.Interpreter? intrp = null;

	Gtk.CssProvider custom_style = new Gtk.CssProvider();

	public DemoWindow()
	{
		this.destroy.connect(Gtk.main_quit);
		this.build_ui();

		Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), this.custom_style, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	}

	private void build_ui()
	{
		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 16) {
			margin = 12
		};
		this.add(vbox);

		/* Build headerbar */

		var hb = new Gtk.HeaderBar() {
			title = "TensorFlow demo",
			show_close_button = true
		};

		this.set_titlebar(hb);

		var clear_button = new Gtk.Button.with_label("Clear");
		clear_button.clicked.connect(() => {
			this.canvas.clear();
		});
		hb.add(clear_button);

		/* Build canvas */
		this.canvas = new CanvasWidget();
		this.canvas.changed.connect(() => {
			this.predict();
		});
		vbox.add(this.canvas);

		/* Create indicators */

		var grid = new Gtk.Grid() {
			row_spacing = 12,
			column_spacing = 12,
			hexpand = true,
			column_homogeneous = true
		};
		vbox.add(grid);

		for (int i = 0; i < 10; i++)
		{
			Gtk.Button button = new Gtk.Button() {
				label = (@"$i"),
				name  = (@"label-$i"),		// Used to refer to the button in CSS
				halign = Gtk.Align.CENTER
			};
			button.get_style_context().add_class("circular");
			button.button_press_event.connect(() => { return true; });

			grid.attach(button, i % 5, i / 5);
			this.number_buttons[i] = button;
		}
	}

	public void load_model()
	{
		var model = TFLite.Model.from_file("mnist.tflite"); // warning: can be null

		if (model != null)
		{
			this.intrp = new TFLite.Interpreter(model, null);
			this.intrp.allocate_tensors();

			/* Check the model takes the format we want. */
			assert(intrp.get_input_tensor(0).type == TFLite.TensorType.Float32);
		}
		else
		{
			var dialog = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, null) {
				text = "Error loading model",
				secondary_text = "A problem occured whilst loading the TensorFlow Lite model."
			};
			dialog.response.connect(() => { dialog.destroy(); });
			dialog.run();
		}
	}

	void predict()
	{
		if (this.intrp == null) return;

		var img = this.canvas.get_image();
		img = img.scale_simple(28, 28, Gdk.InterpType.BILINEAR);
//      img.save("/tmp/img.png","png");

		/* Unfortunately Gdk doesn't have any methods to get grayscale data
		 * so we have to convert the data ourselves.                        */

		var data = new float[28 * 28];
		var img_bytes = img.read_pixel_bytes();
		for (int i = 0; i < img_bytes.length; i++)
		{
			if (i % 3 == 0)     // only read red channel
			{
				data[i / 3] = ((float) img_bytes[i]) / 255;     // convert from int range [0,255] to float range [0,1]
				data[i / 3] = 1 - data[i / 3];                  // invert the image. network expects white writing on black background.
			}
		}

		/* Do the guessing */
		intrp.get_input_tensor(0).copy_from_buffer((uint8[]) data);
		intrp.invoke();

		var prediction = new float[10];
		intrp.get_output_tensor(0).copy_to_buffer(prediction, 10 * sizeof(float));

		this.set_colors(prediction);
	}

	void set_colors(float[] intensities)
	{
		string style = "";

		for (int i = 0; i < intensities.length; i++)
		{
			float n = intensities[i];
			// style += @"#label-$i { background: rgba(31,115,206,$(0.5 * n)) }\n";
			this.number_buttons[i].opacity = n;
		}

		this.custom_style.load_from_data(style);
		Gtk.StyleContext.reset_widgets(Gdk.Screen.get_default());
	}
}

int main(string[] args)
{
	Gtk.init(ref args);

	message("TensorFlow version: %s", TFLite.version());

	var window = new DemoWindow() {
		resizable = false
	};
	window.show_all();
	window.load_model();

	Gtk.main();

	return 0;
}
